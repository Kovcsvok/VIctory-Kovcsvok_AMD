//! Diagnostics: F9 records the window's picture to a video, F9 again stops
//! it (with one of our windows in front). What is recorded is what is
//! presented, the HUD and its clock on it, so the video can be put beside
//! the log frame by frame.
//!
//! At each present the swap chain's buffer is copied into one of a ring of
//! read-back buffers; once the submission with the copy has finished
//! ([`crate::host::submissions`]), a thread of its own hands the bytes to
//! Media Foundation's sink writer (hardware encoders allowed) as H.264,
//! stamped with the time the frame was presented: every frame the window
//! showed, none twice, at the times it showed them. Nothing on the
//! presenting thread waits for the card or the encoder; with no buffer free
//! a frame is left out and counted. The file is a fragmented MP4 where the
//! system has it, so what was written plays even if the run ends without
//! F9. Where: `VICTORY_RECORD_DIR` (the measuring script gives the run's
//! folder), else `recordings` in the working directory; named
//! `felvetel-<UTC time>.mp4`.

use std::collections::VecDeque;
use std::sync::Mutex;
use std::sync::atomic::{AtomicBool, Ordering::Relaxed};
use std::sync::mpsc;
use std::time::Instant;
use windows::Win32::Graphics::Direct3D12::*;
use windows::Win32::Graphics::Dxgi::Common::*;
use windows::Win32::Media::MediaFoundation::*;
use windows::Win32::System::Com::{COINIT_MULTITHREADED, CoInitializeEx, CoUninitialize};
use windows_sys::Win32::UI::Input::KeyboardAndMouse::{GetAsyncKeyState, VK_F9};
use windows_sys::Win32::UI::WindowsAndMessaging::{GetForegroundWindow, GetWindowThreadProcessId};

/// Read-back buffers in the ring: frames the card and the writer may hold.
const SLOTS: usize = 8;
/// The video's bits a second.
const BITRATE: u32 = 16_000_000;

/// Whether a recording runs (the HUD shows `REC`).
static ON: AtomicBool = AtomicBool::new(false);
/// The writer gave up: the presenting side stops.
static FAILED: AtomicBool = AtomicBool::new(false);

/// Whether a recording runs now.
pub(crate) fn recording() -> bool {
    ON.load(Relaxed)
}

/// A frame for the writer: the slot, its buffer, its time (100 ns since the
/// recording began).
struct Frame(usize, ID3D12Resource, i64);
// SAFETY: D3D12 resources are free-threaded.
unsafe impl Send for Frame {}

enum Job {
    Frame(Frame),
    Stop,
}

struct Recorder {
    jobs: mpsc::Sender<Job>,
    done: mpsc::Receiver<usize>,
    writer: Option<std::thread::JoinHandle<()>>,
    slots: Vec<ID3D12Resource>,
    free: Vec<usize>,
    /// Copied, and the submission that must have finished first (0: not
    /// sent yet), with the frame's time.
    pending: VecDeque<(usize, u64, i64)>,
    footprint: D3D12_PLACED_SUBRESOURCE_FOOTPRINT,
    started: Instant,
    frames: u64,
    dropped: u64,
    stopping: bool,
}
// SAFETY: D3D12 resources are free-threaded; the rest is plain data.
unsafe impl Send for Recorder {}

static RECORDER: Mutex<Option<Recorder>> = Mutex::new(None);

/// F9 was pressed since the last call, with one of our windows in front.
fn pressed() -> bool {
    static DOWN: AtomicBool = AtomicBool::new(false);
    // SAFETY: a plain query.
    let down = unsafe { GetAsyncKeyState(i32::from(VK_F9)) } < 0;
    if DOWN.swap(down, Relaxed) || !down {
        return false;
    }
    let mut process = 0;
    // SAFETY: plain queries; room for the answer.
    unsafe { GetWindowThreadProcessId(GetForegroundWindow(), &mut process) };
    process == std::process::id()
}

/// `VICTORY_RECORD_AT=<from>,<to>`: a recording from `from` to `to` seconds
/// after the first present, as if F9 were pressed then (tests; F9 works as
/// well). True at those two presents.
fn timed() -> bool {
    static AT: std::sync::OnceLock<Option<(f64, f64)>> = std::sync::OnceLock::new();
    static FIRST: std::sync::OnceLock<Instant> = std::sync::OnceLock::new();
    static EDGE: std::sync::atomic::AtomicU8 = std::sync::atomic::AtomicU8::new(0);
    let Some((from, to)) = *AT.get_or_init(|| {
        let text = std::env::var("VICTORY_RECORD_AT").ok()?;
        let (a, b) = text.split_once(',')?;
        Some((a.trim().parse().ok()?, b.trim().parse().ok()?))
    }) else {
        return false;
    };
    let t = FIRST.get_or_init(Instant::now).elapsed().as_secs_f64();
    let edge = EDGE.load(Relaxed);
    let next = match edge {
        0 if t >= from => 1,
        1 if t >= to => 2,
        _ => return false,
    };
    EDGE.store(next, Relaxed);
    true
}

/// At the present: `back`, the swap chain's buffer, in `COPY_DEST` with the
/// HUD drawn on it, in `list`, which goes to the card next. F9 starts or
/// stops a recording; while one runs the picture is copied for the writer.
/// What [`sent`] is given after the list was sent.
pub(crate) fn frame(device: &ID3D12Device, list: &ID3D12GraphicsCommandList, back: &ID3D12Resource) -> Option<usize> {
    let mut recorder = RECORDER.lock().unwrap_or_else(|e| e.into_inner());
    if let Some(r) = recorder.as_mut() {
        r.hand_over();
    }
    let press = pressed();
    let press = timed() || press;
    if FAILED.swap(false, Relaxed) {
        if let Some(r) = recorder.as_mut() {
            r.stopping = true;
        }
    }
    match recorder.as_mut() {
        None if press => {
            *recorder = start(device, back);
            ON.store(recorder.is_some(), Relaxed);
        }
        Some(r) if press && !r.stopping => {
            r.stopping = true;
        }
        _ => {}
    }
    let r = recorder.as_mut()?;
    if r.stopping {
        if r.pending.is_empty() {
            let r = recorder.take()?;
            r.finish();
            ON.store(false, Relaxed);
        }
        return None;
    }
    // SAFETY: a live resource; a plain query.
    let desc = unsafe { back.GetDesc() };
    if (desc.Width, desc.Height) != (u64::from(r.footprint.Footprint.Width), r.footprint.Footprint.Height) {
        tracing::warn!(width = desc.Width, height = desc.Height, "recording stopped: the picture's size changed");
        r.stopping = true;
        return None;
    }
    while let Ok(slot) = r.done.try_recv() {
        r.free.push(slot);
    }
    let Some(slot) = r.free.pop() else {
        r.dropped += 1;
        return None;
    };
    let time = (r.started.elapsed().as_nanos() / 100) as i64;
    #[cfg(feature = "diagnostics")]
    let _ours = crate::replay::record::unrecorded();
    let to = D3D12_TEXTURE_COPY_LOCATION {
        pResource: std::mem::ManuallyDrop::new(Some(r.slots[slot].clone())),
        Type: D3D12_TEXTURE_COPY_TYPE_PLACED_FOOTPRINT,
        Anonymous: D3D12_TEXTURE_COPY_LOCATION_0 { PlacedFootprint: r.footprint },
    };
    let from = D3D12_TEXTURE_COPY_LOCATION {
        pResource: std::mem::ManuallyDrop::new(Some(back.clone())),
        Type: D3D12_TEXTURE_COPY_TYPE_SUBRESOURCE_INDEX,
        Anonymous: D3D12_TEXTURE_COPY_LOCATION_0 { SubresourceIndex: 0 },
    };
    // SAFETY: an open list; the buffer in `COPY_DEST` as the caller says,
    // back there after; a read-back buffer of the footprint's size.
    unsafe {
        list.ResourceBarrier(&[crate::host::transition(back, D3D12_RESOURCE_STATE_COPY_DEST, D3D12_RESOURCE_STATE_COPY_SOURCE)]);
        list.CopyTextureRegion(&to, 0, 0, 0, &from, None);
        list.ResourceBarrier(&[crate::host::transition(back, D3D12_RESOURCE_STATE_COPY_SOURCE, D3D12_RESOURCE_STATE_COPY_DEST)]);
    }
    drop(std::mem::ManuallyDrop::into_inner(to.pResource));
    drop(std::mem::ManuallyDrop::into_inner(from.pResource));
    r.pending.push_back((slot, 0, time));
    r.frames += 1;
    Some(slot)
}

/// The list with the copy [`frame`] recorded was sent: its bytes are there
/// once every submission begun by now has finished.
pub(crate) fn sent(token: Option<usize>) {
    let Some(slot) = token else { return };
    let started = crate::host::submissions().0;
    let mut recorder = RECORDER.lock().unwrap_or_else(|e| e.into_inner());
    if let Some(r) = recorder.as_mut()
        && let Some(p) = r.pending.iter_mut().rev().find(|p| p.0 == slot)
    {
        p.1 = started.max(1);
    }
}

impl Recorder {
    /// Frames whose copy has finished go to the writer, in order.
    fn hand_over(&mut self) {
        let finished = crate::host::submissions().1;
        while let Some(&(slot, after, time)) = self.pending.front() {
            if after == 0 || after > finished {
                break;
            }
            self.pending.pop_front();
            let _ = self.jobs.send(Job::Frame(Frame(slot, self.slots[slot].clone(), time)));
        }
    }

    fn finish(mut self) {
        let _ = self.jobs.send(Job::Stop);
        let seconds = self.started.elapsed().as_secs_f64();
        if let Some(writer) = self.writer.take() {
            let _ = writer.join();
        }
        tracing::info!(frames = self.frames, dropped = self.dropped, seconds = format_args!("{seconds:.1}"), "recording (F9) stopped");
    }
}

/// The process ends (the window closed, or the title ended:
/// `victory_hle`'s lifecycle ends it with `TerminateProcess`) while a
/// recording runs: it ends as with F9, so the file gets its length and its
/// index. Without them Windows' own frame readers refuse the fragmented MP4
/// (the 2026-11-27 11:31 run, closed with the window's close button). Waits
/// for the lock and for the writer at most three seconds in all; frames whose
/// copy has not finished are left out.
pub(crate) fn end_at_exit() {
    let deadline = Instant::now() + std::time::Duration::from_secs(3);
    let taken = loop {
        match RECORDER.try_lock() {
            Ok(mut r) => break r.take(),
            Err(std::sync::TryLockError::Poisoned(e)) => break e.into_inner().take(),
            Err(std::sync::TryLockError::WouldBlock) if Instant::now() < deadline => std::thread::yield_now(),
            Err(std::sync::TryLockError::WouldBlock) => return,
        }
    };
    let Some(mut r) = taken else { return };
    ON.store(false, Relaxed);
    r.hand_over();
    let _ = r.jobs.send(Job::Stop);
    let Some(writer) = r.writer.take() else { return };
    while !writer.is_finished() && Instant::now() < deadline {
        std::thread::sleep(std::time::Duration::from_millis(10));
    }
    let closed = writer.is_finished();
    if closed {
        let _ = writer.join();
    }
    tracing::info!(frames = r.frames, dropped = r.dropped, closed, "recording (F9) ended with the process");
}

/// A recording of `back` begins: the ring of read-back buffers and the
/// writer's thread.
fn start(device: &ID3D12Device, back: &ID3D12Resource) -> Option<Recorder> {
    // SAFETY: a live resource; outputs for one subresource.
    let (desc, footprint, total) = unsafe {
        let desc = back.GetDesc();
        let mut footprint = D3D12_PLACED_SUBRESOURCE_FOOTPRINT::default();
        let mut total = 0;
        device.GetCopyableFootprints(&desc, 0, 1, 0, Some(&mut footprint), None, None, Some(&mut total));
        (desc, footprint, total)
    };
    let bgra = match desc.Format {
        DXGI_FORMAT_R8G8B8A8_UNORM | DXGI_FORMAT_R8G8B8A8_UNORM_SRGB => false,
        DXGI_FORMAT_B8G8R8A8_UNORM | DXGI_FORMAT_B8G8R8A8_UNORM_SRGB => true,
        other => {
            tracing::warn!(format = other.0, "recording (F9) not started: the picture is not 8-bit color");
            return None;
        }
    };
    let heap = D3D12_HEAP_PROPERTIES { Type: D3D12_HEAP_TYPE_READBACK, ..Default::default() };
    let buffer = D3D12_RESOURCE_DESC {
        Dimension: D3D12_RESOURCE_DIMENSION_BUFFER,
        Width: total,
        Height: 1,
        DepthOrArraySize: 1,
        MipLevels: 1,
        SampleDesc: DXGI_SAMPLE_DESC { Count: 1, Quality: 0 },
        Layout: D3D12_TEXTURE_LAYOUT_ROW_MAJOR,
        ..Default::default()
    };
    let mut slots = Vec::with_capacity(SLOTS);
    for _ in 0..SLOTS {
        let mut made: Option<ID3D12Resource> = None;
        // SAFETY: plain creation.
        if let Err(e) = unsafe { device.CreateCommittedResource(&heap, D3D12_HEAP_FLAG_NONE, &buffer, D3D12_RESOURCE_STATE_COPY_DEST, None, &mut made) } {
            tracing::warn!(error = %e, "recording (F9) not started: no read-back buffer");
            return None;
        }
        slots.push(made?);
    }
    let dir = std::env::var_os("VICTORY_RECORD_DIR").map_or_else(|| std::path::PathBuf::from("recordings"), std::path::PathBuf::from);
    if let Err(e) = std::fs::create_dir_all(&dir) {
        tracing::warn!(error = %e, dir = %dir.display(), "recording (F9) not started: no folder");
        return None;
    }
    let now = std::time::SystemTime::now().duration_since(std::time::UNIX_EPOCH).unwrap_or_default().as_secs() % 86_400;
    let path = dir.join(format!("felvetel-{:02}{:02}{:02}-UTC.mp4", now / 3600, now / 60 % 60, now % 60));
    // An even size: H.264 asks for it.
    let size = (footprint.Footprint.Width & !1, footprint.Footprint.Height & !1);
    let pitch = footprint.Footprint.RowPitch as usize;
    let (jobs, from_present) = mpsc::channel();
    let (to_present, done) = mpsc::channel();
    let at = path.clone();
    let writer = std::thread::Builder::new()
        .name("victory-record".into())
        .spawn(move || write(&at, size, pitch, bgra, &from_present, &to_present))
        .ok()?;
    tracing::info!(path = %path.display(), width = size.0, height = size.1, format = desc.Format.0, "recording (F9) started; F9 again stops it");
    Some(Recorder {
        jobs,
        done,
        writer: Some(writer),
        slots,
        free: (0..SLOTS).rev().collect(),
        pending: VecDeque::new(),
        footprint,
        started: Instant::now(),
        frames: 0,
        dropped: 0,
        stopping: false,
    })
}

/// The writer's thread: frames from `jobs` into the file at `path`, each
/// slot given back on `done` once its bytes are taken.
fn write(path: &std::path::Path, (w, h): (u32, u32), pitch: usize, bgra: bool, jobs: &mpsc::Receiver<Job>, done: &mpsc::Sender<usize>) {
    // SAFETY: this thread's own COM and Media Foundation.
    let com = unsafe { CoInitializeEx(None, COINIT_MULTITHREADED) }.is_ok();
    // SAFETY: as above.
    let mf = unsafe { MFStartup(MF_VERSION, MFSTARTUP_FULL) }.is_ok();
    let sink = if mf { open(path, (w, h)) } else { Err(windows::core::Error::empty()) };
    let (sink, stream) = match sink {
        Ok(s) => s,
        Err(e) => {
            tracing::warn!(error = %e, "recording (F9): no video writer; nothing is written");
            FAILED.store(true, Relaxed);
            (None, 0)
        }
    };
    let mut written = 0u64;
    let mut last = -1i64;
    while let Ok(job) = jobs.recv() {
        let Job::Frame(Frame(slot, buffer, time)) = job else { break };
        if let Some(sink) = &sink
            && time > last
        {
            match put(sink, stream, &buffer, (w, h), pitch, bgra, time) {
                Ok(()) => {
                    written += 1;
                    last = time;
                }
                Err(e) => {
                    tracing::warn!(error = %e, "recording (F9): a frame was not written; the recording stops");
                    FAILED.store(true, Relaxed);
                }
            }
        }
        let _ = done.send(slot);
    }
    if let Some(sink) = sink {
        // SAFETY: the writer of this thread, every sample given.
        match unsafe { sink.Finalize() } {
            Ok(()) => tracing::info!(path = %path.display(), frames = written, "recording (F9): the file is complete"),
            Err(e) => tracing::warn!(error = %e, path = %path.display(), "recording (F9): the file could not be closed"),
        }
    }
    // SAFETY: started above on this thread.
    unsafe {
        if mf {
            let _ = MFShutdown();
        }
        if com {
            CoUninitialize();
        }
    }
}

/// The sink writer for `path`: H.264 of `w` x `h` from top-down 32-bit
/// BGRX frames; a fragmented MP4 if the system makes one, else a plain one.
fn open(path: &std::path::Path, (w, h): (u32, u32)) -> windows::core::Result<(Option<IMFSinkWriter>, u32)> {
    let url: Vec<u16> = path.as_os_str().to_string_lossy().encode_utf16().chain(Some(0)).collect();
    let made = |container: &windows::core::GUID| -> windows::core::Result<IMFSinkWriter> {
        let mut attributes = None;
        // SAFETY: plain Media Foundation calls with live arguments.
        unsafe {
            MFCreateAttributes(&mut attributes, 3)?;
            let attributes = attributes.ok_or_else(windows::core::Error::empty)?;
            attributes.SetUINT32(&MF_READWRITE_ENABLE_HARDWARE_TRANSFORMS, 1)?;
            attributes.SetGUID(&MF_TRANSCODE_CONTAINERTYPE, container)?;
            MFCreateSinkWriterFromURL(windows::core::PCWSTR(url.as_ptr()), None, &attributes)
        }
    };
    let sink = made(&MFTranscodeContainerType_FMPEG4).or_else(|e| {
        tracing::info!(error = %e, "recording (F9): no fragmented MP4 here; a plain one (complete only after F9)");
        made(&MFTranscodeContainerType_MPEG4)
    })?;
    let ratio = |a: u32, b: u32| (u64::from(a) << 32) | u64::from(b);
    // SAFETY: plain Media Foundation calls with live arguments.
    unsafe {
        let out = MFCreateMediaType()?;
        out.SetGUID(&MF_MT_MAJOR_TYPE, &MFMediaType_Video)?;
        out.SetGUID(&MF_MT_SUBTYPE, &MFVideoFormat_H264)?;
        out.SetUINT32(&MF_MT_AVG_BITRATE, BITRATE)?;
        out.SetUINT32(&MF_MT_INTERLACE_MODE, MFVideoInterlace_Progressive.0 as u32)?;
        out.SetUINT64(&MF_MT_FRAME_SIZE, ratio(w, h))?;
        out.SetUINT64(&MF_MT_FRAME_RATE, ratio(30, 1))?;
        out.SetUINT64(&MF_MT_PIXEL_ASPECT_RATIO, ratio(1, 1))?;
        let stream = sink.AddStream(&out)?;
        let input = MFCreateMediaType()?;
        input.SetGUID(&MF_MT_MAJOR_TYPE, &MFMediaType_Video)?;
        input.SetGUID(&MF_MT_SUBTYPE, &MFVideoFormat_RGB32)?;
        input.SetUINT32(&MF_MT_INTERLACE_MODE, MFVideoInterlace_Progressive.0 as u32)?;
        input.SetUINT64(&MF_MT_FRAME_SIZE, ratio(w, h))?;
        input.SetUINT64(&MF_MT_FRAME_RATE, ratio(30, 1))?;
        input.SetUINT64(&MF_MT_PIXEL_ASPECT_RATIO, ratio(1, 1))?;
        // Top-down rows (a negative or missing stride means bottom-up).
        input.SetUINT32(&MF_MT_DEFAULT_STRIDE, w * 4)?;
        sink.SetInputMediaType(stream, &input, None)?;
        sink.BeginWriting()?;
        Ok((Some(sink), stream))
    }
}

/// One frame of `buffer` (read back, rows `pitch` apart) to the writer, as
/// BGRX, at `time`.
fn put(sink: &IMFSinkWriter, stream: u32, buffer: &ID3D12Resource, (w, h): (u32, u32), pitch: usize, bgra: bool, time: i64) -> windows::core::Result<()> {
    let row = w as usize * 4;
    let len = row * h as usize;
    // SAFETY: plain Media Foundation calls; the read-back buffer's copy has
    // finished (the presenting side waits for its submission), its rows
    // `pitch` apart and at least `row` long; the media buffer `len` long.
    unsafe {
        let media = MFCreateMemoryBuffer(len as u32)?;
        let mut to = std::ptr::null_mut();
        media.Lock(&mut to, None, None)?;
        let mut from = std::ptr::null_mut();
        let mapped = buffer.Map(0, Some(&D3D12_RANGE { Begin: 0, End: pitch * h as usize }), Some(&mut from));
        if let Err(e) = mapped {
            let _ = media.Unlock();
            return Err(e);
        }
        for y in 0..h as usize {
            let src = from.cast::<u8>().add(y * pitch);
            let dst = to.add(y * row);
            std::ptr::copy_nonoverlapping(src, dst, row);
            if !bgra {
                let px = std::slice::from_raw_parts_mut(dst.cast::<u32>(), w as usize);
                for p in px {
                    *p = (*p & 0xff00_ff00) | ((*p >> 16) & 0xff) | ((*p & 0xff) << 16);
                }
            }
        }
        buffer.Unmap(0, Some(&D3D12_RANGE { Begin: 0, End: 0 }));
        media.Unlock()?;
        media.SetCurrentLength(len as u32)?;
        let sample = MFCreateSample()?;
        sample.AddBuffer(&media)?;
        sample.SetSampleTime(time)?;
        sample.SetSampleDuration(333_333)?;
        sink.WriteSample(stream, &sample)
    }
}
