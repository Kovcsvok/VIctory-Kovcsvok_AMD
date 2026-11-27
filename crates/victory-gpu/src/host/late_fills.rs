//! Fills of pages the title writes late, done again just before the card
//! runs their submission (`VICTORY_LATE_FILLS`), instead of the submission
//! waiting for the flights ahead of it ([`super::card_steps`]'s `late`).
//!
//! What waited: a submission that card steps would take, with a fill left
//! to the CPU of a page the title was found writing after sending
//! (`VICTORY_CARD_STEPS_LEARN`), was refused and waited, on the submitting
//! thread, until the flights ahead had landed; only then were its fills
//! read. At the boat that was 3.6 submissions and 20 ms a frame, and the
//! card ran dry meanwhile: the card at 36-55 %, the CPU at 47-66 % (run
//! 2026-11-27 12:20, Claude-29).
//!
//! What is done instead: the submission is taken and sent at once, behind a
//! wait of the queue for a fence of ours (`ID3D12CommandQueue::Wait`). A
//! thread of ours waits for the same moment the submitting thread waited
//! for (mode 1: the flights ahead have landed; mode 2: only the card has
//! run them), reads those fills again from title memory into the upload
//! memory the submission reads them from, and signals the fence: the card
//! goes on. The submitting thread goes on to the next submission at once.
//! The bytes are those the wait would have read, or newer ones.
//!
//! Card steps take a fill to the card when it reads what flights ahead
//! write; a learned one is left to the CPU instead in mode 1 (done again
//! after they have landed, title memory holds what they wrote). One that
//! reads what a copy taken to the card writes still waits as before (that
//! reaches title memory only when this submission lands), and in mode 2
//! every one taken to the card does. (Doing those again at the gate of
//! mode 2 too, from title memory, was tried on 2026-11-27, Claude-39: a
//! frame took 5.1 ms longer, and 29 fills a frame differed from title
//! memory once their submission had landed: the flights' shaders do write
//! the bytes those fills read, so they need the landing.) Only with the relay's fetch on the copy queue
//! (`VICTORY_RELAY_COPY=1`): on the drawing queue the fetch of a flight
//! ahead would run behind the gated submission, and the landing that opens
//! the gate would wait for it. A gate that is not opened in time is opened
//! anyway (logged): the card never waits on us for good.

use std::sync::atomic::{AtomicU64, Ordering};
use std::sync::{Mutex, OnceLock};
use std::time::{Duration, Instant};

use windows::Win32::Foundation::{CloseHandle, HANDLE};
use windows::Win32::Graphics::Direct3D12::*;
use windows::Win32::System::Threading::{CreateEventW, WaitForSingleObject};

/// The longest a gate stays shut: then it opens with the bytes there are.
const MOST: Duration = Duration::from_secs(2);

/// `VICTORY_LATE_FILLS`: `1` after the flights ahead have landed (the moment
/// the submission waited for), `2` as soon as the card has run them; unset
/// or `0`: off, the submission waits as before. Live with `VICTORY_AB`
/// (the mode when on: the variable's, else 1).
pub(super) fn mode() -> u32 {
    static MODE: OnceLock<u32> = OnceLock::new();
    let asked = *MODE.get_or_init(|| match std::env::var("VICTORY_LATE_FILLS").ok().as_deref().map(str::trim) {
        Some("1") => 1,
        Some("2") => 2,
        _ => 0,
    });
    #[cfg(feature = "diagnostics")]
    let asked = match crate::ab::pick("VICTORY_LATE_FILLS") {
        Some(true) => asked.max(1),
        Some(false) => 0,
        None => asked,
    };
    // Without the relay a settle lands every flight together, the gated one
    // too, after the card has run them all: it would wait for the gate.
    if asked > 0 && !(super::relay() && super::relay_copy()) {
        static SAID: std::sync::Once = std::sync::Once::new();
        SAID.call_once(|| {
            tracing::warn!(
                "VICTORY_LATE_FILLS needs VICTORY_RELAY and VICTORY_RELAY_COPY=1: off, submissions wait as before"
            );
        });
        return 0;
    }
    asked
}

/// Since the last frame-rate line: submissions sent behind a gate, fills
/// done again, of them changed since the submission was prepared, the
/// helper's waits in microseconds, gates opened for want of time;
/// submissions that still waited because a fill taken to the card reads a
/// learned page.
static STATS: [AtomicU64; 7] = [const { AtomicU64::new(0) }; 7];

pub(super) fn refused_on_card() {
    STATS[5].fetch_add(1, Ordering::Relaxed);
}

/// Fills card steps would have taken, left to the CPU and done again.
pub(super) fn moved_to_cpu(n: usize) {
    STATS[6].fetch_add(n as u64, Ordering::Relaxed);
}

/// The number of the last submission sent ahead (a flight), for the next
/// one's gate: it opens once that has landed.
static LAST_FLIGHT: AtomicU64 = AtomicU64::new(0);

/// A gated submission's fills, for the thread that opens the gate.
struct Job {
    value: u64,
    /// Mode 1: the flight whose landing opens the gate.
    after: u64,
    /// Mode 2: the host fence and the value behind the flights ahead.
    card: (ID3D12Fence, u64),
    mode: u32,
    /// Upload memory, title memory, bytes.
    fills: Vec<(usize, usize, usize)>,
}

// SAFETY: D3D12 fences are free-threaded; the addresses are upload memory
// the submission holds until it has landed (after the gate) and title
// memory, read with a read that survives remapping.
unsafe impl Send for Job {}

struct Gate {
    fence: ID3D12Fence,
    next: u64,
    jobs: std::sync::mpsc::Sender<Job>,
}

// SAFETY: as above; used under its lock.
unsafe impl Send for Gate {}

static GATE: Mutex<Option<Gate>> = Mutex::new(None);

/// Under the submission lock, before a submission is sent ahead: its flight
/// number, and the fills ([`super::card_steps::Taken::again`]) to do again.
/// Returns the fence and value the queue is to wait for before the
/// submission's lists, `None` to send it as it is (no gate could be made:
/// the fills keep the bytes read when it was prepared).
pub(super) fn gate(
    device: &ID3D12Device,
    host_fence: &ID3D12Fence,
    behind: u64,
    number: u64,
    fills: &[(usize, usize, usize)],
) -> Option<(ID3D12Fence, u64)> {
    let after = LAST_FLIGHT.swap(number, Ordering::Relaxed);
    let mode = mode();
    if fills.is_empty() || mode == 0 {
        return None;
    }
    let mut gate = GATE.lock().unwrap_or_else(|e| e.into_inner());
    if gate.is_none() {
        // SAFETY: plain fence creation.
        let fence: ID3D12Fence = unsafe { device.CreateFence(0, D3D12_FENCE_FLAG_NONE) }.ok()?;
        let (jobs, take) = std::sync::mpsc::channel::<Job>();
        let opener = fence.clone();
        let opener = Opener(opener);
        std::thread::Builder::new()
            .name("victory-late-fills".into())
            .spawn(move || open_gates(opener, take))
            .ok()?;
        tracing::info!(
            mode,
            "fills of pages the title writes late are done again right before the card runs them; the submission does not \
             wait (VICTORY_LATE_FILLS)"
        );
        *gate = Some(Gate { fence, next: 0, jobs });
    }
    let g = gate.as_mut()?;
    g.next += 1;
    let job = Job {
        value: g.next,
        after,
        card: (host_fence.clone(), behind),
        mode,
        fills: fills.to_vec(),
    };
    if g.jobs.send(job).is_err() {
        // The thread is gone: nothing would open it.
        g.next -= 1;
        return None;
    }
    STATS[0].fetch_add(1, Ordering::Relaxed);
    Some((g.fence.clone(), g.next))
}

/// The fence the opening thread signals.
struct Opener(ID3D12Fence);

// SAFETY: D3D12 fences are free-threaded.
unsafe impl Send for Opener {}

/// The thread that opens gates, in the order they were made.
fn open_gates(fence: Opener, jobs: std::sync::mpsc::Receiver<Job>) {
    crate::cores::keep_on_fast_cores("victory-late-fills");
    // SAFETY: an auto-reset event of ours, for host fence waits.
    let event = unsafe { CreateEventW(None, false, false, None) }.unwrap_or_default();
    let mut bytes = Vec::new();
    for job in jobs {
        let began = Instant::now();
        let deadline = began + MOST;
        let in_time = match job.mode {
            2 => card_ran(&job.card.0, job.card.1, event, deadline),
            _ => landed(job.after, deadline),
        };
        if !in_time {
            STATS[4].fetch_add(1, Ordering::Relaxed);
            static SAID: AtomicU64 = AtomicU64::new(0);
            if SAID.fetch_add(1, Ordering::Relaxed) < 8 {
                tracing::warn!(
                    after = job.after,
                    mode = job.mode,
                    "late fills: the flights ahead did not land in 2 s; the gate opens with the bytes there are"
                );
            }
        }
        for &(dst, src, len) in &job.fills {
            bytes.clear();
            bytes.resize(len, 0);
            if !super::read_into(src as *const u8, &mut bytes) {
                continue;
            }
            STATS[1].fetch_add(1, Ordering::Relaxed);
            // SAFETY: the submission's upload memory, `len` bytes, alive until
            // it has landed, which the gate holds back; the card reads it only
            // after the signal below.
            let was = unsafe { std::slice::from_raw_parts(dst as *const u8, len) };
            if was != bytes.as_slice() {
                STATS[2].fetch_add(1, Ordering::Relaxed);
                // SAFETY: as above.
                unsafe { std::ptr::copy_nonoverlapping(bytes.as_ptr(), dst as *mut u8, len) };
            }
        }
        STATS[3].fetch_add(began.elapsed().as_micros() as u64, Ordering::Relaxed);
        // SAFETY: our fence; a CPU-side signal.
        let _ = unsafe { fence.0.Signal(job.value) };
    }
    if !event.is_invalid() {
        // SAFETY: our event.
        let _ = unsafe { CloseHandle(event) };
    }
}

/// Mode 1: until the flight `after` (0: none) has landed.
fn landed(after: u64, deadline: Instant) -> bool {
    let mut line = super::line();
    loop {
        if super::FINISHED.load(Ordering::Acquire) >= after {
            return true;
        }
        let now = Instant::now();
        if now >= deadline {
            return false;
        }
        // (Not every landing path tells the condition variable: looked at
        // again every 2 ms too.)
        line = super::LINE_LANDED
            .wait_timeout(line, (deadline - now).min(Duration::from_millis(2)))
            .map(|(l, _)| l)
            .unwrap_or_else(|e| e.into_inner().0);
    }
}

/// Mode 2: until the card has run what was sent before `value` on the host
/// fence.
fn card_ran(fence: &ID3D12Fence, value: u64, event: HANDLE, deadline: Instant) -> bool {
    loop {
        // SAFETY: a plain query.
        if unsafe { fence.GetCompletedValue() } >= value {
            return true;
        }
        let now = Instant::now();
        if now >= deadline || event.is_invalid() {
            return false;
        }
        // SAFETY: our event and the host's fence.
        if unsafe { fence.SetEventOnCompletion(value, event) }.is_err() {
            return false;
        }
        let ms = (deadline - now).as_millis().clamp(1, 2000) as u32;
        // SAFETY: our event.
        unsafe { WaitForSingleObject(event, ms) };
    }
}

/// For the frame-rate line.
pub(super) fn log(frames: f64) {
    let mode = mode();
    let s: Vec<f64> = STATS.iter().map(|c| c.swap(0, Ordering::Relaxed) as f64).collect();
    if mode == 0 && s.iter().all(|&v| v == 0.0) {
        return;
    }
    tracing::info!(
        "late fills (VICTORY_LATE_FILLS={mode}) per frame: {:.2} submissions sent at once behind a gate instead of waiting, \
         {:.1} fills done again before the card ran them ({:.2} found changed since preparing; {:.1} fills taken off the \
         card for it), the gate thread {:.2} ms waiting and filling; {:.2} still waited (a learned fill reads what a copy \
         on the card writes, or mode 2); since the last line {} gates opened for want of time",
        s[0] / frames,
        s[1] / frames,
        s[2] / frames,
        s[6] / frames,
        s[3] / frames / 1000.0,
        s[5] / frames,
        s[4],
    );
}
