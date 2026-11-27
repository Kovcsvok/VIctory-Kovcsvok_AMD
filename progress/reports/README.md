# Reports: index with English summaries

The reports themselves are in Hungarian; new reports are written in English. Each one is one measurement or decision, in order. Times are local (CET).

Image and video links in the reports do not open here: this repository is text-only (see `docs/asset-policy.md`).

## KLBF phase (26 November): what limits the game on 32 GB

| Report | Summary |
|---|---|
| [Claude-01](Claude-01-20261126-1548.md) | cool_fox `ab75ac3` compared with KLBF; local measurement set up. |
| [Claude-02](Claude-02-20261126-1612.md) | A0, cold baseline run: crash in the prologue's robbery scene. |
| [Claude-03](Claude-03-20261126-1631.md) | A0b, repeat: no crash; memory shortage goes together with the stutters. |
| [Claude-04](Claude-04-20261126-1648.md) | B1 (`-LowMemory`, 512 px): fewer long stutters, but a GPU hang during the car chase. |
| [Claude-05](Claude-05-20261126-1719.md) | B2 (large page file): no crash, but the stutters come from remapping memory. |
| [Claude-C1-dontes](Claude-C1-dontes.md) | Decision after the four runs: next is C1, porting `VICTORY_MAP_LEAN`. |
| [Claude-06](Claude-06-20261126-1735.md) | C1 prepared: `MAP_LEAN` ported, a launcher for four runs. |
| [Claude-07](Claude-07-20261126-1832.md) | C2 starts (Lab 63.2 + `MAP_LEAN`); C1 closed after three runs. |
| [Claude-08](Claude-08-20261126-1900.md) | C2 benchmark, `MAP_LEAN` off and on: the longest frame went from 2,483 ms to 552 ms while loading; both about 20 fps after that. |

## The bundle (26 November evening): Belobug's rx9070xt branch

| Report | Summary |
|---|---|
| [Claude-09](Claude-09-20261126-1930.md) | Bundle: Belobug's rx9070xt branch in one piece, built and started. |
| [Claude-10](Claude-10-20261126-1950.md) | First bundle run: fast, but 3–4 fps at the robbery. |
| [Claude-11](Claude-11-20261126-2000.md) | The slowdown is memory shortage; the bundle's own texture cap turned on. |
| [Claude-12](Claude-12-20261126-2020.md) | With 512 px the bundle gets through the robbery (first run to reach the title card); PC FSR in the Series S profile. |
| [Claude-13](Claude-13-20261126-2035.md) | PC FSR gives a much better picture; pop-in comes from the texture queue. |
| [Claude-14](Claude-14-20261126-2045.md) | The vanishing canopy: the bundle reads zeros where a texture was replaced. |
| [Claude-15](Claude-15-20261126-2105.md) | Re-checking textures every 250 ms became the default; `KEEP_SHOWN=2` did not help. |
| [Claude-16](Claude-16-20261126-2110.md) | A 60 fps cap and FSR sharpening in the bundle (menu options 2–4). |

## Trees and flicker (26 November night – 27 November morning)

| Report | Summary |
|---|---|
| [Claude-17](Claude-17-20261126-2120.md) | Review of Codex's foliage test (`VICTORY_INDIRECT_BATCH=1`). |
| [Claude-18](Claude-18-20261126-2200.md) | The foliage test did not help; avatarmanz's fix/popin built in. |
| [Claude-19](Claude-19-20261126-2215.md) | fix/popin is slower on this machine and the trees still flicker; back to the stable base; next a tree test without renderer port 1. |
| [Claude-20](Claude-20-20261126-2235.md) | Trees flicker without port 1 too; port 2 finds about 25 draw records a frame only late. |
| [Claude-21](Claude-21-20261127-0915.md) | **Found why trees vanish**; own fix `VICTORY_TWIN_MOVE`, because avatarmanz's PR 437 crashes on this card; live on/off test on the HUD. |

## Video, boat scene, frame rate (27 November morning)

| Report | Summary |
|---|---|
| [Claude-22](Claude-22-20261127-0935.md) | F9 video recording in the bundle; tidying the videos. |
| [Claude-23](Claude-23-20261127-1005.md) | The picture is clean; the frame rate goes to the boat fix (`LEARN`); ray-tracing shaders fixed; Antigravity's build would crash on this card. |
| [Claude-24](Claude-24-20261127-1025.md) | The boat fix costs 10 ms a frame; the character ray-tracing resolve gives blue faces, so it is skipped. |
| [Claude-25](Claude-25-20261127-1050.md) | Without the boat fix boats stretch and the beard vanishes, so it is the default again; live test for the glasses. |

## Faces, beard, RAM (27 November)

| Report | Summary |
|---|---|
| [Claude-26](Claude-26-20261127-1115.md) | The glasses clamp has no effect; the suspect for garbage faces is lost texture writes; Cal's beard is half missing. |
| [Claude-27](Claude-27-20261127-1150.md) | Where the RAM goes: the driver memory of command lists (at least 1 MB each) and other programs; first fix, the shared prelude pool. (The real time was about 11:25.) |
| [Claude-28](Claude-28-20261127-1155.md) | The RAM fix works (4–6 GB free instead of 1.5–2.5, no crude models); Cal's beard is not caused by the card steps; the common suspect for the beard, the garbage face and the tourist boat is lost writes into compressed textures; the video now closes when the window is closed. |

## Notes from Codex and Antigravity

| Document | Summary |
|---|---|
| [Codex-22](Codex-22-viz-es-forkjavitasok.md) | Codex: the boat scene and the next release. |
| [Hajos-part-villogas](Hajos-part-villogas.md) | The boat mission: flickering canopy on the right-hand shore. |
| [Lomb-popping](Lomb-popping.md) | Vanishing trees and environment objects. |
| [AGY-v2-20261127](AGY-v2-20261127.md) | Antigravity's technical report on `agy-9070-v2`: commit 7, RX 9070 XT ray-tracing check and shader pre-building. |
| [AGY-eloforditas-dontes](AGY-eloforditas-dontes.md) | Antigravity's task for pre-building shaders for AGY v2. |
| [AGY-dontes-LEARN-es-tukrozodes](AGY-dontes-LEARN-es-tukrozodes.md) | AGY v2: decision on frame rate (`LEARN`) and indoor reflections. |
