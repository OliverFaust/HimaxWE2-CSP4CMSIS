# Neuropathway: Formal Model (CSP-M)

This directory contains the CSPm formal specification for the neuropathway vision pipeline described in the *Neuropathways* chapter of the book: the three-stage `Camera` → `Inference` → `Console` network that processes camera frames through NPU-based person detection. It provides a mathematical abstraction of the pipeline's communication structure, isolating the CSP-level synchronisation guarantees from the low-level FreeRTOS task scheduling, hardware interrupt handling, and TensorFlow Lite Micro / Ethos-U55 driver details covered in the book. The model can be checked with FDR or [ProB](https://prob.hhu.de/) (see the book's discussion of model checkers).

## Model Overview

The model specifies four communicating processes, plus an environment process representing the hardware interrupt source:

1. **`ENV`:** Represents the hardware frame-ready interrupt, repeatedly offering the trigger event on `g_trigger_chan`.
2. **`Camera(c)`:** Waits for a trigger, then outputs the current frame index `c` on `frame_chan` before recursing with an incremented, wrapped index. The index is bounded to `{0, 1}` (via `MAX_INDEX = 2`) for tractable, exhaustive model checking; the real implementation uses an unbounded `uint32_t` frame counter.
3. **`Inference`:** Reads a frame index from `frame_chan` and produces a prediction, modelled as an *internal* choice (`|~|`) between the two outcomes `person` and `no_person`. This is a deliberate modelling decision rather than a convenient shortcut: the real prediction depends on image content the model has no visibility into, so from CSP's perspective it is exactly the kind of arbitrary, environment-independent decision internal choice exists to describe.
4. **`Console`:** Reads a `(frame index, prediction)` pair from `result_chan` and produces an observable `print_` event, accepting either prediction outcome unconditionally, since `Inference`'s choice is internal and therefore unpredictable from `Console`'s point of view.

`NEUROPATHWAY` composes `Camera`, `Inference`, and `Console` into a linear pipeline: `Camera` and `Inference` synchronise on `frame_chan`, and `Inference` and `Console` synchronise on `result_chan`. `SYSTEM` places `NEUROPATHWAY` in parallel with `ENV`, synchronised on `g_trigger_chan`, giving the complete, closed system.

Two assertions close the model: `deadlock free[F]`, checking that the system can never reach a state with no available events, and `divergence free`, checking that it never loops internally without ever offering an observable event. Together these give a machine-checkable version of the informal deadlock-freedom argument made in the book's prose.

## CSP-M Specification

```csp
-- Neuropathway
MAX_INDEX = 2

datatype prediction_t = person | no_person

channel g_trigger_chan
channel frame_chan : Int
channel result_chan : Int.prediction_t
channel print_

ENV = g_trigger_chan -> ENV

Camera(c) =
    g_trigger_chan -> frame_chan!c -> Camera((c+1) % MAX_INDEX)

Inference =
    frame_chan?f ->
        (
            (result_chan!f!person -> Inference)
        |~|
            (result_chan!f!no_person -> Inference)
        )

Console =
    result_chan?f?p -> print_ -> Console

NEUROPATHWAY =
    Camera(0)
        [| {| frame_chan |} |]
    (Inference [| {| result_chan |} |] Console)

SYSTEM =
    ENV [| {| g_trigger_chan |} |] NEUROPATHWAY

-- Sanity checks:
assert SYSTEM :[deadlock free[F]]
assert SYSTEM :[divergence free]
```
