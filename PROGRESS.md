# Progress: VIctory on an RX 9070 XT (Kovcsvok AMD branch)

Status: **27 November 2026, 12:00** (local time). The details are in [`progress/reports`](progress/reports), one report per measurement (Claude-01 … Claude-28, in Hungarian). English summaries of every report are in the [report index](progress/reports/README.md).

## In short: where are we?

**What works:**
- The "Belobug rx9070xt bundle" plays through the prologue on this machine: the robbery, the car chase, the title card and the boat mission. 30 fps in cutscenes (the game's own cap), 20–25 fps while sailing.
- **Gone:**
  - vanishing trees and canopy (`VICTORY_TWIN_MOVE`);
  - "stretching" boats and characters (`VICTORY_CARD_STEPS_LEARN`);
  - blue faces (the character ray-tracing resolve shaders are skipped);
  - 3–4 fps stretches from running out of memory (512 px texture cap);
  - crude, untextured figures in the "Chapter 1" montage (shared prelude pool, and other programs closed).
- The picture is clean with PC AMD FSR.

**What is still wrong:**
1. **Colourful blocky garbage on some faces**, a **vanishing beard** (Cal) and a **boat side that disappears at a distance** (the tourist boat). The common suspect: the game compresses some textures itself on the GPU, and those writes are lost here. **This is the next fix.**
2. **Glasses reflect the sky.** The render pass responsible has not been found yet.
3. **Frame rate:** the boat fix (`LEARN`) costs about 5–6 fps while sailing.
4. **RAM:** on 32 GB the game takes 26–27 GB. There are still items to cut (permanent host lists, the view-shape cache).

## The machine and the goal

| | |
|---|---|
| GPU | AMD Radeon RX 9070 XT, 16 GB (RDNA4) |
| CPU | Intel Core i5-14600KF |
| Memory | 32 GiB DDR5 |
| OS | Windows 11 |
| Profile | Series S, 512 px texture cap, PC AMD FSR |

**The goal:** a stable, correct picture and as high a frame rate as possible on this machine. Measurements decide everything: logs, video, and switches toggled live within the same run.

## Who works on it

| Who | Role |
|---|---|
| The user (Kovcsvok) | plays and tests; marks problems with F8, records video with F9 |
| Claude | measures, analyses and builds locally; writes the reports |
| Codex | coordinates and decides the next step; every report asks it for one decision |
| Antigravity | builds on its own branch (`agy-9070-v2`), which is not in this repository |

## The code branches

| Branch / tree | Role |
|---|---|
| [PastiiJay/klbf-lab](https://github.com/PastiiJay/klbf-lab) `beta-2` | The first local base (KLBF); the A0–C2 measurements ran on it. |
| [Fayberr/Victory-United](https://github.com/Fayberr/Victory-United) | A version for comparison. |
| [Belobug/VIctory-Belobug-AMD](https://github.com/Belobug/VIctory-Belobug-AMD) `rx9070xt` | **The bundle's base** (`cd8dfc06`): RX 9070 XT fixes, HUD, DexNom's PC FSR. |
| **This repository, `main`** | Belobug's `cd8dfc06` plus one commit with every change of the bundle (see below). |
| Antigravity `agy-9070-v2` | Antigravity's own build; not here, and we do not write to it. |

Plans and the record of sources, in [`progress/plans`](progress/plans) (Hungarian):
- the [build watcher](progress/plans/VIctory-buildfigyelo.md): every source and measurement, dated;
- the [fork plan](progress/plans/VIctory-forkterv.md);
- the [test order](progress/plans/VIctory-teszteles-es-javitasi-sorrend.md).

## Timeline

### 1. The KLBF phase (26 Nov afternoon): how far does the memory go?

| Run | Setting | Median fps | Outcome |
|---|---|---:|---|
| A0 | 1024 px | 15.5 | crash at the robbery |
| A0b | 1024 px | 13.7 | normal exit, but long stutters |
| B1 | 512 px (`-LowMemory`) | 13.7 | GPU hang during the car chase |
| B2 | 512 px, large page file | 12.1 | normal exit, 10.9 minutes |

**What we learned:**
- the stutters come from remapping memory;
- `VICTORY_MAP_LEAN` (C1 and C2) helped while loading: the longest frame went from 2,483 ms to 552 ms;
- after that, both variants ran at about 20 fps;
- reports: Claude-01 … 08 and the C1 decision.

### 2. The bundle (26 Nov evening): through the robbery

- **Claude-09:** Belobug's `rx9070xt` branch built in one piece, and it started.
- **Claude-10–11:** fast, but 3–4 fps at the robbery; the cause is running out of memory.
- **Claude-12:** with a 512 px texture cap it reaches the title card **for the first time**. PC FSR turned on in the Series S profile too.
- **Claude-13–15:**
  - a much better picture;
  - objects popping in come from the texture queue;
  - re-checking textures every 250 ms became the default.
- **Claude-16:** a 60 fps cap and FSR sharpening went into menu options 2–4.

### 3. Trees and flicker (26 Nov night – 27 Nov morning)

- **Claude-17–20:** the foliage tests (`INDIRECT_BATCH`, fix/popin, turning renderer ports off) did not help. fix/popin is slower on this machine.
- **Claude-21:** **found why the trees vanish.**
  - The twin views of `CS_Tree_BatchCull` got null views because they were made outside the thread's own workspace.
  - Own fix: `VICTORY_TWIN_MOVE`. avatarmanz's PR 437 (`TWIN_EXACT`) crashes on this card.
  - New tool: live on/off tests (`VICTORY_AB`) shown on the HUD.

### 4. Video, the boat scene, frame rate (27 Nov morning)

- **Claude-22:** F9 video recording in the bundle. With the HUD clock in the picture, the video lines up with the log.
- **Claude-23–24:**
  - the picture is clean, no vanishing trees;
  - the frame rate goes to the boat fix (`LEARN`): about 10 ms a frame;
  - the character ray-tracing resolve gives blue faces, so its 42 shaders are skipped (`progress/tools/rt-feloldo-shaderek.txt`).
- **Claude-25:** without `LEARN` the boats stretch and the beard vanishes, so **`LEARN` is the default again**. The fast variant without `LEARN` stays in menu option 7.

### 5. Faces, beard, RAM (27 Nov morning)

- **Claude-26:**
  - the glasses clamp (`VICTORY_REFLECT_HOLD`) has no effect and was dropped;
  - the suspect for garbage faces is lost texture writes;
  - Cal's beard is half missing.
- **Claude-27:** where does the RAM go?
  - AMD's driver keeps at least 1 MB of shared memory per command list and does not give it back. The game had about 4,000 of them.
  - Fix: a shared pool for the prelude lists (`VICTORY_PRELUDE_POOL`).
- **Claude-28:**
  - the RAM fix works: 4–6 GB free during the montage instead of 1.5–2.5, and no crude models;
  - Cal's beard vanishes without the card steps too, so they are not the cause;
  - the common suspect for the beard, the garbage face and the tourist boat is lost writes into compressed textures;
  - the video is now closed properly when the window is closed.

## The bundle's current settings (menu option 1)

| Switch | What it does |
|---|---|
| `VICTORY_TEXTURE_MAX=512` | 512 px texture cap: fits into 32 GB |
| `VICTORY_TEXTURE_LOOK_MS=250` | re-checks textures at least every 250 ms (less pop-in) |
| PC AMD FSR (`VICTORY_FIDELITYFX_DIR`, `VICTORY_FSR_*`) | the PC FSR instead of the console one, a sharper picture |
| `VICTORY_PORT_CONSTANTS`, `_DESCRIPTORS`, `_CBV`, `_GUARD`, `_JOURNAL` | renderer ports (avatarmanz): a PC path instead of copying console memory |
| `VICTORY_TWIN_MOVE` | tree fix (own) |
| `VICTORY_CARD_STEPS=2` + `VICTORY_CARD_STEPS_LEARN` | boat fix (avatarmanz PR 434): a faithful picture, but slower |
| `VICTORY_SKIP_PIPELINES=…` | the 42 character ray-tracing resolve shaders skipped (against blue faces) |
| `VICTORY_PRELUDE_POOL=1` | shared prelude pool, about 1 GB less RAM |
| `VICTORY_TEXTURE_NO_WAIT`, `VICTORY_RELAY=2`, `VICTORY_JOIN_*`, `VICTORY_INDIRECT_*`, `VICTORY_UPLOAD_AHEAD`, `VICTORY_THIN` … | the Belobug bundle's speed-ups |

The full list is in each run's `futas.txt` and in [`meres-csomag.ps1`](progress/tools/meres-csomag.ps1); the menu options are in [`Inditas-Csomag.cmd`](progress/tools/Inditas-Csomag.cmd). The README has the same set as a PowerShell block.

## Fixed problems

| Problem | Cause | Fix | Report |
|---|---|---|---|
| 3–4 fps, crash at the robbery | ran out of memory | 512 px cap | Claude-11, 12 |
| blurry, ugly picture in Series S | the console FSR was being translated | PC AMD FSR in Series S | Claude-12, 13 |
| objects popping in | the texture queue re-checked rarely | `TEXTURE_LOOK_MS=250` | Claude-13, 15 |
| vanishing trees and canopy | null twin views in the tree culling pass | `VICTORY_TWIN_MOVE` | Claude-21 |
| stretching boats and characters | the game rewrites its constant buffers after submitting | `CARD_STEPS_LEARN` | Claude-21, 25 |
| blue faces | the character ray-tracing resolve on this card | 42 shaders skipped | Claude-24 |
| crude models in the montage | RAM full (1.5 GB free) | `PRELUDE_POOL` and closing other programs | Claude-27, 28 |
| unfinished video after closing the window | exit did not close the recording | `record::end_at_exit` | Claude-28 |

## Open problems and next steps

| # | Problem | Where we are | Next step |
|---|---|---|---|
| 1 | garbage faces, vanishing beard, boat side gone at a distance, odd eyebrows and eyelashes | Thousands of lost writes into BC1/BC4/BC7 textures in the log (`placed unordered texture view not mirrored`). D3D12 does not allow writable views of compressed formats. | The new build logs each view's full description. One short run will show which texture the game writes to. Then: an uncompressed "block twin" texture and a copy into the real one, behind `VICTORY_BC_WRITES`. |
| 2 | glasses reflect the sky | The clamp after `CS_UpdateHistory` has no effect; the source is another pass. | Find the reflecting render pass. |
| 3 | frame rate while sailing (20–25) | `LEARN` waits about 10 ms a frame. | Later: more targeted learning. |
| 4 | RAM (26–27 GB for the game) | The prelude pool is done. | Lazy permanent host lists (1–2 GB); the view-shape cache (up to 1 GB); `VICTORY_RESIDENCY` only with `VICTORY_BURY_LAG=64`. |
| 5 | clouds jump a little | Only observed. | — |

**Decisions open with Codex:**
- Claude-26: the direction for restoring the lost writes;
- Claude-27: whether `PRELUDE_POOL` is the default everywhere;
- Claude-28: whether writes into compressed textures are the next fix.

## How we measure

1. **Start:** `Inditas-Csomag.cmd`, choosing from the menu. The option sets the switches and logs into the run's folder:
   - `victory.log`;
   - `memoria.csv` (a memory sample every second);
   - `futas.txt` (settings, the exe's hash);
   - `jelolesek.csv` (marks).
2. **While playing:**
   - **F8** marks a moment (a beep, the time goes into `jelolesek.csv`);
   - **F9** records video into the run's folder;
   - **F3** turns the HUD on and off. With the HUD clock in the picture, video frames line up exactly with the log.
3. **Live A/B:** `VICTORY_AB=<seconds>,<switch>`. The program toggles the switch during the run, and the HUD's `AB` line shows it, so one run shows both sides.
4. **Analysis:**
   - frames taken from the video (Windows Media Foundation);
   - frame strips around the marks;
   - the log's summary lines (memory, lists, textures, fps) compared with earlier runs.

**Build:** `cargo build --locked --profile diag -p victory --features diagnostics`. The measuring launcher starts `target\diag\victory.exe`.

## What is in this repository, and what is not

**In it:**
- the complete source code (GPL-3.0, like VIctory);
- the [`progress/`](progress) folder: reports, plans, the launchers and scripts.

**Not in it:**
- the game's files;
- videos, logs, screenshots (the repository is text-only, see `docs/asset-policy.md`; image links in the reports therefore do not open here);
- personal data.

**About the scripts:** `<JATEKMAPPA>` stands in place of the game folder's name; put your own folder there before running. The scripts expect the `C:\Games\NOT_GTAVI` folder layout, and their comments and messages are in Hungarian. [`progress/Futtatasi-utmutato.md`](progress/Futtatasi-utmutato.md) is the run guide for the user, in Hungarian.
