# The boat scene and the next release

27 November 2026 · RX 9070 XT · i5-14600KF · 32 GB · Belobug `rx9070xt` (a note by Codex)

Menu option 1 should stay the playable base. According to the Claude-21 report, turning on our own `VICTORY_TWIN_MOVE` dropped the faulty null views from 140–156 a frame to zero at the live switch. The player saw an improvement too. #437's original `TWIN_EXACT` path crashed twice on this machine; it should stay off. #434 can stay switchable in the base. The end of the boat stretching still needs visual confirmation.

## The next visible fault is the rectangle on the water

fxceless identified two water shaders. Both reached the GPU command list on our machine as well. Their first bind in the local `victory.log` files:

| Run | `5dc3b25986622949` | `6f225b641c5b0708` |
|---|---:|---:|
| `20261126-193520-csomag-jatek` | frame 2,817, line 16,264 | frame 2,817, line 16,266 |
| `20261126-224719-csomag-faproba-port12-ki` | frame 2,564, line 15,873 | frame 2,564, line 15,887 |

The donor reports black/grey patches on open water disappearing after taking these two programs out of the forced wave-wide mode. After #1419 it further improved the accuracy of the reduction. A separate fix of theirs targets flickering water tiles: it initialises a tile's extremes even if the thread for the corner exits early. The author has not yet confirmed the latter in play in their report. The origin of the rectangle on our screen is still open. [Donor's measurements](https://github.com/fxceless/victory-fork/blob/674290601fb9dba441e711cc951a8950ff08ddc6/README.md) · [More accurate reduction](https://github.com/fxceless/victory-fork/commit/e3307c7727a604d8847ace8751cc6623bad26b5c) · [Initialising water tiles](https://github.com/fxceless/victory-fork/commit/a918163849d506fc15a7c5d20106da03e2138365)

**Task for Claude.** For the two identifiers, print once the local compiler's actual wave mode and the shader cache hit. I did not find the names of the donor's two wave filters in the local source or the launcher, so copying the environment variables from there is not a test by itself. If the compilation differs, apply the more accurate path to these two shaders first, and give the mode its own cache key. A short recording from the boat save with the same camera is enough. If the rectangle stays, switch the initialisation fix separately. That way the mission does not have to be played through again.

## Three more fixes for the local source

| Row | Fix | Local check and suggestion |
|---|---|---|
| 1 | ka1qux · the right type for a missing constant buffer | Port 5 is active in the base. For a missing entry the local code may give a null texture view to a shader reading a raw buffer. The patch only changes this case. `git apply --check` succeeds. [Commit](https://github.com/ka1qux/BRVIctory-ka1qux/commit/95d571feb3aea43e62866b3f82f4b2971f39e45a) |
| 2 | cool_fox · DirectStorage memory | The list of file paths grows here even with diagnostics off. The patch only collects them with tracing active, and releases the compressed input earlier for zlib + BCPack requests. `git apply --check` succeeds. The saving on this machine has not been measured yet. [Commit](https://github.com/DoubleGhosty/cool_fox/commit/a96549d3ef4a2533dd0af0ac42957f81a7f0d005) |
| 3 | fxceless #1324 · freeing GPU descriptor slots | The local code identifies the heap by its address. If the address comes back into use, an old command list may free slots of the new heap that were handed out to something else. The donor adds a generation number and showed the fault with a separate WARP test. The PR's actual diff differs from the local source in all three files; it needs a manual port. No local picture fault has been tied to it yet. [PR and regression test](https://github.com/fxceless/victory-fork/pull/1324/files) |

The first two fit in one integration branch, with one build and the next normal play run. I checked that the patches apply; I did not build or run these changes. #1324's own test can come over with the code. I would leave out the descriptor capacity increase that worked in the other fork for now: in 260 reported time windows of three earlier local runs I found zero refused allocations. The freeing fault is independent of that.

**An addition for the F9 recording.** At the start of a recording and at every change of the A/B state, the run's log should get the frame number, the monotonic time and the MOVE/LEARN state. The HUD mark should stay in the video. If the fault flashes on another machine, the recording and the matching log line can be read together. No second recorder is needed for this.

## What is worth sharing on GitHub?

As a first release I suggest a separate repository containing a source patch. The finished `meresek/csomag/csomag-belobug-9070.patch` applied without errors onto the clean `cd8dfc06ace7ccb91a19431e74bc2d0de2a10145` base in a separate git index. SHA-256: `D558583BDE4310F7438F8D9C9BD8148560B1E5DBDAE08478E9A8E285B5FD41E6`. This identifies the Claude-21 state. A newer version with F9 should be a separate release. [Exact Belobug base](https://github.com/Belobug/VIctory-Belobug-AMD/tree/cd8dfc06ace7ccb91a19431e74bc2d0de2a10145)

The patch needs the GPL licence and the attributions, the dates and origins of the changes, a build guide and a launcher that takes the game's and the cache's folders as parameters. The current local launcher lives outside the patch and uses the machine's own paths. The README should state the tested hardware, the 512 px profile, the scene that gives nearly 30 fps, the switches and the open water/boat fault. That way others can build it with their own game files and compare. For a bug report the build's identifier, GPU/driver, location and a short log excerpt are enough. [GNU GPLv3, sections 5–6](https://www.gnu.org/licenses/gpl-3.0.html#section5)

I would wait with releasing a finished EXE. At build time `bcpack.rs` embeds the `bcpack-tables.bin` table into the EXE, which upstream's own policy explicitly excludes from the repo's licence. A binary release needs the distribution rights of the table and of the bundled external components cleared, and the exactly corresponding source provided. The clean patch touches 12 source files. The game files, saves, caches, videos and the local SDK/DLLs should stay on the machine. [Belobug asset policy](https://github.com/Belobug/VIctory-Belobug-AMD/blob/cd8dfc06ace7ccb91a19431e74bc2d0de2a10145/docs/asset-policy.md)

The morning search queried the default branch of 43 known repositories, with at most 40 recent entries per repository. Four repositories could not be fetched. The list above contains the checked candidates.
