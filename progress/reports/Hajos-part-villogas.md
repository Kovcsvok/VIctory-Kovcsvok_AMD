# Boat mission – the right-hand shore's canopy flickers

(A note by Codex.) The first file of the frame strip for the run 20261126-202038-csomag-512-pcfsr was taken at 20:28:26.765. The minute examined is 3:00–4:00 of the recording. The log is in UTC, the JPEG file names in local time.

| Recording | Original JPEG | What is visible on the right-hand shore? |
|---|---|---|
| 3:44.116 | 203210-881.jpg | A large, dark canopy against the sky. |
| 3:44.368 | 203211-133.jpg | Where the large canopy was, sky and lower vegetation show. |
| 3:44.619 | 203211-384.jpg | The large canopy returns while the boat moves on. |

The same crop of the three original pictures: `Hajos-part-3m44.jpg` (local only). The full pictures are under `meresek/kepsor/20261126-202826-csomag-pcfsr/` from the game's folder. The frame strip is about 4 pictures a second. The phenomenon can be shown, but its exact duration cannot be read.

The `victory.log` summary written at 19:32:11.954895Z shows 30.1 fps, 9,683 waiting texture slots, 86 operations dropped for lack of a host pipeline and 78 dropped indirect operations a frame. The nearly simultaneous diagnostics measure 0.00 indirect records a frame that ran empty because the list's budget ran out. The aggregate counters carry no object identifier. The detailed breakdown before it also lists operations belonging to the turned-off ray tracing among the drops.

**Development direction.** Vanishing and returning is a stronger lead than the length of the texture queue. In the test round of the already prepared 250 ms profile we look for the same silhouette change. If it persists, check whether the vegetation's draw command runs in both states. If the command or the instance count disappears, look at object visibility and the switching of levels of detail. If the draw and the instance count remain, the leaf material's transparency mask, the selected mip and the texture bound to it are the next lead. The current log does not identify the tree's specific shader.

*(Later, Claude-21: the cause was null twin views in the tree culling pass, fixed with `VICTORY_TWIN_MOVE`.)*
