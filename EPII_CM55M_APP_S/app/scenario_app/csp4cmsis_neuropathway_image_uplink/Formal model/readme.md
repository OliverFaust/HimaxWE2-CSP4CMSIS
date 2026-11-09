# Neuropathway: Formal Model (CSP-M)

This directory holds two models. `Neuropathway.csp` (with `Neuropathway_controls.csp`) models the network of the parent app, before the uplink; the sections below up to *Uplink model* describe it. `Uplink.csp` (with `Uplink_defs.csp` and `Uplink_controls.csp`) models this app's network with the four JPEG buffers and the Reporter's ready token as tokens, and `Uplink_command.csp` (with `Uplink_command_defs.csp` and `Uplink_command_controls.csp`) its command path; see [Uplink model](#uplink-model-uplinkcsp). `Uplink_source.csp` (with `Uplink_source_defs.csp` and `Uplink_source_controls.csp`) models the frame source, Camera or FileSource, with end of stream; see [Frame-source model](#frame-source-model-uplink_sourcecsp). `FileSource_commands.csp` states what FileSource's command handling must do and shows the ALT guard-slot defect of CSP4CMSIS against it; see [FileSource commands](#filesource-commands-filesource_commandscsp).

This directory contains the CSPm formal specification for the neuropathway vision pipeline described in the *Neuropathways* chapter of the book: the three-stage `Camera` → `Inference` → `Reporter` network that processes camera frames through NPU-based person detection, and `MainApp`, which sends the stack report. It provides a mathematical abstraction of the pipeline's communication structure, isolating the CSP-level synchronisation guarantees from the low-level FreeRTOS task scheduling, hardware interrupt handling, and TensorFlow Lite Micro / Ethos-U55 driver details covered in the book. The model is checked with [ProB](https://prob.hhu.de/) 1.16.1 (`probcli Neuropathway.csp -assertions`); FDR can check it as well.

## Model Overview

The model mirrors the application (`csp4cmsis_spn.cpp`): the console has one owner, the **Reporter**. Camera, Inference and MainApp never print; they send reports over **one rendezvous channel with three writers**, `report_chan`. In CSP-M the writers do not synchronise with each other on `report_chan` (they are composed with `|||` or with an interface that does not contain it), while each synchronises with the Reporter.

1. **`ENV`:** the hardware frame-ready interrupt, repeatedly offering the trigger event on `g_trigger_chan`. (In the application the trigger goes through a one-slot buffered channel; since Camera re-arms the capture only after reading a trigger, at most one is pending, and the slot behaves like a rendezvous with the interrupt.)
2. **`Camera`:** the camera driver prints its start-up log (`camera_log`), then Camera reports `started.camera` -- once -- and enters its loop: wait for a trigger, send the frame index on `frame_chan`. Indices are bounded to `{0, 1, 2}` (`MAX_INDEX = 3`) for exhaustive checking; the application uses an unbounded counter.
3. **`Inference`:** initialises the model only after its first frame (i.e. after Camera has started), reports `started.inference`, then reports one `result.f.p` per frame. The prediction `p` is an *internal* choice (`|~|`) between `person` and `no_person`: it depends on image content the model cannot see.
4. **`MainApp`:** on every tick of its own timer (`stack_tick`, 3 s in the application) it sends one stack report per process -- `stack.cam`, `stack.inf`, `stack.rep` -- and one for itself, `stack.main_app`, over its own writer end. It never prints, and it depends on nothing the pipeline does.
5. **`Reporter`:** receives any report and prints it as one line (`line.r`). It has no state and no timer.

## What is checked

The console is checked in two views, because MainApp's stack report runs on its own timer and may fall between any two pipeline lines:

| Assertion | Meaning | Result |
|---|---|---|
| `SYSTEM :[deadlock free [F]]` | the system never stops | holds |
| `SYSTEM :[divergence free]` | it never loops internally without an observable event | holds |
| `SPEC_PIPE [T= CONSOLE_PIPE`, `SPEC_PIPE [F= CONSOLE_PIPE` | pipeline view (stack lines hidden): the camera driver's log, `started.camera`, `started.inference`, then exactly one result line per frame, in frame order -- and the next result line always comes (stable failures), whatever MainApp does | holds |
| `SPEC_STACK [T= CONSOLE_STACK`, `SPEC_STACK [F= CONSOLE_STACK` | stack view (only stack lines visible): complete groups (Camera, Inference, Reporter, CSP_Main), in order, for ever | holds |
| `SYSTEM_STALL :[deadlock free [F]]`, `SPEC_STACK [F= CONSOLE_STACK_STALL` | Inference stops for ever after its first result (as in the board's stall test): the pipeline stops, but the system does not deadlock and the stack report goes on unchanged | holds |

(The pipeline view is not checked for divergence: with the stack lines hidden, MainApp's timer-driven loop is a hidden cycle, which is not a fault of the network.)

What the model does not cover: timing. That the camera driver's start-up log (printed by the driver, outside the Reporter) has ended before MainApp's first stack report is a timing property: MainApp's first report comes 3.5 s after start, and on the board Camera reported `started` about 2.9 s before it.

## Positive controls (`Neuropathway_controls.csp`)

Each control is a plausible wrong design that must **fail** its check, showing that the checks above can detect such faults:

| Control | Design | Check | Result |
|---|---|---|---|
| 1 | one channel per writer, and a Reporter that reads them in a fixed order (Camera, then Inference) every round | `SYSTEM1 :[deadlock free [F]]` | **fails** (as it should): the Reporter waits for a second Camera report that never comes, while Inference waits to report -- deadlock |
| 2 | the real pipeline, but Inference also prints directly (`direct_print`), like the old `dbg_printf` | `SPEC_PIPE [T= CONSOLE2` | **fails** (as it should): `direct_print` appears among the Reporter's lines |
| 3 | the previous design: the Reporter prints the stack report itself after a report (timer expired), MainApp sends nothing; Inference stalls after its first result | `SPEC_STACK [F= CONSOLE_STACK3` | **fails** (as it should): once the reports stop, the stack report stops too -- exactly when it is needed |

ProB's output for both files is in `prob_results.txt` (ProB 1.16.1; 8 of 8 assertions hold for the model, 3 of 3 fail for the controls). The `*.csp.pl` files are ProB's parse caches.

## CSP-M Specification

See `Neuropathway.csp`; the core of it:

```csp
Camera = camera_log -> report_chan!started.camera -> CameraLoop(0)
CameraLoop(c) = g_trigger_chan -> frame_chan!c -> CameraLoop((c + 1) % MAX_INDEX)

Inference = frame_chan?f -> report_chan!started.inference -> Infer(f)
Infer(f)  = (report_chan!result.f.person -> Next) |~| (report_chan!result.f.no_person -> Next)
Next      = frame_chan?f -> Infer(f)

MainApp = stack_tick -> report_chan!stack.cam -> report_chan!stack.inf ->
          report_chan!stack.rep -> report_chan!stack.main_app -> MainApp

Reporter = report_chan?r -> line!r -> Reporter

WRITERS = (Camera [| {| frame_chan |} |] Inference) ||| MainApp
NETWORK = WRITERS [| {| report_chan |} |] Reporter
SYSTEM  = ENV [| {| g_trigger_chan |} |] NETWORK

CONSOLE_PIPE  = SYSTEM \ union(INTERNAL, {| line.stack |})
SPEC_PIPE     = camera_log -> line!started.camera -> line!started.inference -> RESULTS(0)
CONSOLE_STACK = SYSTEM \ diff(Events, {| line.stack |})
SPEC_STACK    = line!stack.cam -> line!stack.inf -> line!stack.rep -> line!stack.main_app -> SPEC_STACK
```

(`print` is a CSP-M keyword, hence the channel name `line`.)


## Uplink model (`Uplink.csp`)

The uplink network (`csp4cmsis_spn.cpp`, `camera_process.cpp`, `inference_process.cpp`, `reporter_process.cpp`, `command_process.cpp`; app README sections 2-4, 10, 14 and 15) is modelled in two parts, each with its definitions in a `_defs` file that the assertions and the positive controls `include`:

* `Uplink.csp`: Camera, Inference, MainApp and the Reporter with the four JPEG buffer ids as data, `free_chan` and the ready token (`ready_chan`), the per-frame `Scores` reports and the event filter.
* `Uplink_command.csp`: the command path (Command, `cmd_chan`, Camera's poll, the acknowledgements under the ready token), with Inference reduced to what that path touches.

A single model of both did not finish: with command lines able to arrive between any two events of the other processes, a ProB run reached 13.6 GB in 9.5 hours without completing one check. Commands and buffers do not interact (a command changes settings, not buffer roles), so the two parts are checked apart.

Bounds: 4 buffer ids (as on the board), windows of `W = 2` frames instead of 8, frame indices 0..1 (only the position in the window matters), and the merged count saturating at `MAXM = 2`. With indices 0..3 the main model's checks ran out of memory; 0..1 lose nothing, since nothing depends on the index but `i % W`. Checked with ProB 1.16.1; the nine assertions of `Uplink.csp` each in a run of their own to bound memory (25 to 336 s, at most 6.2 GB), `Uplink_command.csp` in 73 s.

### `Uplink_defs.csp`

1. **`Camera`:** reports `started.camera`, then per frame: trigger, `frame_chan!i!b` (the frame's position in the window and the buffer the DMA wrote), `release_chan?nb` (the next DMA target).
2. **`Inference`:** starts with the free token and the ready token. Per frame: poll `free_chan` (a returned buffer joins the spares), poll `ready_chan` (the token is back), release a spare (internal choice), score (`better`, `worse`, `failed`, a visible `scored.o.b`), then `End`: holding the ready token it writes one report: at a window end, if it also holds the free token, a `Window` report, with the image (`wimage.m.b`) or, when the filter fails, `suppress.b` (the best goes back to the spares) and `window.m`; otherwise `scores` (with `merge` first at a window end). Without the ready token it writes nothing and merges a window that ends. The filter (best >= T and at least K frames >= T) depends on the scores, so it is an internal choice.
3. **`FREE`, `READY`:** one-slot buffered channels, polled with a PRI ALT and SKIP (value or empty, never both); a second write to a full slot leads to `overflow`.
4. **`Reporter`:** a text report becomes a `line`; a `wimage` report its line, the send (`uplink.b`) and `free_in!b`; after each of Inference's reports it returns the token (`ready_in`). `ReporterStall` may stop for ever after any of Inference's reports, without returning the token (or the buffer). `MainApp` sends stack reports (`MainAppN(n)`: n of them).
5. **`OBS`:** the buffer-role observer of before (next, pending, best, sending including the slot, spare), extended by `suppress`, which moves the best back to the spares.

### Assertions (`Uplink.csp`)

| Assertion | Meaning | Result |
|---|---|---|
| `SYSTEM :[deadlock free [F]]`, `SYSTEM :[divergence free]` | the network never stops; no internal loop | holds |
| `RUN(diff(Events, {error, overflow})) [T= OBSERVED(SYSTEM)` | the four ids always form a permutation across the roles; Camera is only handed a spare; only the window's best is sent; neither slot (`free_chan`, `ready_chan`) overflows | holds |
| `MCOUNT(0) [T= SYSTEM \ ...` | every `Window` line, with or without an image, carries the number of windows merged since the last | holds |
| `TOKEN [T= SYSTEM \ ...` | Inference's reports and the Reporter's token returns alternate: Inference never writes a report while the Reporter is still busy with its previous one | holds |
| `SYSTEM_STALL :[deadlock free [F]]` | with the Reporter stalled for ever after any report, nothing stops | holds |
| `CYCLE [FD= SYS(Inference, Reporter, MainAppN(2)) \ ...` and `... ReporterStall ...` | Camera and Inference keep cycling (the trigger is never refused), with the Reporter running and with it stalled. Everything but the trigger is hidden and the refinement is failures-divergences, so a refused trigger and any loop of hidden events both fail it. MainApp sends two reports here: its stack reports would otherwise be such a loop while the Reporter runs, and on such a loop a blocked Camera would go unseen (a state on it is never stable, so it has no refusals; an earlier version of this check, with `[F=` and an unbounded MainApp, passed with Camera blocked, see control 3) | holds |
| `PRE [FD= SYSTEM_STOP \ ...` | after the uplink stops following an image, only merges follow, one per window, for ever; before it, `Window` lines and merges in any order | holds |

### Command path (`Uplink_command.csp`)

Camera polls `cmd_chan` (one slot) after each frame and marks the next frame when it has written the sensor; Inference keeps the ready token, the window position and a pending acknowledgement, and with the token writes one report per frame: the `Window` report at a window end, else the acknowledgement, else `Scores`. Command reads abstract lines (`rx`), writes valid ones to `cmd_chan` or reports them as rejected; `CommandN(n)` handles n lines, `CommandValid` valid lines for ever (each needs a frame), `CommandNone` none. All 11 assertions hold: deadlock and divergence freedom, no overflow of `ready_chan`, the token alternation (acknowledgements included), deadlock freedom with the Reporter stalled, and Camera and Inference cycling (`[FD=`, MainApp with two reports) in all six combinations of {`CommandN(2)`, `CommandValid`, `CommandNone`} and {`Reporter`, `ReporterStall`}.

What the models do not cover: timing (how long a send or a stall takes, how many scores a batch must hold; the board's stall build measures that), the scores' values and the batch contents, the JPEG contents and the D-cache, the frame-ready ISR's buffered channel and the UART's receive interrupt, the console's text beyond the report kinds, and the Stage 0 build.

### Positive controls

| Control | File | Design | Check | Result |
|---|---|---|---|---|
| 1 | `Uplink_controls.csp` | Camera may be retargeted to the window's best: Inference releases from its spares and its best | `RUN(...) [T= OBSERVED(SYS(Inference1, ...))` | **fails** (as it should): the best is handed out as a DMA target |
| 2 | `Uplink_controls.csp` | Inference sends a `Window` report with an image while holding the ready token but not the free token | `RUN(...) [T= OBSERVED(SYS(Inference2, ...))` | **fails** (as it should): a second image while the previous buffer is not yet read back |
| 3 | `Uplink_command_controls.csp` | Camera reads `cmd_chan` with a blocking read instead of polling it | `CYCLE [FD= SYS(Camera3, Reporter, MainAppN(2), CommandNone) \ ...` | **fails** (as it should): with no command, Camera stops after one frame |
| 4 | `Uplink_controls.csp` | Inference writes its `Scores` report on every frame, with or without the ready token | `CYCLE [FD= SYS(Inference4, ReporterStall, MainAppN(2)) \ ...` | **fails** (as it should): with the Reporter stalled, Inference blocks on `report_chan` and Camera stops |

ProB's output is in `prob_results.txt` (9 of 9 and 11 of 11 assertions hold; 4 of 4 controls fail). The variants of controls 1, 2 and 4 are copies of `Inference` from `Uplink_defs.csp` with a suffix and one part changed.


## Frame-source model (`Uplink_source.csp`)

The app takes its frames from the camera or, with `FRAME_SOURCE=sdcard`, from FileSource (app README, sections 16-18). `Uplink_source.csp` (definitions in `Uplink_source_defs.csp`, controls in `Uplink_source_controls.csp`) checks that the network is correct with either source. The Camera model of `Uplink.csp` and its checks are unchanged.

**Why one source process in the model covers both.** Everything the rest of the network sees of a source is what happens on its four channels: it writes a `frame_t` on `frame_chan`, reads a `release_t` on `release_chan`, polls `cmd_chan` and writes `report_chan`. On `frame_chan` and `release_chan` both sources follow the same protocol. The source sends a frame in the JPEG buffer it was last given (buffer 0 at start), then waits for Inference to release the buffer for the next one, and accepts whichever buffer it is given. It refills the raw buffer only after that release, which Inference gives after `cv_prepare()`. Camera points the DMA at the released buffer; FileSource reads the next `.jpg` into it. Whatever happens in between (a trigger from the frame-ready interrupt; or two file reads, CRC checks and a pace wait) is internal to the source. `SOURCE(b)` states this protocol, with an internal choice between a frame and an end-of-stream terminator. Both `Camera` and `FileSource` refine it in failures-divergences, with everything but `frame_chan` and `release_chan` hidden. So whatever Inference and the downstream processes can observe of either source on those channels is a behaviour of `SOURCE`, and the buffer and token properties carry over. `cmd_chan` is the same for both (a one-slot channel polled with a zero-timeout ALT after each frame; the command path is checked in `Uplink_command.csp`).

The two sources differ on `report_chan`, which is visible to the Reporter, and the model includes that. Camera writes it once, at start. FileSource writes it between frames: errors with a file name, command acknowledgements, a status line every 10 s, and the end of a stream. This is the one property that does not carry over (see below).

**End of stream.** `frame_chan` carries a kind, `img` or `eos`. The terminator (`frame_t.end`) carries a JPEG buffer but no image. Inference releases that buffer straight back as the next target. If the window has frames or scores are waiting, it then waits for the ready token with a blocking read, not a poll. For a partial window it also waits for the free token, and it sends the partial window's `Window` report (with the image if it passes the filter), or a `Scores` report. The next stream starts a new window. To model this, Inference counts its position in the window (`pos`) instead of taking it from the frame index, as the firmware does since the flush (`pos` restarts at 0). FileSource ends a stream at the end of the manifest without `loop`, or on `restart`. It writes the terminator and the end report, waits for `restart` (modelled as `fs_restart`), and starts again. Before each frame it may write one report; then it either sends a frame (`fs_read`, its two files read) or ends the stream.

| Assertion | Meaning | Result |
|---|---|---|
| `SOURCE(0) [FD= Camera \ ...`, `SOURCE(0) [FD= FileSource \ ...` | both sources follow the source protocol on `frame_chan` and `release_chan` | holds (3 s each) |
| `SYSTEM_FS :[deadlock free [F]]`, `SYSTEM_FS :[divergence free]` | the FileSource network never stops; no internal loop | holds (366 s, 363 s) |
| `RUN(diff(Events, {error, overflow})) [T= OBSERVED(SYSTEM_FS)` | the buffer roles of `Uplink.csp`, with the terminator's buffer going back to the spares; neither slot overflows | holds (778 s) |
| `MCOUNT(0) [T= SYSTEM_FS \ ...` | every `Window` line carries the number of windows merged since the last, partial windows included | holds (434 s) |
| `TOKEN [T= SYSTEM_FS \ ...` | Inference's reports, the flush reports included, and the Reporter's token returns alternate | holds (442 s) |
| `CYCLE_F [FD= SYS(FileSource, Inference, Reporter, MainAppN(1)) \ ...` | with the Reporter running, frames and terminators keep flowing (`frame_chan` is never refused for ever, no hidden loop) | holds (482 s, 9.0 GB) |
| `CYCLE_F [FD= SYS(FileSource, Inference, ReporterStall, MainAppN(1)) \ ...` | the same with the Reporter stalled | **fails, as expected** (15 s): see below |
| `SYSTEM_CAM :[deadlock free [F]]`, `RUN(...) [T= OBSERVED(SYSTEM_CAM)` | the Camera network with this Inference: no deadlock, buffer roles kept | holds (143 s, 297 s) |
| `CYCLE [FD= SYS(Camera, Inference, ReporterStall, MainAppN(2)) \ ...` | with Camera, Inference keeps cycling with the Reporter stalled | holds (413 s) |

Bounds as in `Uplink.csp` (4 buffer ids, `W = 2`, `MAXM = 2`). Each assertion ran in a probcli run of its own, at most 14 GB (2 s to 778 s). In the two FileSource cycling checks MainApp sends one stack report, not two as in `Uplink.csp`: with two, the check with the Reporter running ran out of memory at 14 GB after 12 minutes. The bound only has to be finite, so that the stack reports cannot form a loop of hidden events that would hide a blocked source.

**The difference between the sources.** With the Reporter stalled for ever after any report, Camera and Inference keep cycling (as in `Uplink.csp`), but FileSource does not. FileSource blocks on `report_chan` the next time it reports, and Inference's end-of-stream flush waits for the ready token. That is acceptable for the SD card: no frame is lost by waiting, since FileSource only reads the next file later. With a camera, a blocked Camera would miss sensor frames, which is why Camera never reports while frames run. The assertion is kept in `Uplink_source.csp` and documented as expected to fail.

**Positive controls** (`Uplink_source_controls.csp`), both of which must fail:

| Control | Design | Check | Result |
|---|---|---|---|
| 5 | at end of stream, Inference flushes the partial window with its image without waiting for the free token | `RUN(...) [T= OBSERVED(SYS(FileSource, Inference5, Reporter, MainApp))` | **fails** (as it should, 136 s): after a terminator the partial window's image is reported while the previous image's buffer is still in `free_chan`'s slot |
| 6 | after the terminator, FileSource goes on with the same buffer instead of waiting for a release | `SOURCE(0) [FD= FileSource6 \ ...` | **fails** (as it should, 2 s): after `frame_chan.3.eos` the next frame comes without a `release_chan` event |

Not modelled: the card driver's waits, pace, CRC checks and timing (internal to FileSource), and the ALT guard-slot issue of CSP4CMSIS. The latter is a property of the library's implementation, not of the channel protocol: two `Alternative`s on one channel end redirect each other's input. FileSource avoids it by binding both to one variable (app README, section 18). `FileSource_commands.csp` models it on its own (below).

ProB's output is in `prob_results.txt`: of the 12 assertions of `Uplink_source.csp`, 11 hold and the one expected to fail fails; both controls fail.


## FileSource commands (`FileSource_commands.csp`)

FileSource takes commands from `cmd_chan` in two `Alternative`s: a poll after each frame (a command or move on at once) and the pace wait (a command or the deadline). In CSP4CMSIS 2.0.0 to 3.1.0 a channel end has one ALT guard slot, and the latest `in | var` sets the variable a value taken from the end goes into. With the poll bound to `cmd` once and the wait bound to a loop-local `c` in every round, a command taken by the poll after the first pace wait went into `c`, and the poll read its own stale `cmd`: a `restart` was handled as `set again 0` (app README, section 18; CSP4CMSIS `docs/known-issues.md`).

- **Part 1, the requirement.** `SYSTEM_REQ` is FileSource with both alternations as external choices, and any sequence of user commands (`Restart`, `Pace`). `CMD_SPEC = cmd?c -> handled!c -> CMD_SPEC`: every command FileSource accepts is acted on, with the value accepted, before the next one is accepted. Frames, the poll's empty branch and the pace deadline are hidden.
- **Part 2, the defect.** `STORE` is one slot per channel end (`SLOT`, which remembers the variable of the latest `bind`) and the two variables, `V_cmd` (the poll's) and `V_c` (the wait's), both starting at `Init` (the zero-initialised `command_t`). A value taken from the channel (`deliver`) goes into the slot's variable (`put`) before the input completes; each alternation then reads its own variable (`get`). `FS_BAD` binds the poll once, then the wait in every round, as FileSource did.
- **Part 3, the workaround.** `FS_FIX` binds both alternations to `V_cmd`, as FileSource does now. The library fix of CSP4CMSIS 3.2.0 (every `Alternative` sets its channel guards to its own variables at the start of each select) gives every alternation its own variable back, so the poll again reads what the slot delivered; `CMD_SPEC` is the behaviour it restores.

| Assertion | Meaning | Result |
|---|---|---|
| `SYSTEM_REQ :[deadlock free [F]]` | the requirements model never stops | holds |
| `CMD_SPEC [T= SYSTEM_REQ \ Internal`, `CMD_SPEC [F= ...` | the requirements model meets the requirement | holds (both) |
| `CMD_SPEC [T= SYSTEM_BAD \ Internal` | the defective binding meets the requirement | **fails, as expected**: `cmd.Restart, handled.Init` |
| `SYSTEM_BAD :[deadlock free [F]]` | the defect does not stop FileSource; it only acts on the wrong value | holds |
| `CMD_SPEC [T= SYSTEM_FIX \ Internal`, `CMD_SPEC [F= ...` | the workaround meets the requirement | holds (both) |
| `SYSTEM_FIX :[deadlock free [F]]` | the workaround never stops | holds |

The counterexample: after one round with no command (poll empty, pace deadline, both hidden), the slot is bound to the wait's `V_c`; the next poll accepts `cmd.Restart`, the value goes into `V_c`, and the poll reads `V_cmd`, still `Init`. ProB searches depth first and reports a longer trace ending `cmd.Restart, handled.Pace` (the poll reads an older command). That `<cmd.Restart, handled.Init>` is a trace of `SYSTEM_BAD \ Internal` and not of `SYSTEM_FIX \ Internal` was checked separately with `CEX = cmd.Restart -> handled.Init -> STOP` (`SYSTEM_BAD \ Internal [T= CEX` holds, the same for `SYSTEM_FIX` fails).

ProB 1.16.1, all 8 assertions in 2.3 s; the output is in `prob_results.txt` (7 hold, the one expected to fail fails).
