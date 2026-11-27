# Run guide – KLBF and Victory United, and the bundle

(The user's run guide, translated from Hungarian. The local original is `C:\Games\NOT_GTAVI\Futtatasi-utmutato.md`. The launchers are in [`tools`](tools); in this repository the game folder's name is replaced with `<JATEKMAPPA>`.)

Every launcher is in the `C:\Games\NOT_GTAVI` folder. They can be started with a double-click or from a terminal. **Do not run them as administrator.**

## Where are we? (2026-11-26, the KLBF phase)

| Step | State |
|---|---|
| Build (KLBF and United) | Done, 14:10 |
| KLBF shader pre-build | Done, 14:36 (1 pass, about 23.5 minutes) |
| First play run | Not yet |

**So today no build or pre-build is needed: start at step 3.**

## The order

### 1. Build: `Forditas.cmd`

Only needed if the source code changed (a new commit or fix).

- Builds KLBF, then Victory United (`cargo build --release --locked -p victory`).
- Downloads United's DirectX runtime only if it is missing.
- On error the window stays open (`pause`); on success it closes.
- Step 2 always follows.

### 2. Shader pre-build: `Shader-eloforditas.cmd`

**Needed after every new build,** and only for KLBF. About 23–24 minutes on this machine.

- If the graphics driver crashes meanwhile, the script continues by itself from where it stopped (up to 120 passes). Do not interfere then.
- It is done when the log shows `Pre-build done`.
- It skips pipelines already pre-built, so a repeat is faster.
- **Series X mode needs a separate pre-build:** `Shader-eloforditas.cmd -SeriesX`. The `-LowMemory` switch needs no new pre-build.

### 3. Start: pick one

| What is it for? | Command |
|---|---|
| **Measuring with logs** (the current task) | Double-click `meresek\Meres-KLBF.cmd`, then the profile (`1` = default, `2` = `-LowMemory`) and the name (Enter for the suggested one) |
| Plain play with KLBF | `Inditas-KLBF.cmd` |
| Smaller textures, less memory | `Inditas-KLBF.cmd -LowMemory` (512 px texture cap) |
| Series X mode, without FSR (slower) | `Inditas-KLBF.cmd -SeriesX` (first: `Shader-eloforditas.cmd -SeriesX`) |
| The comparison fork | `Inditas-United.cmd` |

**Do not rename `Meres-KLBF.cmd`.** On a double-click it first asks for the profile (`1` or Enter = default 1024 px, `2` = `-LowMemory` 512 px), then for the run's name. With Enter it gets the name suggested for the profile (`A1-rablas-1024` or `B1-rablas-512`), but you can type another. From a terminal it can be given as a parameter: `Meres-KLBF.cmd A1-ut-meleg` or `Meres-KLBF.cmd B1-ut-512 -LowMemory`. The name may only contain unaccented letters, digits, dots, hyphens and underscores. The script puts the date and time in front of the folder's name, so two runs never overwrite each other.

United gets no pre-build. In the first minutes it compiles shaders while running, so it is slower and stutters more at first.

## One measuring run (how it has to go now)

1. In the Load menu always load **the same save** (now: the 16:04 autosave before the robbery).
2. Play the robbery stretch the same way, and get past the point where A0 crashed.
3. **Play for 12 minutes** from when the character can be controlled, then quit from the game's menu. If it crashes earlier, that is valuable data too.
4. Then write just this: did it crash (if so, what happened before), did you get through the robbery scene, when and while doing what did the game stutter badly, and were there missing or blurry textures. I collect the logs from the folder.

Why 12 minutes: memory gets tight within the first 1–2 minutes, and the long stutters and the crash came around 7–9 minutes. 12 minutes covers both, and it matches A0b's length, so the runs can be compared.

## C1 measurement (MAP_LEAN, four runs)

1. Double-click `meresek\Meres-C1.cmd` and type the run's number: `1`, `2`, `3` or `4`, in order, one after the other. The launcher sets off/on from the number.
2. Load the same **16:04** save, and play the same way as in B2.
3. **F8:** once when you arrive at the café, and once when the car chase starts. A beep confirms it was recorded. The key also works in the game's window.
4. Play for 12 minutes from when the character can be controlled, then quit from the game's menu.
5. Do not restart the machine between the four runs, and do not change back the page-file setting.

## C2 measurement (Lab 63.2 + MAP_LEAN, four runs)

Needed once beforehand: `meresek\Eloforditas-C2.cmd` (about 25 minutes; do not start a game meanwhile).

1. Double-click `meresek\Meres-C2.cmd` and choose the run. Order: `1`, `2`, `3`, `4`.
2. **`1` and `2`, benchmark:**
   - load the 16:04 save, and do not touch anything after that;
   - after 5 minutes a result card appears;
   - after a key press or 60 seconds the game quits by itself.
3. **`3` and `4`, play:**
   - the same save, 12 minutes through the robbery and the chase;
   - F8 on arriving at the café and when the chase starts;
   - then write how the faces and the doors looked, and when the game stuttered badly.

## The bundle: this is the playable base now (Belobug rx9070xt + 512 px + PC FSR + faster texture refresh)

1. Double-click `meresek\Inditas-Csomag.cmd`, then `1`.
   - `1`: the stable base, with a 30 fps cap, the new tree fix (`VICTORY_TWIN_MOVE`) and the boat fix (`CARD_STEPS_LEARN`). The characters' RT resolve shaders are skipped, otherwise they gave blue faces. Since 2026-11-27 10:50 the boat fix is in again, because without it boats stretched and beards vanished (Claude-25).
   - `2`: up to 60 fps, with a sharper picture.
   - `3`: like `2`, with larger textures. Uses more memory, may stutter.
   - `4`: like `2`, saving pictures, if you want to show something.
   - `5`: safe mode, if nothing else starts.
   - `6`: tree test. Like `1`, but without renderer port 1.
   - `7`: fast mode. Like `1`, but without the boat fix. About 6 fps faster; in exchange boats and figures may stretch, and the beard may vanish.
   - `8`: like `6`, without renderer port 2 as well. Slower, and it did not help (2026-11-26 22:50).
   - `9`: done, no longer needed. Like `1`, but without the card-step speed-up (`VICTORY_CARD_STEPS`). In the 11:31 run Cal's beard vanished all the same, so that is not the cause (Claude-28).
   - After closing the game, do not close the black window until it prints "Vége." ("Done."). Otherwise the marker may hold F8 for an hour.
   - Before starting, close the browser, ChatGPT, Word and Antigravity. Together they take about 4 GB of RAM, and every GB counts for the game: with full RAM the crude models come.
   - Since 11-27 11:25 every menu option has `VICTORY_PRELUDE_POOL=1` (fewer command lists, about 1–1.5 GB less RAM). In the 11:31 run 4–6 GB stayed free during the montage instead of the earlier 1.5–2.5 GB.
   - Since 11-27 12:20 every option has `VICTORY_STAGING_SPARES=2` (at most 2 empty 64 MB texture upload blocks; Codex's change, about 128 MB less).
2. Pick the account and load the latest save. The bundle uses its own save folder; it does not touch the KLBF saves.
3. The frame rate shows in the picture's corner. **F3**: the HUD disappears or comes back.
   - **F9: video recording.** Press it, and a red `REC` appears next to the HUD's clock; press F9 again, and it stops. The video goes into the run's folder (`meresek\<date>-<name>\felvetel-<UTC time>.mp4`), no need to look elsewhere. Since 11-27 11:55 it is closed properly even when you quit with the window's X button during a recording.
   - Leave the HUD visible while recording: its clock lets me line the video up with the log.
4. Then write:
   - did it crash;
   - how much objects pop up or vanish;
   - when the game stuttered badly.

## Before starting

1. **Connect the controller.** The account picker only reacts to the controller, not to the keyboard.
2. **Close large memory users,** especially `llama-server`. If it is running, the measuring launcher warns; then type `n`, close it, and start again.
3. Do not run the two forks at the same time, and do not start two games.

## During and after play

- The first minutes in a new area are slow, because shaders are still loading.
- **Quit the game from the game's menu.** Do not close the terminal window before that.
- After quitting, `Meres-KLBF.cmd` writes the run's summary and only closes on a key press.
- **The two forks' saves are in separate places;** they do not see each other's saves:
  - KLBF: `VIctory-dev\state\klbf-lab\data\7952987A\storage`
  - United: `VIctory-dev\state\Victory-United\data`

## Where are the logs?

| What | Where |
|---|---|
| Measurement logs | `meresek\<date-time>-<name>\`: `victory.log`, `frametime.csv`, `memoria.csv`, `osszegzes.md` |
| Crash log | `VIctory-dev\state\klbf-lab\data\7952987A\crashes.log` (the measuring launcher copies it into the run's folder) |
| Pre-build log | `VIctory-dev\state\klbf-lab\shader-prebuild.log` |

`Inditas-KLBF.cmd` keeps no log. If the run's data is needed, use `Meres-KLBF.cmd`.

## If something does not work

| What you see | What to do |
|---|---|
| `Build first` or `Run Forditas.cmd first` | Step 1 |
| `AMD FSR not found` | `VIctory-dev\FidelityFX-SDK\Kits\FidelityFX\signedbin\amd_fidelityfx_upscaler_dx12.dll` is missing, or use the `-SeriesX` switch |
| `Cargo build failed` | Send the window's last lines |
| A black window, then exit after about 3 seconds | Not enough memory: close other programs |
| `Már fut egy victory.exe` ("a victory.exe is already running") | Close the running instance (Task Manager, `victory.exe`) |
| The game freezes and does not respond | Stop `victory.exe` in Task Manager; keep the log and the run's folder |

## In one go

```text
(if the code changed)  Forditas.cmd  →  Shader-eloforditas.cmd  →  meresek\Meres-KLBF.cmd (name + Enter)  or  Inditas-KLBF.cmd
(if it did not)                                                    meresek\Meres-KLBF.cmd (name + Enter)  or  Inditas-KLBF.cmd
```
