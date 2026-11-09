# Test branch: CSP4CMSIS dev/tracing (unreleased)

**Not for merging.** `main` stays on the vendored CSP4CMSIS 3.0.1, the version of the book. `main` moves to CSP4CMSIS 3.2.0 when it is released.

## Purpose

To run `csp4cmsis_neuropathway_image_uplink` on the board with the unreleased ALT guard fix of CSP4CMSIS, and to show on hardware that the fix removes the FileSource defect: two `Alternative`s bound one channel end to different variables, and a command taken by one went into the other's variable (CSP4CMSIS `docs/known-issues.md`).

## Library

`EPII_CM55M_APP_S/library/csp4cmsis/` is `csp4cmsis/` and `LICENSE` of CSP4CMSIS `dev/tracing` at commit `454af80f25a485b820851d8061d678c63e38bbcf`, unmodified (`VERSION` says so). Added since 3.0.1: `inc/csp/csp4cmsis_trace.h`, `inc/csp/csp_trace_ring.h`, `src/csp_trace_ring.c`; none removed. `csp4cmsis.mk` is unchanged (it compiles every source in `src/`). Built with `CSP4CMSIS_TRACE` undefined, GCC 13.2.Rel1.

The app compiles unchanged, with no new warnings. SRAM use is the same as on `main`, to the byte: 1 381 632 B (camera), 1 359 264 B (SD card).

| | 3.0.1 (`main`) | dev/tracing |
|---|---|---|
| `sizeof(csp::Alternative)` | 92 B | 156 B |
| `sizeof(csp::Chanin<int>)` | 28 B | 28 B |

## Results on the board (2026-11-09)

**SD-card build, 640x480, 200 frames.** GUI commands: `set pace 0`, `loop on`, `restart`, two passes, then `set pace 500` for 20 s, `set pace 0`, `loop off` (the stream ended at the end of the manifest), `restart`.

| | `main` (3.0.1) | dev/tracing |
|---|---|---|
| Frame rate, pace 0 | 5.05-5.36 fps | 5.41 and 5.38 fps (passes 1 and 2) |
| Scores, pass 1 vs 2 vs 3 | 200 of 200 identical | 200 of 200 identical; 85 of 85 in the partial 4th stream |
| Scores, pass 1 against `main`'s pass 1 | | 200 of 200 identical |
| CRC / read / JPEG errors | 0 | 0 |
| pace, loop, restart | handled | all handled, each acknowledged with its value |

**Camera build, 5 min, a person walking in and out of view (2026-11-10).** 8.26 fps (2513 frames), all 2513 scores received, 0 CRC, sequence or EOI errors, no reset. 14 episodes with the person in view (score 40 or more, up to 118 of 127, from 0.1 s to 32 s long) between empty scenes. `set threshold 40`, `set window 4`, `set window 8`, `set threshold 0`, sent from the GUI at 60, 120, 200 and 240 s, were each applied at the next frame. While the window was 4, an image came every 0.5 s instead of every 1 s. 219 images, all at or above the threshold in force: none was sent from 71 s to 136 s, when the scene was empty and the threshold 40. An earlier 5-minute run with the scene empty (2026-11-09) gave the same frame rate, errors and command results.

**Stack high-water marks** (bytes used of the stack, highest over the runs):

| Process | Stack | `main`, camera | test, camera | `main`, SD card | test, SD card | Lowest headroom (test) |
|---|---|---|---|---|---|---|
| Camera | 1536 | 1008 | 1080 | | | 30 % |
| FileSource | 2048 | | | 1232 | 1376 | 33 % |
| Inference | 2048 | 1248 | 1408 | 1232 | 1368 | 31 % |
| Reporter | 1024 | 640 | 680 | 640 | 728 | 29 % |
| Command | 1024 | 304 | 440 | 304 | 304 | 57 % |
| CSP_Main | 1536 | 1016 | 1016 | 1016 | 1016 | 34 % |

No process is under 25 % headroom. The larger `Alternative` adds 64 bytes per `Alternative` on a stack. Command's 440 bytes came from a run in which the camera build rejected `loop` and `restart`, a path the `main` figure did not exercise.

No run printed "channel end bound twice", a second-process error or any other fatal error.

## Regression on hardware

Commit `e364823` puts back the pattern that failed on 3.0.1: the poll bound to `cmd`, built once; the pace wait bound to a loop-local `command_t c`, built in every iteration. `d5d4aca` reverts it. The default pace (125 ms) runs the pace wait from boot, so the wait binds the slot before the first command. After `set pace 0` only the poll selects, with the slot last bound by the wait. That is the case that failed. The same 16 GUI commands were sent to the regression image built against each library:

| Commands | 3.0.1 | dev/tracing |
|---|---|---|
| `loop on`, `set pace 500`, `set pace 300`, `restart` (pace waits running) | handled | handled |
| `set pace 0` | handled | handled |
| the next 11: `restart` x4, `loop off/on/off`, `set pace 400/0/250/0` | every one reported as "again not applicable (no sensor)" (the poll's stale, zero-initialised `cmd`); no restart happened | all handled with their values; every restart ended the stream and started a new one |

The 3.0.1 build was a working-tree build of this commit with `main`'s library; it was not committed.
