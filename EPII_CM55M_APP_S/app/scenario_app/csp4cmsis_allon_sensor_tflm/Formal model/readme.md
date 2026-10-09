# Neuropathway: Formal Model (CSP-M)

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
