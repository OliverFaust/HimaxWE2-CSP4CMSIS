# CSP4CMSIS 2.0.1 -> 3.0.0: the 16 csp4cmsis_* apps

**Date:** 2026-10-07. **Board:** Grove Vision AI V2 (WE2) with the IMX219 camera and the on-board
microphone; no ADXL345, PCF8574 or PCA9685 (as for 2.0.1). **Toolchain:** Arm GNU 13.2.rel1. **Library:**
CSP4CMSIS v3.0.0 (commit `647a1cb`), unmodified. **Reference:** the 2.0.1 board logs
(`../migration_2.0.1/results/board/migrated_*.txt`, `pilot_*.txt`). Procedure as in
`../migration_2.0.1/BOARD.md` (ELF -> image -> xmodem; opening the port resets the WE2; capture from boot).

## Changes (branch csp4cmsis-3.0.0, from main `7646dfb`)

| Commit | Change |
|---|---|
| Library | `library/csp4cmsis/` = unmodified v3.0.0 `csp4cmsis/` (including its Himax `csp4cmsis.mk`, changed only in a comment) + `LICENSE` + `VERSION` |
| Code, 16 apps | `SleepFor(Milliseconds(n))` for every duration (was `SleepFor(n)` in ticks at 1 kHz; a plain number no longer compiles); `SleepFor(Ticks(1))` only in the one-tick poll-and-yield loops of the four KWS apps (`while (!flag) SleepFor(Ticks(1))`, the console poll); `SleepFor(Forever)` (was `osWaitForever`); `BufferedChannel<T, N, P>` (was `SamplingBufferedChannel`: `irq`, `lossy_policy_test`, the four KWS report channels); `ExecutionMode::TerminatingNetwork` named in `asymmetric_philosophers` (it used that default) |
| `APPL_DEFINES` | only `CSP4CMSIS_MAX_SYSCALL_INTERRUPT_PRIORITY=5` and `CSP4CMSIS_DEVICE_HEADER="WE2_device.h"`; `CSP4CMSIS_RTOS2_BACKEND_FREERTOS` and `CSP4CMSIS_STATIC_ALLOCATION` removed |
| READMEs | library version, the 3.0 names in text and snippets |

At 1 kHz every converted sleep has the same tick count as before.

**Detection with `OS_HAL := y`:** there is no `RTE_Components.h` in the SDK build; `FreeRTOS.h` is on the
include path and `rtx_os.h` is not, so CSP4CMSIS selects FreeRTOS, and static allocation is the default.
Built with and without the two removed defines, all 16 flash images (`objcopy -O binary`) are
byte-identical: the defines are redundant, so the backend define is not kept.

## Builds

All 16 build (`results/build_summary.txt`); the warnings are the same as in the 2.0.1 build, text and
count (SDK code and the apps' existing `.c` files; none from the changed code).

## Board results (3.0.0 vs 2.0.1)

| App | Result | Class |
|---|---|---|
| `sieve` | output identical (primes 2…47) | — |
| `alt_test` | 20 000 verified, SUCCESS, both senders finish; Snd 736/800 B identical, Receiver 912 B (2.0.1: 952 B) of 4 KB, MainApp 888 B (896 B) | — |
| `alt_test_max` | 1 600 000 verified, SUCCESS; max spread 16 (17), drift ≤ 0.4 % (0.4 %); Receiver 1168 B (1176 B) | — |
| `comstime` | 22.7–23.3 µs/cycle, same distribution | — |
| `chain_test`, `dining_philosophers`, `lossy_policy_test` | output identical (lossy: KeepNewest 999 990…999 999, KeepOldest 0…9, PASS; dining: the same deadlock after 10 meals) | — |
| `matrix_multiplication` | results and line order identical; PE02 856 B of 4 KB (824 B; 856 B was the PE maximum in the 2.0.1 measurement build) | — |
| `asymmetric_philosophers` | output identical (628 meals in 25 s) | — |
| `irq` | count 1…23 in 25 s, no gaps (identical) | — |
| `shake_detection` | start-up identical (no ADXL345) | — |
| `kws_pdm_record`, `kws_PCA9685_alt` | output identical (on-board microphone, quiet room) | — |
| `kws_iic` | identical except Invoke time ±2 ms per 20 calls | (b) timing |
| `kws_PCA9685` | audio path identical (rtf, MFCC, heap, semaphore counts); four extra keyword detections ("up", "_unknown_") of room sound and a different console interleaving | (b) ambient sound, as noted for 2.0.1 |
| `allon_sensor_tflm` (neurochannel, IMX219) | 764 frames in 40 s (≈ 19.6 fps), no stall, no FATAL; stacks Camera 744/1536, Console 360, CSP_Main 560 identical, Inference peak 488 B once (472 B) of 1 KB; scores −25…−1 (2.0.1: −95…−8; nobody in view, scene-dependent) | — |

- **Heap:** the KWS apps report the FreeRTOS heap themselves: `free_heap=824 min_ever_free=824`,
  identical to 2.0.1 (the Ethos-U semaphore; CSP4CMSIS allocates nothing). For the other apps the images
  are identical with and without `CSP4CMSIS_STATIC_ALLOCATION` (above), so their 0 heap allocations
  measured for 2.0.1 still hold.
- **Not tested** (as for 2.0.1): the ADXL345, PCF8574 and PCA9685 devices; a person in view.

Logs: `results/board/v300_<app>.txt` (one capture per app from boot: 25 s; `alt_test_max` 120 s,
the KWS apps 30 s, the neurochannel 40 s).

## Neurochannel: one console owner (branch `reporter`, 2026-10-07)

`allon_sensor_tflm` printed each result twice (Inference's `dbg_printf` and the Console process), plus
`invoke pass` / `person_score` from `cv_run()` and Camera's per-frame `retrigger` line, and lines from
different processes tore mid-string (`xprintf()` has no locking). Now the **Reporter** is the only process
that prints while the network runs: Camera and Inference send fixed-size `report_t` messages (kind, source,
code, index, `value[3]`; trivially copyable) over one rendezvous `Channel<report_t>` with two writers.
`cv_init()`/`cv_run()` return codes instead of printing (two `cv_init()` failure paths returned 0, i.e.
success, before). Inference initialises the model after its first frame, so the camera driver's own start-up
log ends before anything else prints. MainApp ends after `Run()`; the Reporter prints the stack report.

Board (Grove Vision AI V2, IMX219, nobody in view; 3 runs of 40 s from boot, identical):

| | 3.0.0 before (`v300_allon_sensor_tflm.txt`) | Reporter |
|---|---|---|
| Frames in 40 s | 764 | 764, 764, 764 (frames 0..763, no gaps): fps unchanged |
| Lines per frame | 5 (`invoke pass`, `person_score`, the result twice, `retrigger`), interleaved | 1: `Frame n: prediction = s` |
| Lines not from the Reporter after `Camera: started` | many | 0 |
| Stacks Camera / Inference / Reporter (Console) | 744 / 472 / (360) of 1536 / 1024 / 1024 B | 760 / 480 / 408 of 1536 / 1024 / 1024 B |
| Build warnings (app) | 25 | 23 (two unused variables in `cvapp.cpp` gone) |

Logs: `results/board/reporter_allon_sensor_tflm_run{1,2,3}.txt`.

## Neurochannel: stack report by MainApp (branch `mainapp-stack-monitor`, 2026-10-09)

Review change: the Reporter's own stack report depended on report traffic (no reports, no stack report --
exactly when a process stalls) and delayed the writers while it printed four lines. Now `MainApp_Task` keeps
the network (`auto network = InParallel(...)`), runs it as a StaticNetwork and stays alive: every 3000 ms it
sends one `ReportKind::Stack` report per process (`network.forEachProcess`) and one for itself
(`osThreadGetStackSpace()`), over its own writer end of `report_chan` (now three writers). MainApp never
prints; the "network started" line is dropped (as a report it could reach the Reporter while the camera
driver is still printing its start-up log). The Reporter only receives and prints. A plain CMSIS-RTOS2
thread may use a rendezvous in 3.0.0: it blocks on thread flag 0 of the calling thread (`osThreadGetId()`),
and MainApp uses no thread flags otherwise. MainApp stays above the network (`osPriorityLow3`), so a busy
network process does not hold the report up (time slicing is on, so the Reporter, at network priority, runs
even next to a spinning process).

Board (Grove Vision AI V2, IMX219; 40 s from boot):

| | Reporter's stack report (before) | MainApp's stack report |
|---|---|---|
| Frames in 40 s | 764 | 764, 764, 764 |
| Lines per frame / other lines after `Camera: started` | 1 / 0 | 1 / 0 |
| Stack reports in 40 s | 12 | 13 (every 3 s from 3.5 s after start) |
| Stacks Camera / Inference / Reporter / CSP_Main | 760 / 480 / 408 of 1024 / -- (MainApp ended) | 760 / 480 / 384–432 of 1024 / 464 of 1024 B (MainApp stack right-sized from 2048 to 1024 B) |
| Stall test (scratch build: Inference stops after frame 100) | -- | frames 0..100, then the stack report continues every 3 s (12 more groups), nothing else |

The first stack report came 56 frames (≈ 2.9 s) after `Camera: started`: that is the margin between the
camera driver's start-up log (printed by the driver, outside the Reporter) and MainApp's first report.
Formal model updated (MainApp as the third writer; stall case; the previous design as a positive control),
ProB 1.16.1: 8 of 8 assertions hold, 3 of 3 controls fail as expected (`Formal model/`).
Logs: `results/board/mainapp_stack_allon_sensor_tflm_run{1,2,3}.txt`, `..._stall.txt`.
