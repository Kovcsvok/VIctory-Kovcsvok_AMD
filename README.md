# VIctory-Kovcsvok_AMD: VIctory on an RX 9070 XT

[VIctory](https://github.com/Marvisak/VIctory) is a compatibility layer that runs an Xbox Series title natively on Windows from the user's own copy. This branch builds on [Belobug's rx9070xt](https://github.com/Belobug/VIctory-Belobug-AMD/tree/rx9070xt) branch and is **tuned and measured on one machine: Radeon RX 9070 XT 16 GB with 32 GB of RAM.**

**This repository contains nothing from the game:** no files, code, textures or screenshots. You need your own copy of the game. It is not affiliated with or endorsed by the game's developer or publisher.

> **If you are picking this up (human or AI):** read this file first, then [PROGRESS.md](PROGRESS.md), then the latest report ([Claude-28](progress/reports/Claude-28-20261127-1155.md), in Hungarian; English summaries of all reports are in the [report index](progress/reports/README.md)). The next task, with code locations, is under [What comes next](#what-comes-next).

## Status: 27 November 2026

**Measured on:**
- Radeon RX 9070 XT 16 GB (RDNA4);
- Core i5-14600KF;
- 32 GiB DDR5;
- Windows 11.

**Profile:** Series S, 1080p output, 512 px texture cap, PC AMD FSR, ray tracing off.

| Scene | Result |
|---|---|
| Prologue: robbery, car chase, title card | **plays through**, no crash |
| Cutscenes (office, dialogue) | 30 fps (the game's own cap) |
| "Chapter 1" montage | about 23 fps |
| Boat mission, sailing | **20–25 fps** (median 22–23) |
| Game memory | peak 27.3 GB private, 11.1 GB VRAM, 7.5–9 GB shared |
| Free RAM while playing | 4–6 GB, with the browser and other large programs closed |

**Minimum: 32 GB of RAM, with no other large program running while playing.** With 1024 px textures, 32 GB is not enough.

### What works

- **Picture:** PC AMD FSR works in the Series S profile as well, with a clean image.
- **Trees:** no longer vanish or flicker (`VICTORY_TWIN_MOVE`).
- **Boats and characters:** no longer stretch (`VICTORY_CARD_STEPS_LEARN`).
- **Faces:** no longer blue (the 42 character ray-tracing resolve shaders are skipped).
- **Memory:**
  - no more 3–4 fps stretches or out-of-memory crashes (512 px textures);
  - no crude, untextured figures in the montage (`VICTORY_PRELUDE_POOL`).
- **Measuring:** F9 records video, F8 marks moments, the HUD shows a clock; switches can be toggled live (`VICTORY_AB`).

### What is still wrong

| Problem | Cause | Status |
|---|---|---|
| Colourful blocky garbage on some faces; Cal's beard and moustache vanish; a tourist boat's side turns see-through at a distance; Lucia's eyebrows and eyelashes look wrong | **Suspected:** the game writes compressed (BC1/BC4/BC7) textures itself on the GPU, and those writes are lost here | **next task**, see below |
| Glasses reflect the sky | an unknown render pass; a clamp after `CS_UpdateHistory` did not help | open |
| 20–25 fps while sailing | `CARD_STEPS_LEARN` waits about 10–17 ms a frame | open; the picture comes first for now |
| RAM is tight (26–27 GB for the game) | permanent host lists (about 1,900), the view-shape cache (up to 1 GB) | open |
| Clouds jump a little | not looked into | open |

The full history is in [PROGRESS.md](PROGRESS.md) and in the [reports](progress/reports).

## What is new in this branch

Compared with Belobug's `cd8dfc06`: one commit (`643a55a`), 24 files. All new behaviour is behind switches.

**Our own:**

| Switch / feature | What it does | In the measured profile |
|---|---|---|
| `VICTORY_TWIN_MOVE` | The twin views of the tree culling pass (`CS_Tree_BatchCull`) no longer become null: they were made outside the thread's own workspace, so they are moved (`descriptor/host.rs`) | **on** (on by default in code too) |
| `VICTORY_PRELUDE_POOL` | Host lists take their prelude lists from a shared pool of at most 192 spare ones. AMD's driver keeps at least 1 MB of shared memory per command allocator and does not give it back: 432 preludes instead of 1,909, about 1 GB less (`host.rs`, `list.rs`) | **on** (off by default in code) |
| `VICTORY_LIST_IDLE_MOST` | cap on idle host lists (default 512) | not set |
| `VICTORY_REFLECT_HOLD` | the glasses-test clamp; measured with no effect | off |
| F9 video (`record.rs`) | H.264 MP4 into the run's folder (`VICTORY_RECORD_DIR`), with the HUD clock in the picture. Closed properly even when the window is closed (`lifecycle.rs` → `end_recording`). | always |
| Logging | all 16 words of the views behind lost BC texture writes; memory lines in `copystat.rs` (preludes, pool, host lists) | `diagnostics` builds |
| HUD | an `AB` line for live A/B tests, more panel lines (`host/panel.rs`) | `VICTORY_PANEL=1` |

**Taken from other forks:**
- avatarmanz [PR 430](https://github.com/avatarmanz/VIctory-7900XTX/pull/430) (`VICTORY_WARM_BAD`);
- avatarmanz [PR 434](https://github.com/avatarmanz/VIctory-7900XTX/pull/434), adapted (`VICTORY_CARD_STEPS_LEARN`);
- avatarmanz [PR 437](https://github.com/avatarmanz/VIctory-7900XTX/pull/437) (`VICTORY_TWIN_EXACT`): **crashes on this card, do not turn it on**;
- upstream fix/popin `7ab13ed`: slower here, so off (`VICTORY_PORT_CONSTANTS_ORDER=0`);
- Belobug `f962387` (RDNA4 `GetDimensions`);
- DexNom's PC FSR, here in the Series S profile too (`VICTORY_FSR_PC`, `VICTORY_FSR_SHARPNESS`, `VICTORY_FSR_DLL`).

## Building and running

**You need:**
- Windows 10/11 x64, a CPU with AVX2;
- a Direct3D 12 GPU with Shader Model 6.6 and mesh shaders;
- Rust (the toolchain is pinned) and the MSVC build tools;
- your own copy of the game.

```powershell
git clone https://github.com/Kovcsvok/VIctory-Kovcsvok_AMD
cd VIctory-Kovcsvok_AMD
copy victory.example.toml victory.toml      # then set your paths, outside this folder
cargo build --locked --profile diag -p victory --features diagnostics
```

**Before the first run** (both can be stopped and resumed later):

```powershell
target\diag\victory.exe shaders <the game's shader archives>   # translates every shader, takes minutes
target\diag\victory.exe warm --used                            # builds pipelines ahead, after a new driver or build
```

**PC FSR:** point `VICTORY_FIDELITYFX_DIR` at the folder with AMD's signed `amd_fidelityfx_upscaler_dx12.dll` ([FidelityFX SDK, `Kits/FidelityFX/signedbin`](https://github.com/GPUOpen-LibrariesAndSDKs/FidelityFX-SDK/tree/v2.4.0/Kits/FidelityFX/signedbin)).

### The measured profile (menu option `1`) by hand

The measurements are started by the menu in [`progress/tools/Inditas-Csomag.cmd`](progress/tools/Inditas-Csomag.cmd) and by [`meres-csomag.ps1`](progress/tools/meres-csomag.ps1). Both expect the `C:\Games\NOT_GTAVI` folder layout and have `<JATEKMAPPA>` in place of the game folder's name; their comments and messages are in Hungarian. The same by hand:

```powershell
$s = @{
  VICTORY_TEXTURE_NO_WAIT='1'; VICTORY_RELAY='2'; VICTORY_WIDE_BACK='1'; VICTORY_CARD_REHASH_RUNS='1'
  VICTORY_JOIN_COPIES='1'; VICTORY_INDIRECT_WINDOW='1'; VICTORY_RELAY_COPY='1'; VICTORY_CARD_STEPS='2'
  VICTORY_INDIRECT_BATCH='2'; VICTORY_MAP_THREADS='1'; VICTORY_TITLE_PRIORITIES='0'; VICTORY_CARD_AWAKE='1'
  VICTORY_SHOW_AFTER='1'; VICTORY_AMBIENT='0.8'; VICTORY_D3D12_DRED='light'; VICTORY_THIN='1'
  VICTORY_JOIN_PARTS='8'; VICTORY_UPLOAD_AHEAD='1'; VICTORY_PORT_CONSTANTS='1'; VICTORY_PORT_DESCRIPTORS='1'
  VICTORY_PORT_CBV='1'; VICTORY_PORT_GUARD='1'; VICTORY_PORT_JOURNAL='1'; VICTORY_PANEL='1'
  VICTORY_PIPELINE_BOOK='1'; VICTORY_TEXTURE_MAX='512'; VICTORY_TEXTURE_LOOK_MS='250'
  VICTORY_PORT_CONSTANTS_ORDER='0'; VICTORY_PRELUDE_POOL='1'
  VICTORY_FIDELITYFX_DIR='<folder of the FSR dll>'; VICTORY_RECORD_DIR='<where F9 videos go>'
}
$s.VICTORY_SKIP_PIPELINES = (Get-Content progress\tools\rt-feloldo-shaderek.txt | Where-Object { $_ -match '^[0-9a-f]{16}$' }) -join ','
foreach ($k in $s.Keys) { Set-Item "Env:$k" $s[$k] }
$env:RUST_LOG = 'info'
target\diag\victory.exe run "<the game's executable>" --execute --console series-s
```

**While playing:**
- **F3:** HUD on/off;
- **F9:** video recording start/stop;
- **F8:** mark a moment (only with the measuring launcher, `jelolo.ps1`).

The account picker only reacts to a controller. `scripts\play.ps1` at the top level is the base's (avatarmanz/Belobug) launcher; we do not measure with it.

## What comes next

### 1. Lost writes into compressed textures (the most important now)

**What we see:**
- A repeated warning in the log: `placed unordered texture view not mirrored (null: writes through it are lost)`, more than 8,000 times in a 6-minute run.
- The formats: 71 BC1_UNORM, 72 BC1_UNORM_SRGB, 80 BC4_UNORM, 98 BC7_UNORM; 32–1024 px, with full mip chains.
- The timing matches the problems: the count passed 4,096 exactly while the garbage face was on screen.

**Where it is in the code:**

| Place | What is there |
|---|---|
| `crates/victory-gpu/src/descriptor.rs`, `create_placed_uav` / `create_placed_srv` | The game's device methods 0x238 and 0x230: views of memory it placed itself, `(resource desc [14 words], view desc [16 words], handle)` |
| `crates/victory-gpu/src/descriptor/host.rs`, the `View::Placed` branch (search for the warning text) | This is where a writable view of such a texture gets a null view |
| `placed_texture()` → `crate::resource::texture_at(address, resource)` | How **shader (read) views** find the host texture made for that memory; the address is in words 10–11 of the view description |
| `crates/victory-gpu/src/texback.rs` | copying textures the GPU wrote back into the game's memory |

**The open question:**
- In the **writable** views, words 10–11 are 0, so we do not yet know which texture they belong to.
- The current build therefore logs all 16 words of each such view.
- **A run that loads a scene is needed**; loading the save and reaching the first cutscene is enough.

**The plan:**
1. Once the address is known: for each (texture, mip) writable view, an uncompressed "block twin" texture at a quarter of the width and height. `R32G32_UINT` for BC1/BC4 (8-byte blocks), `R32G32B32A32_UINT` for BC5/BC7 (16-byte blocks).
2. The writable view points at the twin. After the dispatches, `CopyTextureRegion` copies from the twin into the BC texture.
3. **To be checked:** exactly what D3D12 allows when copying between a BC format and an uncompressed format of the same block size. The alternative is relaxed format casting (`D3D12_OPTIONS12`) with a castable-format list.
4. Switch: `VICTORY_BC_WRITES`. Measure it with live A/B in the same scene: the garbage face, Cal's beard, the tourist boat.

### 2. The glasses

**Ruled out:** a clamp after `sr_denoising:CS_UpdateHistory` (`Role::Reflect`); measured with no effect (Claude-26).

**Next:** find the reflecting render pass with the frame record and replay tools ([docs/replay.md](docs/replay.md)).

### 3. Frame rate while sailing

The `late` module of `crates/victory-gpu/src/host/card_steps.rs` (`LEARN`) waits on learned pages: about 3.8 submissions a frame, 16–17 ms. Idea: finer, per-buffer learning.

### 4. RAM

- `list.rs`: every game list gets a fresh, open host list right after it is submitted (about 1,900 alive). Handing them out lazily could save 1–2 GB.
- `descriptor/host.rs`: the cache of view shapes (`SHAPES`, capped at `1<<22`, about 1 GB).
- `VICTORY_RESIDENCY=1` only together with `VICTORY_BURY_LAG=64`; with 16 it caused device losses.

## How we work (please keep this)

1. **Nothing from the game goes into the repository:** no files, shader dumps, screenshots, videos or logs ([docs/asset-policy.md](docs/asset-policy.md)).
2. **All new behaviour sits behind a `VICTORY_...` switch,** off by default in code. The profile (the launcher) turns it on once a measurement has shown it helps.
3. **No decision without a measurement:**
   - a launcher run writes the log, a memory sample every second and the marks;
   - an F9 video is recorded;
   - two variants go into the same run with live A/B (`VICTORY_AB=<seconds>,<switch>`).
4. **Every measurement gets a report** in [`progress/reports`](progress/reports) and a dated line in the [build watcher](progress/plans/VIctory-buildfigyelo.md). New reports and overviews in this repository are written in English; the older ones are in Hungarian.
5. **Tests:** `cargo test --locked -p victory-gpu --lib <module>::` (for example `list::`). Trying it with the game needs the `diag` build.

## File map

| Where | What |
|---|---|
| `crates/victory-gpu/src/host.rs` | host lists, preludes, `PRELUDE_POOL` |
| `crates/victory-gpu/src/list.rs` | list life cycle, the idle pool |
| `crates/victory-gpu/src/host/card_steps.rs` | card steps, `LEARN` |
| `crates/victory-gpu/src/descriptor/host.rs` | views, placed textures, twin views (`TWIN_MOVE`) |
| `crates/victory-gpu/src/record.rs` | F9 video |
| `crates/victory-gpu/src/ab.rs`, `host/panel.rs` | live A/B, HUD |
| `crates/victory-gpu/src/copystat.rs` | the log's summary lines |
| `crates/victory-hle/src/modules/lifecycle.rs` | process exit |
| `crates/victory-hle/src/modules/fidelityfx.rs`, `apps/victory/src/run.rs` | PC FSR |
| `PROGRESS.md`, `progress/` | progress, reports, plans, measuring tools |
| `docs/README-7900XTX-alap.md` | the base's (avatarmanz, 7900 XTX) original README: switches, commands, background |

## Credits

This builds on other people's work. The history is kept, and commits taken from elsewhere name their source and author.
- **[VIctory](https://github.com/Marvisak/VIctory)** by Marvisak and its contributors: the loader, the runtime services, the Direct3D 12 back end and the shader recompiler.
- **[avatarmanz/VIctory-7900XTX](https://github.com/avatarmanz/VIctory-7900XTX):** the renderer ports, PRs 430, 434 and 437.
- **[Belobug/VIctory-Belobug-AMD](https://github.com/Belobug/VIctory-Belobug-AMD):** the `rx9070xt` branch (RX 9070 XT fixes, HUD, flicker fix).
- **[DexNom/VIctory](https://github.com/DexNom/VIctory):** the PC FidelityFX FSR bridge, ray-tracing fixes.
- **[fxceless/victory-fork](https://github.com/fxceless/victory-fork)**, **[myokex/victory-amd](https://github.com/myokex/victory-amd)**, **Geckomacabre**, **cxy0072019-sketch**, **[FQY55kai/ZJOU-VICTORY](https://github.com/FQY55kai/ZJOU-VICTORY)**: see the base's README.
- This branch's changes were made with [Claude Code](https://claude.com/claude-code), coordinated with Codex, alongside Antigravity's parallel branch.

## License

GPL-3.0-or-later, as VIctory. See [LICENSE](LICENSE); the one file that is not covered is named in [docs/asset-policy.md](docs/asset-policy.md).
