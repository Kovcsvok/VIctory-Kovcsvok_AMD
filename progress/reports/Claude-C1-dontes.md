# Decision after the four local runs

26 November 2026 • RX 9070 XT 16 GB, i5-14600KF, 32 GiB RAM • KLBF `643939a7`

**Claude's next task is the C1 experiment.** Based on the four runs, the Windows memory-remapping calls are worth looking at first. In the longest stutter a frame lasted 3,364 ms; the log shows 30.2 ms of our own preparation, 4.5 ms of it texture work. At the same time memory remapping and DirectStorage reads slowed down too. The shared time window does not yet show which one caused the stall.

| Run | Texture cap | Median fps | Measured peak fps | End of run |
|---|---:|---:|---:|---|
| A0 | 1024 px | 15.5 | 22.7 | Access violation at the robbery |
| A0b | 1024 px | 13.7 | 28.4 | Normal exit |
| B1 | 512 px | 13.7 | 24.3 | GPU hang in the car chase |
| B2 | 512 px | 12.1 | 24.5 | Normal exit, 10.9 minutes in the game world |

The values come from the four runs' `fps.json` files, from KLBF's aggregated samples filtered to the game world. B2's folder name is `20261126-170050-B1-rablas-512`; `futas.txt` tells it apart from B1. With the larger page file at least 25.6 GiB of free Windows commit remained, yet this run had the longest stutter. The stutter-reducing effect of the 512 px cap needs further comparison. The raw data and Claude's interpretation are in [Claude-05](Claude-05-20261126-1719.md).

## For Claude – C1

1. Make a separate KLBF work tree from the measured version. As a first step, port the **VICTORY_MAP_LEAN** behaviour introduced by `49d7126`. It skips needless Windows mapping operations in some cases. Keep the original fallback path and KLBF's metrics. The streaming thread's priority stays the original in both measurements, and mapping stays single-threaded. In the donor, `VICTORY_MAP_THREADS=1` means the single-threaded path. [First donor commit](https://github.com/DoubleGhosty/cool_fox/commit/49d7126) · [Parallel mapping's separate commit](https://github.com/DoubleGhosty/cool_fox/commit/565f4a5)
2. Build and check the changed module with the existing targeted tests. Compare the off and on paths with the same binary. Confirm in the log which path ran. Keep B2's profile, save and cache handling the same. Four runs are suggested, in **off–on–on–off** order, 12 minutes each. Mark the time of arriving at the café, because with different play the same minute may cover a different scene.
3. On the same café stretch compare the time spent remapping, the share of intervals with a ≥ 500 and ≥ 1,000 ms frame, and the DirectStorage waits. Give the number of intervals. Mark GPU hangs, missing textures and the level's progress separately. If the repeats point the same way and the difference exceeds the spread of the base runs, suggest a decision. Thread priority and `565f4a5`'s several mapping threads can be a separate next experiment. `ab75ac3` comes forward again if the failed allocations it handles appear.

## Public builds and incoming fps reports

| Candidate | The public data | What we use it for |
|---|---|---|
| AvatarManz `c9c932c` | On the same city street with the Series S profile, 44.9 ms per frame, about 22 fps. The starting 57–75 ms improved substantially. A stable 30+ fps is the project's goal. | Performance donor. KLBF already used the constants and descriptor changes in the local run. The CBV, guard and journal differences can be measured separately later. [Pinned README](https://github.com/avatarmanz/VIctory-7900XTX/blob/c9c932cbcc38defd8f1683d62dd298187f565031/README.md) |
| DexNom `64bd58f` | RX 7900 XTX, Series X, RT, 1440p → 4K FSR Quality. The developer considers it their most stable tested shader and texture profile. On the City waterfront the warmed-up sample was 1.1–1.3 fps, with zero dropped draws and a few black materials. | Picture-correctness control for dark surfaces. Speed is only worth comparing with the local Series S profile on the same scene and settings. [Pinned README](https://github.com/DexNom/VIctory/blob/64bd58f5fb794216894bc0e33e03a3a64d19c347/README.md) |
| Belobug AMD | The Series X / 1440p reference table in the repo gives 19–22 fps for the boat mission, 6–10 for the car chase. The documentation also lists a 41-minute run without a crash. | A third public name for comparing the heavy scenes and Radeon picture faults. Check the table's origin separately before quoting it as a fork measurement of its own. [Repo and reference table](https://github.com/Belobug/VIctory-Belobug-AMD) |
| 30+ and 40–50 fps news | There is a public clip published as gameplay above 30 fps. For it and for the 40–50 fps report, the specific public commit and a comparable measurement are still missing. The Yashank and MadeByNik1 leads are still listed separately in the build watcher. | For a new report, note the original recording, the commit, the hardware, the controllable scene, the duration, the internal resolution, RT and frame generation. Natively rendered and displayed fps go into separate columns. [Community clip](https://www.reddit.com/r/Indiangamers/comments/1y5qk6x/gta_6_goes_beyond_30_in_new_stable_gameplay/) |
