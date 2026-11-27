# AGY v2 – decision on the frame rate and indoor reflections

(A note by Codex.) 27 November 2026. From commit 7, the tree fix and a standalone LEARN test are justified now. The 30 fps profile should stay the basis of comparison. The 60 fps mode is already a separate menu option.

## How big is the loss?

From the local logs I took the report windows with 3,300–5,600 draws a frame. I paired fps and waiting from counters printed in the same UTC second. The values are the windows' medians.

| Run | Windows | FPS | Waiting for submitted GPU work, ms per frame | Submissions waiting for a learned page, per frame |
|---|---:|---:|---:|---:|
| 09:32, LEARN active | 32 | 22.45 | 16.55 | 3.80 |
| Yesterday 20:51, fast texture refresh | 17 | 30.0 | 0.0 | not measured yet |
| Yesterday 22:17, port 1 off | 86 | 30.0 | 0.0 | not measured yet |

In today's 32 windows the wait was between 13.9 and 20.6 ms. The local code really does switch to waiting when a fill touches a page rewritten late. The old runs ran with a different build and route. The difference is large and the mechanism fits it, but the exact gain, whether it is the only cause, and the freed-up frame rate are still open. [#434's original description](https://github.com/avatarmanz/VIctory-7900XTX/pull/434)

## Antigravity's and Claude's tasks

1. **Antigravity** should take the finished `csomag/claude-twin-move-agy.patch`. It still applies cleanly (`git apply --check`). In `eszkozok/agy-v2-profil.ps1` it should **also** set the matching `VICTORY_` switches to `TWIN_EXACT=0`, `TWIN_MOVE=1`. The profile currently turns EXACT back on explicitly. On the 9070 XT you have already seen device losses twice with it.
2. **Claude** should toggle only LEARN on the same boat stretch, with MOVE fixed. The launcher already accepts the `-AB '10,VICTORY_CARD_STEPS_LEARN'` parameter. Menu option 9 currently toggles both switches. The indicators are the frame rate, the wait, and stretching of the boat or the figures. If LEARN off gives the speed back and the picture stays nice, that should be the fast base. If the stretching returns, the faithful mode should stay a separate option. `PORT_CBV_WRITTEN=2` is already active in AGY. It changes how constant buffers that shaders can write are read; it serves a different case than #434.
3. **Picture quality.** In Claude-23 the fixed Belobug re-examined 42 old bans; the first bind is visible for several character resolve pipelines. One separate BVH-skinning shader still failed. Look at the glasses with this build first, in the same scene. If they are still sky-blue, `Role::Reflect`'s reflection clamp is a candidate behind its own switch. The donor's first commit also brings an LDS and RT port, the second contains many other optimisations. Only the reflection path and the bindings it needs are worth taking. The brightness of outdoor chrome or water is a good control, because the clamp acts on surfaces; it does not single out the glasses. [First donor commit](https://github.com/maren-halv/VIctory-DXR/commit/6c30d582ec1767f621a367848d20bca576c05fd3) · [Refining the execution condition](https://github.com/maren-halv/VIctory-DXR/commit/dd83629436e169c315c21b550aeeb9ff4118b00d)
4. **Green wall.** The local `ambient.rs` computes an upper bound from `MOST`, and scales the old light by a factor of at most 1. A fourfold green amplification does not follow from that. The origin of a faulty pixel cannot be told from the HUD's aggregate DROP value. If it persists with the RT fix, measure the suspect lighting buffer's values on a faulty frame. The MISS without a BVH is a separate candidate; its source also flips the BVH builder's default, so taking the whole commit would change other behaviour too. [fxceless commit](https://github.com/fxceless/victory-fork/commit/4966cd671b990d3e02b7928f4a28debb56c0a3bb)

*(Claude's later measurements: LEARN off gives back about 6 fps, but boats stretch and beards vanish (Claude-24, 25), so LEARN stays on; the `Role::Reflect` clamp did not change the glasses (Claude-26).)*
