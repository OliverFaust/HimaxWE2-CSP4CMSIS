# Neuropathway: Formal Model (CSP-M)

This directory contains the CSPm formal specification for the neuropathway vision pipeline described in the *Neuropathways* chapter of the book: the three-stage `Camera` → `Inference` → `Reporter` network that processes camera frames through NPU-based person detection. It provides a mathematical abstraction of the pipeline's communication structure, isolating the CSP-level synchronisation guarantees from the low-level FreeRTOS task scheduling, hardware interrupt handling, and TensorFlow Lite Micro / Ethos-U55 driver details covered in the book. The model is checked with [ProB](https://prob.hhu.de/) 1.16.1 (`probcli Neuropathway.csp -assertions`); FDR can check it as well.

## Model Overview

The model mirrors the application (`csp4cmsis_spn.cpp`): the console has one owner, the **Reporter**. Camera and Inference never print; they send reports over **one rendezvous channel with two writers**, `report_chan`. In CSP-M the two writers simply do not synchronise with each other on `report_chan` (it is not in the interface between them), while each synchronises with the Reporter.

1. **`ENV`:** the hardware frame-ready interrupt, repeatedly offering the trigger event on `g_trigger_chan`. (In the application the trigger goes through a one-slot buffered channel; since Camera re-arms the capture only after reading a trigger, at most one is pending, and the slot behaves like a rendezvous with the interrupt.)
2. **`Camera`:** the camera driver prints its start-up log (`camera_log`), then Camera reports `started.camera` -- once -- and enters its loop: wait for a trigger, send the frame index on `frame_chan`. Indices are bounded to `{0, 1, 2}` (`MAX_INDEX = 3`) for exhaustive checking; the application uses an unbounded counter.
3. **`Inference`:** initialises the model only after its first frame (i.e. after Camera has started), reports `started.inference`, then reports one `result.f.p` per frame. The prediction `p` is an *internal* choice (`|~|`) between `person` and `no_person`: it depends on image content the model cannot see.
4. **`Reporter`:** reads any report from `report_chan`, prints it (`line.r`), and may then print the stack report (`stack_report`, an internal choice: in the application a timer decides).
5. **`SYSTEM`:** MainApp prints its line (`main_print`) and ends before the network runs (it runs at a higher priority), then the network runs with `ENV`. MainApp writes no reports.

`CONSOLE` is `SYSTEM` with the internal channels (`g_trigger_chan`, `frame_chan`, `report_chan`) hidden: what a user sees on the UART.

## What is checked

| Assertion | Meaning | Result |
|---|---|---|
| `SYSTEM :[deadlock free [F]]` | the network never stops | holds |
| `SYSTEM :[divergence free]` | it never loops internally without an observable event | holds |
| `SPEC [T= CONSOLE` | every console output is allowed by `SPEC`: MainApp's line, the camera driver's log, `started.camera`, `started.inference`, then exactly one result line per frame, in frame order, with stack reports only after Reporter lines | holds |
| `SPEC [F= CONSOLE`, `SPEC [FD= CONSOLE` | in addition, the console never refuses what `SPEC` must offer: the next result line always comes (and no divergence) | holds |

The old model (`Camera` → `Inference` → `Console` with `result_chan`) checked deadlock and divergence freedom only; the refinements against `SPEC` are new. They state the console-ownership property: after `started.camera`, only the Reporter prints, one line per frame.

## Positive controls (`Neuropathway_controls.csp`)

Each control is a plausible wrong design that must **fail** its check, showing that the checks above can detect such faults:

| Control | Design | Check | Result |
|---|---|---|---|
| 1 | one channel per writer, and a Reporter that reads them in a fixed order (Camera, then Inference) every round | `SYSTEM1 :[deadlock free [F]]` | **fails** (as it should): after `line.started.inference` the Reporter waits for a second Camera report that never comes, while Inference waits to report -- deadlock |
| 2 | the real network, but Inference also prints directly (`direct_print`), like the old `dbg_printf` | `SPEC [T= CONSOLE2` | **fails** (as it should): `direct_print` appears among the Reporter's lines |

ProB's output for both files is in `prob_results.txt` (ProB 1.16.1; 5 of 5 assertions hold for the model, 2 of 2 fail for the controls). The `*.csp.pl` files are ProB's parse caches.

## CSP-M Specification

See `Neuropathway.csp`; the core of it:

```csp
ENV = g_trigger_chan -> ENV

Camera = camera_log -> report_chan!started.camera -> CameraLoop(0)
CameraLoop(c) = g_trigger_chan -> frame_chan!c -> CameraLoop((c + 1) % MAX_INDEX)

Inference = frame_chan?f -> report_chan!started.inference -> Infer(f)
Infer(f)  = (report_chan!result.f.person -> Next) |~| (report_chan!result.f.no_person -> Next)
Next      = frame_chan?f -> Infer(f)

Reporter = report_chan?r -> line!r -> ((stack_report -> Reporter) |~| Reporter)

NETWORK = (Camera [| {| frame_chan |} |] Inference) [| {| report_chan |} |] Reporter
SYSTEM  = main_print -> (ENV [| {| g_trigger_chan |} |] NETWORK)
CONSOLE = SYSTEM \ {| g_trigger_chan, frame_chan, report_chan |}

STK(P) = (stack_report -> P) |~| P
SPEC = main_print -> camera_log -> line!started.camera ->
       STK(line!started.inference -> STK(RESULTS(0)))
RESULTS(f) = |~| p : prediction_t @ line!result.f.p -> STK(RESULTS((f + 1) % MAX_INDEX))

assert SYSTEM :[deadlock free [F]]
assert SYSTEM :[divergence free]
assert SPEC [T= CONSOLE
assert SPEC [F= CONSOLE
assert SPEC [FD= CONSOLE
```

(`print` is a CSP-M keyword, hence the channel name `line`.)
