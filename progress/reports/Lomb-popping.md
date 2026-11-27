# Vanishing trees and environment objects

(A note by Codex.)

**First fix attempt:** start the game with profile 1's settings, but with more careful batching of the indirect GPU commands. The separate launcher on the machine is `C:\Games\NOT_GTAVI\meresek\Lomb-proba.cmd`. It needs no build.

| Start from the measurement folder | What it is for |
|---|---|
| `Lomb-proba.cmd` | Profile 1 with a single change: `VICTORY_INDIRECT_BATCH=1`. The ports, PC FSR, 512 px and the 250 ms texture re-check stay. |
| `Inditas-Csomag.cmd` → `1` | The playable base, batching 2. Compare against its picture and speed, from the same save. |
| `Lomb-proba.cmd diag 210` | With the default batching it logs the visibility passes, and looks for flashes in the picture in seconds 210–240 of the renderer's own clock. 210 can be replaced as needed. The detailed counting is active for the whole run, so the diagnostic run's speed is no basis for comparison. |

**What to watch while playing?** When a flickering tree line is visible, stop the vehicle for a moment and keep the camera in the same place. It is a different phenomenon when a distant tree appears for the first time while approaching, and when an already drawn canopy vanishes and returns in the same place. We are mainly trying to fix the second. If the test does not help, the playable base stays the original option 1.

## What justifies the test?

- The 20:51 and 20:56 runs had 271 + 324 log lines measuring records that ran empty because the indirect command list's budget was used up. The largest value printed in both is **0.00 records a frame**. These are rounded interval averages. There is little reason to raise the budget.
- Both runs' logs contain the first binding of the `tree` (`55679a0547649d0b`), `tree_imposter` (`89d08e561897d4e5`), `slod` (`1c4b3c0547e3e6fa`) and `meshlet_args` (`9146291b38ea9ce1`) compute shaders. That only shows the programs are available. The log so far has no instance count produced for individual trees. The two frame strips show different routes and cutscenes, so the flicker rate of the two profiles cannot be told from them.
- In `crates/victory-gpu/src/draw.rs`, in mode 1 `State::buffers_written` drops the batch so far after a shader may have written the buffer. In mode 2 it marks it, and may keep using it among the indirect passes until the next recognised synchronisation or draw. If one step of the visibility chain gets old arguments, the whole object may be missing. That is the test's hypothesis. Recomputing more often may cost time. The switch needed is in the current program.

## If it still flickers

The `walls trace: the frame's main pass` lines written by `VICTORY_WALLS_TRACE=1` count the recordings of the `tree`, `tree_imposter`, `slod`, `meshlet_args` and `depth_pyramid_cpu_occlusion` operations. `VICTORY_POP_WATCH` looks for differences between neighbouring captured pictures. In the diagnostic run's own folder, `victory.log` and the `popwatch` folder belong together. The author's implementation may skip samples, for example when composite picture layers are presented. With an empty picture folder, the existing frame strip's time can be used for orientation.

Compare the same patch of shore in the pictures before, during and after the flash with the operations of the surrounding frame identifiers. If the data point to a switch between a tree and its distant stand-in, the next code change should follow the count **actually read at execution** from the selected GPU argument buffer. A tree's visibility cannot be told from the number of compute calls. If the draw remains even during the flash, we look at the leaf material's transparency mask and mip selection.

*(Later: `INDIRECT_BATCH=1` did not help (Claude-18); the cause was null twin views in the tree culling pass, fixed with `VICTORY_TWIN_MOVE` (Claude-21).)*
