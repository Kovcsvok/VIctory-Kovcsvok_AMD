# VIctory test and fix order for the RX 9070 XT

(The first plan, 26 November, written for the KLBF phase; the bundle later took its place, see [PROGRESS.md](../../PROGRESS.md).)

**First try whether KLBF gets you to the first controllable scene, whether picture, sound and control work there, and whether the game can later load a save back.** If that is fine, the first performance test should be a repeatable car route. As the first fix I would take up texture uploads if, at the moment of a stutter, the upload time or the number of waiting textures also jumps in the log.

## What is the local starting point?

The machine has an i5-14600KF, an RX 9070 XT 16 GB and 32 GiB of physical RAM. The Radeon driver version is `32.0.32029.2010`. KLBF Lab 62 (`643939a7`) and Victory United (`6757b6ef`) use separate save folders and caches. The import-binding test passed on both. KLBF's pre-build finished in one pass, in 23 minutes 27 seconds. Seven compute shaders were left out of compilation. **The frame rate, stability and picture faults of the first local play run are still to be measured.**

## The first three tests

| Test | What to do | What to note |
|---|---|---|
| 1. Start and control | Use the `C:\Games\NOT_GTAVI\Inditas-KLBF.cmd` launcher. If you play with a controller, connect it before starting. In the first controllable scene walk around, turn the camera, open and close the menu. | The last screen reached, whether there is picture and sound, whether the character responds, whether returning from the menu works. If it stops here, that is the first fault to fix. |
| 2. Save and load | At the first available manual save point, save to a separate slot. Quit, start the same fork again, then pick this save from the **Load** menu. | Do the same place and progress load back? If yes, use this save for the next repeat. |
| 3. Texture loading while moving | When you reach Jason's house, make a manual morning save. Go out to the car, select the nearby dollar-sign target, and follow the same GPS route to the parking spot. If you are still in the prologue, repeat the same short indoor walk until then. | Write down where the picture stops, whether the road or car textures appear late, and whether the fault repeats in the same place. Leaving the house and the first busy crossing are good comparison points. |

## So a log of the first run remains

Open a **Command Prompt** (`cmd.exe`), then run the following. Leave the window open until you quit the game. Replace `A1` with a new name for every run, because the output redirection overwrites a log of the same name.

```bat
cd /d C:\Games\NOT_GTAVI
if not exist meresek mkdir meresek
set "RUST_LOG=info"
Inditas-KLBF.cmd > "meresek\A1.log" 2>&1
```

In another Command Prompt this shows the aggregated frame data:

```bat
cd /d C:\Games\NOT_GTAVI
findstr /C:"draws/frame" "meresek\A1.log"
```

In KLBF's log line, `preparing` is the CPU-side preparation, `textures` the time and amount of data spent on textures, `copying back` the copy-back. `waiting` helps interpret the queue of textures waiting. Take samples from play. On a crash keep the run's log, the name of the last visible scene and, if it was made, `VIctory-dev\state\klbf-lab\data\7952987A\crashes.log`.

## Which fix should come first?

| What you actually see | First cross-check | First development goal |
|---|---|---|
| Black picture, an exit or a lost GPU device in the same scene | Repeat once with the same setting. Try the same scene with the `Inditas-United.cmd` launcher too, and note how far it gets. The two stock profiles may differ. | Fix the earliest reproducible fault. If the log gives a specific shader or pipeline identifier, start from that. The seven skipped compute shaders get priority if one of them can be tied to the faulty scene. |
| Long stutters while driving and a growing texture queue | Measure the same route with the default setting, then with `Inditas-KLBF.cmd -LowMemory`. That lowers the texture cap from 1024 to 512 pixels. Watch the picture, the stops, the dedicated and shared GPU memory. | If the stutters drop with smaller textures, examine the upload queue and the memory budget next. If several views upload the same texture, AnyXboxX #304 is a targeted candidate. The local patch needs a manual port. |
| Slow with a still camera and while driving, `preparing` stays high | Compare the `copies`, `textures`, `heap buffers` and `copying back` times across several log lines of the same scene. | If walking the heap is expensive, look at Flamingo's solution that follows changed descriptors. If copying is expensive, the 7900XTX fix that copies changed 4 KiB ranges. In KLBF the constants and descriptor ports are already active. |
| Acceptable speed, but water, skin, glass or indoor light is wrong | Make a pair of pictures from the same save, time of day and camera view. For water, note separately whether the surface shows, and whether the boat floats and can be steered. | Pick a single visible fault. For the triangle pattern on skin or car paint, Belobug's AMD quad-read fix is a starting point; for water, checking the shader output and the texture view. |

## When to keep a change?

After a warm-up round, run three measured rounds with the original and three with the changed setting, alternating. Measure with the same manual save, route, resolution and FSR profile. Keep the already built cache when switching back to the base version too. Caches stay separate between forks.

One row per run is enough:

| Run and commit | Profile | Route completed? | Median fps | Number and place of noticed long stops | Picture or functional fault |
|---|---|---|---:|---|---|
| A1 · 643939a7 | KLBF, Series S + FSR, 1024 px | | | | |
| B1 · 643939a7 | KLBF, Series S + FSR, 512 px | | | | |

The repo's `tools\fps-session.py` computes the mean, median and 1% low from the log. If there is a working Python 3 on the machine, the first log can be summarised from the game's main folder like this:

```bat
py -3 VIctory-dev\klbf-lab\tools\fps-session.py meresek\A1.log --build 643939a7 --out meresek\A1.json
```

The tool keeps samples of at least 1,000 draws a frame. The 1% low is the mean of the worst one per cent of the aggregated fps samples. So a single short hitch should also go into the table as a separate observation.

**A change is worth keeping if the targeted fault repeatedly disappears on the same stretch, or the improvement is larger than the spread between base runs, and picture, control and saving are still fine.** So among the fixes in the fork plan, the first local fault picks the next one.

References: [KLBF measurement route](https://github.com/PastiiJay/klbf-lab/blob/beta-2/docs/klbf/MEASUREMENT.md) · [KLBF launcher settings](https://github.com/PastiiJay/klbf-lab/blob/beta-2/play.ps1) · [AnyXboxX #304](https://github.com/LooperSalty/AnyXboxX/pull/304) · [Victory United provenance list](https://github.com/Fayberr/Victory-United/blob/main/PROVENANCE.md).
