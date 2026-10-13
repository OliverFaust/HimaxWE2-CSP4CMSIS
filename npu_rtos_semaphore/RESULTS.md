# Neuropathway (`csp4cmsis_allon_sensor_tflm`): Inference blocks during `Invoke()`, CSP4CMSIS 3.0.1

Board: Grove Vision AI V2 (Himax WE2, Cortex-M55 at 400 MHz, Ethos-U55), IMX219 camera, nobody in
view. GNU Arm 13.2.Rel1, `-O2`; Debug (`DEBUG=1`: `-g -DDEBUG`) and Release (`DEBUG=0`: `-DNDEBUG`).
Flashed over xmodem; each capture starts at the bootloader banner (opening the port resets the WE2).
Date: 2026-10-13.

- **Before:** `main` at `0cd3129`: CSP4CMSIS 3.0.0; the Ethos-U driver's own weak semaphores
  (`__WFE()` busy-wait, `malloc()`); NPU interrupt at priority 0.
- **After:** branch `npu-rtos-semaphore`: CSP4CMSIS 3.0.1; `ethosu_rtos_semaphore.c` (CMSIS-RTOS2
  semaphores, static control blocks, `osWaitForever`); NPU interrupt at priority 5 (`cvapp.cpp`).

## Changes

| File | Change |
|---|---|
| `app/.../csp4cmsis_allon_sensor_tflm/ethosu_rtos_semaphore.c` | new: `ethosu_semaphore_create/destroy/take/give` for the driver of `tflmtag2209_u55tag2205`. Pool of 2 static `StaticSemaphore_t` (the driver creates one global semaphore and one per driver instance; the app has one instance). Both binary: max 1, initial 0 (the bare-metal version sets its count to 1, not +1; a give while set is not an error). Take waits for ever; give is `osSemaphoreRelease()` (thread or interrupt). Pool exhausted or `osSemaphoreNew()` failed: `csp4cmsis_fatal_error()`. The driver's `ethosu_mutex_*` stay bare-metal no-ops (only Inference uses the NPU). Picked up by the app's source wildcard; no makefile change. |
| `app/.../csp4cmsis_allon_sensor_tflm/cvapp.cpp` | `_arm_npu_irq_init()`: `NVIC_SetPriority(U55_IRQn, CSP4CMSIS_MAX_SYSCALL_INTERRUPT_PRIORITY)` before `NVIC_EnableIRQ()`, as in `csp4cmsis_kws_iic/cvapp_kws.cpp`. |
| `library/csp4cmsis/` | v3.0.1 (tag v3.0.1, commit `8576491`), unmodified: `src/alternative.cpp`, `inc/csp/csp_version.h`, `VERSION`. This copy is shared by all 16 `csp4cmsis_*` apps. |
| `app/.../csp4cmsis_allon_sensor_tflm/README.md` | architecture points 1 (NPU interrupt priority) and 3 (Inference blocks), frame rate, heap statement, stack table and sample output, file list, library version. |

The book-facing files (`csp4cmsis_spn.cpp`, `camera_process.cpp`, `inference_process.cpp`,
`reporter_process.cpp`, `common_types.h`) are unchanged. The formal model is unchanged (see below).

Linked image (`out_after/*.map`, disassembly): `ethosu_semaphore_create/take/give` come from
`ethosu_rtos_semaphore.o` and call `osSemaphoreNew/Acquire/Release`; the driver's weak versions are
discarded. `ethosu_semaphore_destroy` is not linked (the app never calls `ethosu_deinit()`).
CSP4CMSIS's `alternative.o` (the only code that changes in 3.0.1) is not linked into this app: it
uses no `Alternative`.

## Measurements

Two kinds of build, from the same sources:

- **Plain** builds (exactly what is committed): frame rate, frame gaps, stack report, console log.
- **Measurement** builds: the plain sources plus scratch instrumentation, identical before and after
  (`results/measure_instrumentation.c.txt`, applied by `results/measure_apply.sh.txt`; not committed
  to the app). It enables `DWT->CYCCNT`; times `int_ptr->Invoke()` in `cv_run()`; adds
  `traceTASK_SWITCHED_IN/OUT` hooks that accumulate the cycles spent in the FreeRTOS idle task;
  counts every take/give per Ethos-U semaphore (after only); wraps `malloc`, `_malloc_r`, `free`, ...
  and `_sbrk` with `-Wl,--wrap` (caller, size, tick); reads `vPortGetHeapStats()` and `mallinfo()`.
  A thread prints one `@@MEAS` block at 70 s; the window is 10 s .. 70 s after boot (60 000 ticks).
  `DWT->CYCCNT` keeps counting while the core sleeps (tickless idle, `__WFE()`): over the window it
  advanced 23 999 834 k cycles against 24 000 000 k for 60 s at 400 MHz.

| | Before (3.0.0, `__WFE()` spin) | After (3.0.1, RTOS semaphore) |
|---|---|---|
| Frames in the 60 s after frame 0 (plain, Release and Debug) | 1164 (19.40 fps) | 1164 (19.40 fps) |
| Mean frame period over 1440 frames (74 s) | 51.58 ms (19.39 fps) | 51.58 ms (19.39 fps) |
| Frames within 40 s of boot (the earlier "764 in 40 s" count) | 762 | 762 |
| Frame-index gaps, `FATAL`, stalls | none | none |
| `Invoke()`, 60 s window, n = 1164: min / mean / max cycles | Release 640 885 / 641 013 / 698 762; Debug 640 907 / 641 037 / 701 083 | Release 641 998 / 642 097 / 658 758; Debug 642 021 / 642 119 / 659 118 |
| `Invoke()` mean in µs (400 MHz) | 1602.5 | 1605.2 |
| `Invoke()`, whole run (1345, first excluded): max cycles; first call | 710 932 / 711 061; 641 000 / 641 024 | 826 416 / 826 582; 642 136 / 642 157 |
| CPU idle share (idle task / wall time, 60 s) | 95.3 % (22 886 M of 24 000 M cycles), both builds | 97.4 % (23 391 M cycles), both builds |
| Takes on the inference-finished semaphore (driver instance) | not counted (bare-metal spin) | 1346 for 1346 `Invoke()` calls (window: 1163 takes, 1164 gives, 1164 `Invoke()`: one job straddles the window edge) |
| Global ("driver released") semaphore | — | 0 takes, 1346 gives (1345 found it already set: `osErrorResource`, ignored) |
| Stack report group at 62.9 s (plain): Camera / Inference / Reporter / CSP_Main, bytes used | Release 768 / 488 / 448 / 464; Debug 768 / 488 / 472 / 464 | Release and Debug 768 / 560 / 472 / 464 |
| FreeRTOS heap (`heap_4`, 1 KB) | 0 allocations | 0 allocations |
| C library heap (16 KB): allocations | 4: 1088 B libstdc++ emergency exception pool (`eh_alloc.cc`, before `main()`); 1 B + 1 B `ethosu_semaphore_create()`; 12 B `ethosu_dev_init()` | 2: 1088 B libstdc++ pool; 12 B `ethosu_dev_init()` |
| C library heap: in use (`mallinfo().uordblks`) | 1144 B | 1112 B |
| C library heap: `sbrk` extent (`mallinfo().arena`) | Release 2584 B, Debug 4856 B | Release 2312 B, Debug 4584 B |
| Torn console lines | none | none |

Notes:
- The idle share rises by 505 M cycles in 60 s, 434 k cycles (1.09 ms) per frame: the part of
  `Invoke()` in which the NPU runs and the CPU spun before. The rest of `Invoke()` (about 0.5 ms) is
  CPU work. The frame rate is set by the camera (51.6 ms per frame), not by the NPU, so it does not
  change.
- Blocking costs about 1 100 cycles (2.7 µs) per `Invoke()`: two context switches and the semaphore
  calls. The largest `Invoke()` of each run happens before the window (10 s) in both builds:
  826 k cycles after, 711 k before.
- Every allocation happens at start-up (tick 0 or 613 ms, when Inference initialises the model);
  none while frames run; nothing is freed. The `sbrk` extent is larger than what is in use because
  newlib's `malloc()` rounds the top of its arena up to a 4 KB boundary; it depends on where
  `__HeapBase` lands, not on the allocations. The earlier "1.25–1.5 of 16 KB"
  (`migration_2.0.1/BOARD.md`) came from another method; the figures here are `mallinfo()`.
- Inference's stack grows from 488 to 560 bytes: it now blocks in `osSemaphoreAcquire()` inside
  `Invoke()`. The Reporter's figure reached 448 or 472 bytes depending on the run, before and after.
- The `\r\r\n` line ends in the logs are verbatim: lines printed with `"\r\n"` get another `\r`
  from `xprintf()`'s newline conversion. Not a tear: every line is complete.
- Camera start-up failure (`IMX219 off by app fail`, I2C −60; README troubleshooting): once in
  12 captured boots today (before, measurement build, Release); the run was repeated.

## CSP4CMSIS's share of the image (linker map)

`results/map_share.py.txt` reads the GNU ld map. Counted: every input section kept in the link (the
"Linker script and memory map" part; discarded sections are listed elsewhere in the map), by output
section: code = `.text`, `.table`, `.ARM.exidx`, copy/zero tables (ITCM) and `.text_2` (SRAM);
rodata = `.rodata` (DTCM) and `.model` (SRAM); data = `.data`; bss = `.bss`, `.noinit`. The heap
(16 KB) and the main stack (36 KB) are reserved regions, not counted in bss. All objects are built with
`-ffunction-sections -fdata-sections` and linked with `--gc-sections`, so each function and object is
its own input section.

- **Library:** input sections from `libcsp4cmsis.a`. Linked: `alt_channel_sync.o`, `csp_wrapper.o`,
  `glue.o`.
- **Templates:** input sections from the app's own object files whose symbol demangles into namespace
  `csp::` (functions, vtables, typeinfo, guard variables; 71 sections, all in `camera_process.o` and
  `csp4cmsis_spn.o`). Not counted: template code inlined into app functions (not attributable), and
  the app's static objects of `csp::` types.
- **Merged strings:** the map lists `.str1.4` sections at their size before the linker merges equal
  strings. Recounted as the distinct strings in the objects: library 345 B (listed 346), templates
  199 B (listed 199). The listed figures are used below.

Release, after (identical before and in Debug for the library and the templates):

| | code | rodata | data | bss | image (code + rodata + data) |
|---|---|---|---|---|---|
| Library (`libcsp4cmsis.a`) | 1540 | 346 | 0 | 4 | 1886 |
| Templates in app objects (`csp::`) | 1832 | 471 (272 vtables, 199 strings) | 0 | 0 | 2303 |
| Image total, Release before | 166 948 | 265 044 | 2972 | 660 668 | 434 964 |
| Image total, Release after | 167 044 | 265 152 | 2964 | 660 844 | 435 160 |
| Image total, Debug before | 167 972 | 266 876 | 2964 | 660 668 | 437 812 |
| Image total, Debug after | 168 068 | 266 984 | 2956 | 660 844 | 438 008 |

Shares (Release after): library 0.92 % and templates 1.10 % of the code; of the loaded image without
the model (435 160 − 251 568 = 183 592 B), library 1.03 %, templates 1.25 %, together 2.28 %; with the
model, 0.43 % and 0.53 %. RAM: the library's own variables are 4 bytes (`csp4cmsis_last_fatal_error`).

For comparison, the network's static objects, owned by the app (`.bss`, DTCM; from `nm -S`):
Camera 1992 B, Inference 1472 B, Reporter 1448 B (each with its stack: 1536, 1024 and 1024 B),
`frame_chan` 244 B, `report_chan` 244 B, `g_trigger_chan` 212 B; MainApp's stack 1024 B and control
block 376 B.

The change itself (after − before, Release): code +96 B, rodata +108 B, data −8 B, bss +176 B (the
two static semaphore control blocks, 2 × 84 B, and their two handles, 8 B).

## The other 15 apps on 3.0.1

The library copy is shared, so every `csp4cmsis_*` app now builds against 3.0.1
(`results/build_all16_v301.txt`, Debug): all 16 build, 0 errors, the same warning counts as on 3.0.0
(`migration_3.0.0/results/build_summary.txt`; Neuropathway 39, two fewer since the comments were
removed on `main`), none in the library. Four link `AltScheduler::select()`, each with one `CLZ`:
`alt_test`, `alt_test_max`, `comstime`, `kws_PCA9685_alt`. Board, against
`migration_3.0.0/results/board/v300_*.txt` (logs `results/v301_*.txt`):

| App | 3.0.1 | 3.0.0 |
|---|---|---|
| `alt_test` (25 s) | 20 000 verified, SUCCESS, both senders finish | same |
| `alt_test_max` (120 s) | 1 600 000 verified, SUCCESS (fair round-robin); max spread 17, drift ≤ 0.2 %; Receiver 1168 B | same; max spread 16, drift ≤ 0.4 %; Receiver 1168 B |
| `comstime` (25 s) | 22.7–23.3 µs/cycle (70 × 22.7, 28 × 22.8, 8 × 23.3) | 22.7–23.3 µs/cycle (67 / 31 / 8) |

Not run: `kws_PCA9685_alt` (needs the PCA9685 board). The other apps' READMEs still say 3.0.0.

## Formal model

`Formal model/Neuropathway.csp` is unchanged. Inference's computation between `frame_chan?f` and
`report_chan!result.f.p` has no events in the model, so whether `Invoke()` spins or blocks is not
observable there; the NPU semaphore is private to Inference and its interrupt, not a channel of the
network; timing is outside the model (readme: "What the model does not cover"). Re-checked with ProB
1.16.1 on the unchanged file: all 8 assertions hold, as in `prob_results.txt`.

## Console log for the book

`results/console_after_Release_book.txt`: the plain after build (Release), verbatim bytes from the
bootloader banner (the first byte after reset) to the end of the first stack report group: 90 lines,
the camera driver's start-up log, `Camera: started`, `Inference: started`, frames 0..55 (contiguous),
then Camera, Inference, Reporter and CSP_Main. Every line ends in CR LF; no line is torn. Full
captures: `results/{before,after}_{Release,Debug}_75s.txt`; measurement builds:
`results/measure_{before,after}_{Release,Debug}_85s.txt` (`@@MEAS` block near the end).
