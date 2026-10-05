# CSP4CMSIS 2.0.1 migration of the csp4cmsis_* apps — Phase A (analysis, baseline, plan)

**Date:** 2026-10-04. **Repository:** HimaxWE2-CSP4CMSIS, `main` = `77124fa` (clean, up to date with
origin; default branch `main`), work branch `csp4cmsis-2.0.1`. **Scope:** the 18 apps
`EPII_CM55M_APP_S/app/scenario_app/csp4cmsis_*`. **Toolchain:** Arm GNU Toolchain 13.2.rel1 (the
system gcc 14.2 fails in the SDK's `retarget_newlib.c`). **Target library:** CSP4CMSIS v2.0.1 (tag
`v2.0.1`, `6c23fec`). Nothing outside `migration_2.0.1/` was changed; all builds ran on copies.

Logs: `results/baseline_build_summary.txt` (today's state), `results/compile_check_2.0.1_*.txt`
(the apps compiled against 2.0.1, see §3), `results/inventory_scan.txt` (construct counts per app).

---

## 1. RTOS layer

**FreeRTOS:** the apps select `OS_SEL := freertos_10_5_1` (FreeRTOS 10.5.1), `TRUSTZONE := y`,
`TRUSTZONE_TYPE := security`, `TRUSTZONE_FW_TYPE := 1`, which `os/os.mk` maps to the **secure-only**
build `os/freertos_10_5_1/NTZ` with the port `portable/GCC/ARM_CM55_NTZ/non_secure`
(`configRUN_FREERTOS_SECURE_ONLY 1`, `configENABLE_TRUSTZONE 0`, FPU on, MVE off, MPU off).

**CMSIS-RTOS2 is already in the SDK**, three times:

| Option | What | Status |
|---|---|---|
| `OS_HAL := y` with `OS_SEL := freertos_10_5_1` | `os/freertos_10_5_1/OS_HAL/`: Arm's CMSIS-FreeRTOS adapter (`cmsis_os2.c`, "Copyright (c) 2013-2022 Arm Limited", Apache-2.0), `freertos_evr.c`, `os_systick.c`, already adapted to WE2 (`#include "WE2_device.h"`). Built into `liboshal.a` | **all 18 apps set `OS_HAL := n` today**; with `y`, 10 of 18 apps compile and link against 2.0.1 unchanged (§3) |
| `OS_SEL := rtos2_freertos` | `os/rtos2_freertos/10.5.1/`: Arm's CMSIS-FreeRTOS package (own FreeRTOS 10.5.1 copy, same `cmsis_os2.c` apart from the `WE2_device.h` include and line endings, `Config/ARMCM*/FreeRTOSConfig.h` templates, `License/license.txt`) | no SDK app uses it |
| `OS_SEL := rtos2_rtx` | `os/rtos2_rtx/`: Keil RTX5 kernel 5.5.4, API 2.1.3 | no SDK app uses it |

**Recommendation: `OS_HAL := y`** (the first row): the apps keep their FreeRTOS, port and
`FreeRTOSConfig.h`; the adapter is a library next to it; native FreeRTOS calls in app code
(Ethos-U semaphore override, `uxTaskGetStackHighWaterMark` reports) keep working. Nothing has to be
added or licensed: the adapter is already in the SDK (Apache-2.0).

**The M55 masked-interrupt defect is present in this copy** (`OS_HAL/Source/cmsis_os2.c`, l. 55–67):
`IS_IRQ_MASKED()` checks PRIMASK **and** BASEPRI only for `__ARM_ARCH_7M__`, `7EM` and `8M_MAIN`; the
Cortex-M55 is Armv8.1-M (`__ARM_ARCH_8_1M_MAIN__`), so it falls through to the PRIMASK-only check.
Effect: application code that calls an RTOS2 function while BASEPRI is raised gets the task-level
path, whose `taskEXIT_CRITICAL()` clears BASEPRI and ends the caller's masked section. CSP4CMSIS itself
never calls the RTOS inside its critical sections (unaffected). None of the 18 apps raises BASEPRI in
its own code (`taskENTER_CRITICAL` is not used; `taskDISABLE_INTERRUPTS` only in `configASSERT`).
Keep the SDK file unmodified and document the rule in the README.

**FreeRTOSConfig.h:** per app, in the app folder; three variants (md5 groups):
A = 13 apps (heap 64 KB), B = `kws_iic`/`kws_PCA9685`/`kws_PCA9685_alt` (heap 300 KB),
C = `allon_sensor_tflm` (heap 160 KB); `AI_testbench` has **none** (it never built, §4).
Against Arm's adapter template (`Config/ARMCM/FreeRTOSConfig.h`) they already have everything the
adapter needs: `configMAX_PRIORITIES 56`, all `INCLUDE_*` used by `cmsis_os2.c`, timers, mutexes,
recursive mutexes, counting semaphores, task notifications, trace facility, static and dynamic
allocation, `vPortSVCHandler`→`SVC_Handler`, `xPortPendSVHandler`→`PendSV_Handler`;
`configUSE_PORT_OPTIMISED_TASK_SELECTION` is undefined (= 0, as the adapter requires).
Changes needed:
- **remove the two SysTick mappings** `#define xPortSysTickHandler SysTick_Handler` and
  `#define SysTick_Handler xPortSysTickHandler`: the adapter defines `SysTick_Handler` itself (which
  calls `xPortSysTickHandler()` once the scheduler runs). Done in the compile check; it links.
- **start via CMSIS-RTOS2:** every app's `app_main()` (`csp4cmsis_<app>.c`) creates its launcher task
  and calls `vTaskStartScheduler()`; replace with `osKernelInitialize()` before the first thread is
  created and `osKernelStart()` at the end.
- `configASSERT` disables interrupts and spins silently: replace with a printing one (as in the book
  examples) — recommended, not required.
- Interrupt priorities: `configPRIO_BITS 3` (`__NVIC_PRIO_BITS 3U`), `configLIBRARY_MAX_SYSCALL_
  INTERRUPT_PRIORITY 5` → **`CSP4CMSIS_MAX_SYSCALL_INTERRUPT_PRIORITY=5`** (BASEPRI 0xA0). Any ISR that
  calls CSP4CMSIS or FreeRTOS must be at priority 5..7. The SDK's `SystemInit` only disables the
  interrupts (`device/system_WE2_ARMCM55.c`); the drivers are prebuilt (`libdriver.a`), and **no
  csp4cmsis app sets a priority** for its interrupts (timer 1, I2C master 0, sensor data path/XDMA,
  NPU) — the NVIC reset value is 0, i.e. *above* the threshold. Whether a prebuilt driver sets one is
  not visible without a debugger: to be read on the board (§5, §6).
- Unchanged and noted: `configTIMER_TASK_PRIORITY 2` (irrelevant: 2.0.1 creates no RTOS timers);
  `configUSE_NEWLIB_REENTRANT 0` with `printf` from several threads (output can interleave, as in the
  book examples); `configCHECK_FOR_STACK_OVERFLOW 0`.

## 2. Library integration

The v2.0.1 tag's `csp4cmsis/csp4cmsis.mk` **is** the Himax SDK fragment (same structure as today's,
`CSP4CMSIS_DIR = $(LIBRARIES_ROOT)/csp4cmsis`; the only difference: `inc/` on the include path, not
`inc/csp`, which shadowed `<time.h>`). It must sit at `library/csp4cmsis/csp4cmsis.mk`.

| | (a) git submodule of CSP4CMSIS at v2.0.1 | (b) unmodified copy of `csp4cmsis/` + `LICENSE` + `VERSION` |
|---|---|---|
| Byte-identical to the tag | yes (the whole repository) | yes (the library folder; `diff -r` against `git archive v2.0.1 csp4cmsis` shows only `LICENSE`, `VERSION`) |
| Where the `.mk` lands | `library/<sub>/csp4cmsis/csp4cmsis.mk` — needs a Himax-side wrapper `library/csp4cmsis/csp4cmsis.mk` that sets `override CSP4CMSIS_DIR` and includes it | `library/csp4cmsis/csp4cmsis.mk` directly, no wrapper |
| Clone / download | needs `--recurse-submodules`; GitHub ZIP downloads and `git archive` **omit submodules** (the library would then silently drop out) | works with any clone or download |
| Size | the whole CSP4CMSIS repository (tests, docs, pack sources) | 28 library files |
| Updating | bump the submodule pointer | replace the folder, update `VERSION` |
| Precedent | — | the five book repositories (`lib/csp4cmsis/` + `VERSION` + `LICENSE`) |

**Recommendation: (b).**

**Fail loudly:** `library/library.mk` includes each `LIB_SEL` entry through `$(wildcard ...)`, so a
missing `library/csp4cmsis/csp4cmsis.mk` silently removes the library (this is what broke the old
local clone: `fatal error: csp/csp4cmsis.h` only at compile time, no hint why). Proposed: in
`library/library.mk`, after `LIB_INCLUDES` is computed,
`$(if $(and $(filter csp4cmsis,$(LIB_SEL)),$(if $(wildcard $(LIBRARIES_ROOT)/csp4cmsis/csp4cmsis.mk),,1)),$(error CSP4CMSIS selected (LIB_SEL) but library/csp4cmsis/csp4cmsis.mk is missing))`
— limited to csp4cmsis, so other SDK apps are unaffected. (Alternative: the same check in each of the
18 app `.mk` files.)

**`library/old_csp4cmsis/`** (pre-1.0, 2026-07-29, tree `890d73d`): no app selects it → **remove**
(confusing next to the real library; it stays in git history).

**`prebuilt_libs/gnu/libcsp4cmsis.a`** (pre-1.0, FreeRTOS event groups): only used with
`CSP4CMSIS_LIB_FORCE_PREBUILT=y`, and **every build overwrites it** (the `.mk`'s rule copies the fresh
archive into `prebuilt_libs/`; the 2.0.1 fragment does the same). Measured: one build round dirties 8
tracked archives (`libcsp4cmsis.a`, `libcommon.a`, `lib_cmsis_nn*.a`, `lib_cmsis_dsp.a`, `libfatfs.a`,
`libtflmtag2209…cmsisnn_gnu.a`, `libtrustzone_cfg.a`) — vendor SDK behaviour. Proposed: **untrack
`libcsp4cmsis.a` and add it to `.gitignore`** (a prebuilt copy of a library whose sources are in the
tree only goes stale); leave the vendor archives alone (decision D3).

## 3. Per-app inventory

Common to all 18: the SDK `app_main()` → `RunProcessingChainTest()` → a launcher task (`xTaskCreate`,
heap) that builds a static network and calls `Run(..., ExecutionMode::StaticNetwork)` (two use the
terminating `Run()`); processes are `CSProcessStatic<N>` (N in words) except in `AI_testbench`;
`vTaskDelay`/`vTaskDelete` in app code; no app uses task notifications, event groups or
`taskENTER_CRITICAL` itself (`xTaskNotifyGive` appears only in a comment). "2.0.1 compile" = the
compile check (2.0.1 library, `OS_HAL := y`, the four defines, SysTick mappings removed, **no
source changes**).

| App | Purpose | Processes (stack words) | Channels (type, element) | ALT | Interrupts → channel | Launcher (stack words, prio) | Build today (text/data/bss) | 2.0.1 compile | Peripherals |
|---|---|---|---|---|---|---|---|---|---|
| `alt_test` | resident-guard ALT, two senders | Sender (512) ×2, Receiver (1024) | 2 × `Channel<Message>` (8 B) | 1 ALT reader, 2 input guards, `fairSelect` | — | 4096, idle+3 | ok, 109 472/2136/90 240 | **ok** | none |
| `alt_test_max` | ALT stress, 16 senders | Sender (512) ×16, Receiver (2048) | 16 × `Channel<Message>` | 1 ALT reader, 16 guards, `fairSelect` (`priSelect` commented) | — | 4096, idle+3 | ok, 158 560/2136/90 840 | **ok** | none |
| `alt_alt_test` | regression test for the 1.x ALT-vs-ALT hang | ControlSender (256), AltSender (512), Receiver (512) | 2 × `Channel<Message>` | **symmetric ALT** (AltSender: output guard + `RelTimeoutGuard`; Receiver: input guard + `RelTimeoutGuard`), `priSelect`; one ALTer per channel end | — | 2048, idle+3 | ok, 103 124/2136/87 156 | **ok** | none |
| `comstime` | Comstime benchmark | Prefix, Successor, Delta, Trigger (512), Consumer (1024) | 4 × `Channel<int>`, `Channel<bool>` | Consumer: 2 input guards, `fairSelect` | — | 2048, idle+3 | ok, 104 416/2144/95 436 | **ok** | none |
| `chain_test` | relay chain | Sender, Relay ×N, Checker (256) | `Channel<int>[N+1]` | — | — | 4096, idle+3 | ok, 101 748/2120/91 204 | **ok** | none |
| `sieve` | Sieve of Eratosthenes | Numbers, Filter ×N, Sink (256) | `Channel<int>[N+1]` | — | — | 4096, idle+3 | ok, 101 176/2144/91 220 | **ok** | none |
| `matrix_multiplication` | systolic array | PE ×12 (1024), Feeder, Sink (512) | `Channel<int>` h[3][4], v[4][3] | — | — | 4096, idle+3 | ok, 117 472/2144/153 156 | **ok** | none |
| `dining_philosophers` | deadlock demonstration | Fork ×5, Philosopher ×5 (256) | `Channel<int>` pick[5], put[5] | — | — | 8192, idle+3 | ok, 103 308/2120/95 924 | **ok** | none |
| `asymmetric_philosophers` | deadlock avoidance | Fork ×5, Philosopher/Asymmetric (256) | as above | — | — | 8192, idle+3; terminating `Run()` (blocks for ever, by design) | ok, 103 892/2144/96 024 | **ok** | none |
| `lossy_policy_test` | KeepNewest vs KeepOldest | Sender, Receiver (256) | `BufferedOne2OneChannel<Message, 10, KeepNewest>` and `…KeepOldest>` (buffered, 4 B) | — | — | 4096, idle+3 | ok, 99 160/2136/83 588 | **ok** | none |
| `irq` | timer ISR → process | TimerProcess, LogicProcess (256) | `Channel<uint32_t>` (rendezvous) | — | **timer 1** (`hx_drv_timer_hw_start`, periodic, period value 1000), `writer().putFromISR(count)` (result ignored); priority never set | 4096, idle+2 | ok, 102 064/2188/83 668 | **error**: `putFromISR` | none (internal timer) |
| `shake_detection` | ADXL345 over I2C, shake events | Adxl345Reader, ShakeLogic, Consumer (256) | `Channel<bool>` (I2C completion), `Channel<AccelData>`, `Channel<bool>` | — | **I2C master 0** completion callback, `writer().putFromISR(true)` (ignored); **lost-completion race** (two transfers per sample) | 4096, idle+3 | ok, 102 256/2132/85 252 | **error**: `putFromISR` | **ADXL345** on I2C 0 (0x53) |
| `kws_pdm_record` | keyword spotting (transformer) | Acquisition, Preprocessing (256), Inference (8192, idle+3), Reporter (256) | `Channel<AudioChunkMsg>` (pointer), `Channel<FeatureTensorMsg>` (pointer), `SamplingBufferedChannel<KwsReportMsg, 8, KeepNewest>` (~96 B, several writers) | — | NPU IRQ (`EPII_NVIC_SetVector`, `NVIC_EnableIRQ`, priority not set); PDM DMA | 8192, idle+3 | ok, 352 684/46 112/329 436 | **error**: `taskPriority()` returns `UBaseType_t` | **PDM microphone**; KWS model in flash (`--model model_zoo/kws_pdm_record/…tflite`) |
| `kws_iic` | KWS + PCF8574 actuation | Acquisition (2048, +4), Preprocessing (4096, +3), Inference (8192, +2), Filter, Fsm (512, +1), Pcf8574, Reporter (1024, +0) | `BufferedChannel<AudioChunkMsg,2>`, `BufferedChannel<FeatureTensorMsg,2>`, `Channel<KwsTokenMsg>` (16 B) ×3, `SamplingBufferedChannel<KwsReportMsg,8,KeepNewest>`, `Channel<bool>` (I2C completion) | — | I2C master 0 completion → `putFromISR` (**lost-completion race**); NPU IRQ → `ethosu_semaphore_give()` = `xSemaphoreGiveFromISR` + `portYIELD_FROM_ISR` (app's Ethos-U semaphore override, FreeRTOS binary semaphore) | 8192, idle+4 | ok, 358 476/46 112/678 456 | **error**: `putFromISR`, 7 × `taskPriority()` | mic, **PCF8574** on I2C 0, KWS model |
| `kws_PCA9685` | KWS + PCA9685 servo driver | as `kws_iic` with Pca9685 (two transfers per command) | as `kws_iic` | — | as `kws_iic` | 8192, idle+4 | ok, 359 560/46 104/678 464 | **error**: `putFromISR`, 7 × `taskPriority()` | mic, **PCA9685** on I2C 0, KWS model |
| `kws_PCA9685_alt` | as above + console commands | + ConsoleInput (512, +1) | + `Channel<KwsTokenMsg>` console | Pca9685: 2 input guards (voice, console), `fairSelect` | as `kws_iic` | 8192, idle+4 | ok, 361 864/46 112/681 016 | **error**: `putFromISR`, 8 × `taskPriority()` | mic, PCA9685, KWS model, **keyboard** (UART console) |
| `allon_sensor_tflm` ("neurochannel", book ch. 8) | person detection pipeline | Camera, Inference, Console (256) | `Channel<trigger_t>` (ISR), `Channel<frame_t>` (12 B), `Channel<result_t>` (8 B) | — | sensor data path / XDMA frame-ready callback → `writer().putFromISR(trigger)` (result checked, but not acted on); NPU IRQ (priority not set); **lost-completion stall**: a dropped trigger means no `sensordplib_retrigger_capture()` | static, 512, idle+3 (`xTaskCreateStatic`) | ok, 430 868/2992/822 420 | **error**: `putFromISR` | **camera** (CSI), SD card optional; person model compiled in |
| `AI_testbench` | AF detection testbench (SD card data, NPU) | SD, InferenceEngine (**plain `CSProcess`**, not static) | `BufferedOne2OneChannel<work_packet_t,16>`, `<result_packet_t,16>` | — | NPU IRQ | 8192, idle+3 | **fails** (no `FreeRTOSConfig.h`; never built since it was added on 2026-02-11) | **fails** (same) | **SD card** with test data |

Build today: 17 of 18 build with Arm GNU 13.2.rel1 (7–79 warnings, SDK code); `AI_testbench` does not.

**README errors noticed:** `alt_alt_test/README.md` is a copy of `alt_test_max`'s ("16-Sender ALT
Stress Test"); `shake_detection/README.md` describes an L3G4200D gyroscope over SPI on a
NUCLEO-F401RE, while the code reads an ADXL345 over I2C on the WE2.

## 4. Classification

**(A) mechanical** — compile unchanged on 2.0.1; need only the shared foundation (§6) plus the RTOS2
start, and optionally native calls → RTOS2/`SleepFor`:
`alt_test`, `alt_test_max`, `comstime`, `chain_test`, `sieve`, `matrix_multiplication`,
`dining_philosophers`, `asymmetric_philosophers`, `lossy_policy_test`. Board check for
`lossy_policy_test`: 2.0's KeepNewest overwrites the oldest element, KeepOldest drops the new one
(expected: Newest 999 990..999 999, Oldest 0..9), **provided** the sender's 2 × 1 000 000 writes finish
within the receiver's fixed `vTaskDelay(100 ms)` — not guaranteed; if the receiver drains mid-burst the
values differ. Compare with the baseline; if needed, replace the delay with a "done" rendezvous.

`kws_pdm_record` is mechanical apart from the priority type (D5).

**(B) needs a decision:**

| App | Issue in 2.0 | Options | Recommendation |
|---|---|---|---|
| `shake_detection`, `kws_iic`, `kws_PCA9685`, `kws_PCA9685_alt` | I2C completion via `putFromISR` on a rendezvous channel: no longer compiles, and has the lost-completion race (`docs/upstream/himax_i2c_completion.md`) | (1) `BufferedChannel<bool, 1>` (Block) + `isrWriter().putFromISR(true)`, trap a `false` (second completion before the first was read = driver bug); (2) `SamplingBufferedChannel<bool, 1, KeepNewest>` (never fails, but would hide such a bug) | **(1)**; reader side unchanged |
| `irq` | timer ISR `putFromISR` on a rendezvous channel (no longer compiles; ticks are dropped whenever TimerProcess is printing); timer IRQ priority never set | (1) `SamplingBufferedChannel<uint32_t, 1, KeepNewest>` — "latest count": a missed tick shows as a gap in the count; (2) `BufferedChannel<uint32_t, N>` Block — every tick, overflow counted | **(1)** (the count itself reveals missed ticks); plus `NVIC_SetPriority(TIMER1INT_IRQn, ≥5)` |
| `allon_sensor_tflm` (neurochannel) | frame-ready ISR `putFromISR` on a rendezvous channel; a dropped trigger stops the camera for good (no retrigger) | (1) `BufferedChannel<trigger_t, 1>` Block (one retrigger → one frame-ready, so at most one pending; trap `false`); (2) `SamplingBufferedChannel<trigger_t, 1, KeepNewest>` | **(1)**, same reasoning as the I2C apps; README/book text on `putFromISR()`; **last** in the order |
| `alt_alt_test` | written to show the 1.x ALT-vs-ALT failure ("expected (buggy) result: timeout"); 2.0 communicates | (1) keep as a demonstration that 2.0 communicates: rename messages to PASS on delivery, FAIL on timeout, fix its README (currently a copy of another app's); (2) remove | **(1)** |
| `AI_testbench` | never built (no `FreeRTOSConfig.h`); uses plain `CSProcess` (2.0.1: `CSProcessStatic<N>` required); needs an SD card with test data | (1) fix: add a `FreeRTOSConfig.h` (variant C, heap as for TFLM), port to `CSProcessStatic<N>`, test with the SD data; (2) remove from the repository; (3) leave unbuilt, out of scope | **(2) remove** unless it is needed for a publication (then (1), last) |
| all KWS apps (+ `kws_pdm_record`) | `taskPriority()` returns `UBaseType_t` native priorities `tskIDLE_PRIORITY + 0..4`; 2.0.1 requires `osPriority_t`, and native 0 (the idle task's level) has no RTOS2 equivalent | map the order deliberately: +0 → `osPriorityLow`, +1 → `osPriorityLow1`, +2 → `osPriorityLow2`, +3 → `osPriorityLow3`, +4 → `osPriorityLow4` (same order and spacing, all above idle and timer task) | the mapping shown (D5) |

## 5. Baseline

**Board:** not connected (no Grove Vision AI V2 USB serial port on the host; the attached SEGGER J-Link
and ST-LINK belong to other boards). **Flashing** (README): build → copy the ELF to
`we2_image_gen_local/input_case1_secboot/` → `./we2_local_image_gen project_case1_blp_wlcsp.json` →
`python3 xmodem/xmodem_send.py --port=<port> --baudrate=921600 --protocol=xmodem
--file=we2_image_gen_local/output_case1_sec_wlcsp/output.img` (KWS apps add
`--model="model_zoo/kws_pdm_record/kwt1_relu_mfcc_fvp_aligned_vela.tflite 0xB7B000 0x00000"`); the UART
console is the same port. SWD debugging needs a CMSIS-DAP probe with Himax's pyOCD build
(`swd_debugging/`); none is set up.

**Captured so far:** build status and sizes of all 18 apps (§3, `results/baseline_build_summary.txt`).
**Board output: not captured** — needs the board. Then, per app (current state, Arm GNU 13.2):

| Runs without extra hardware | Needs |
|---|---|
| `alt_test`, `alt_test_max`, `alt_alt_test`, `comstime`, `chain_test`, `sieve`, `matrix_multiplication`, `dining_philosophers`, `asymmetric_philosophers`, `lossy_policy_test`, `irq` | — (several print stack reports) |
| `kws_pdm_record` | the PDM microphone (on the Grove Vision AI V2 per Seeed's description — to confirm) and the model in flash; prints timing/statistics reports |
| `kws_iic`, `kws_PCA9685`, `kws_PCA9685_alt` | the above plus a PCF8574 / PCA9685 board on I2C 0; `_alt` also keyboard input on the console. Without the I2C board: start-up and audio path only (the actuator process would wait for an I2C completion) |
| `shake_detection` | an ADXL345 on I2C 0 |
| `allon_sensor_tflm` | a camera module on the CSI connector |
| `AI_testbench` | does not build |

Also to read on the board (one-off diagnostic print in a scratch build): the NVIC priority of the timer
1, I2C 0, sensor-DP/XDMA and NPU interrupts after their drivers are started (§1).

## 6. Migration plan

**Shared foundation (one commit each where possible):**
1. `library/csp4cmsis/` ← unmodified v2.0.1 `csp4cmsis/` + `LICENSE` + `VERSION`; remove
   `library/old_csp4cmsis/`; untrack/ignore `prebuilt_libs/gnu/libcsp4cmsis.a`.
2. `library/library.mk`: fail loudly if `csp4cmsis` is selected but its `.mk` is missing.
3. Per app `.mk`: `override OS_HAL := y`; `APPL_DEFINES += -DCSP4CMSIS_RTOS2_BACKEND_FREERTOS
   -DCSP4CMSIS_STATIC_ALLOCATION -DCSP4CMSIS_MAX_SYSCALL_INTERRUPT_PRIORITY=5
   -DCSP4CMSIS_DEVICE_HEADER=\"WE2_device.h\"`.
4. Per app `FreeRTOSConfig.h`: remove the two SysTick mappings; printing `configASSERT`.
5. Per app `app_main()`: `osKernelInitialize()` … `osKernelStart()` instead of `vTaskStartScheduler()`.
6. Interrupt priorities: `NVIC_SetPriority(<irq>, 5..7)` before enabling each ISR that calls
   CSP4CMSIS or FreeRTOS (after reading the actual values on the board).

**Pilot:** `csp4cmsis_sieve` — the smallest network (pure rendezvous pipeline, three process types),
deterministic output, no peripherals, no ALT, no ISR, and it compiles unchanged: a failure isolates the
foundation (adapter, start-up, tick, library). Then `alt_test` (ALT and stack reports) as the second
check before the rest.

**Then:** the remaining A-apps; the B-apps after the decisions, `allon_sensor_tflm` last. Per app:
launcher on CMSIS-RTOS2 (`osThreadNew`, static stack, stack in bytes), `SleepFor()`/`osDelay()`
instead of `vTaskDelay()`, `osThreadExit()` instead of `vTaskDelete(NULL)`, named `osPriority_t`
keeping the old order (code comment), FreeRTOS heap right-sized from measurements.

**Verification per app:** build (Arm GNU 13.2, 0 new warnings in app code); board output vs baseline,
every difference classified (fixed pre-1.0 defect, intended 2.0 change, regression); stack figures
(the apps' own reports or a stack-mark read) and heap (`xPortGetMinimumEverFreeHeapSize`).

**README updates:** toolchain (Arm GNU 13.2.rel1); library version and how it is integrated (copy in
`library/csp4cmsis/`, `VERSION`); `OS_HAL := y` and the four defines; the M55 adapter rule (no RTOS2
calls with BASEPRI raised in application code); per app: the 2.0 semantics where they changed
(I2C completion, timer, camera trigger, ALT-vs-ALT), the two README errors above.

## Decisions for you

- **D1 Integration:** (b) unmodified copy + `VERSION` + `LICENSE` (recommended) or (a) submodule.
- **D2 RTOS2:** the SDK's `OS_HAL := y` adapter (recommended), Arm's `rtos2_freertos` package, or RTX5.
- **D3 Old artefacts:** remove `library/old_csp4cmsis/`; untrack/ignore `prebuilt_libs/gnu/libcsp4cmsis.a`
  (recommended); leave the other vendor archives that builds rewrite as they are?
- **D4 Loud failure:** the csp4cmsis-only check in `library/library.mk` (recommended) or per-app checks.
- **D5 KWS priorities:** native +0..+4 → `osPriorityLow`..`osPriorityLow4` (recommended).
- **D6 I2C completion** (`shake_detection`, three KWS apps): `BufferedChannel<bool,1>` Block + trap (recommended) or KeepNewest.
- **D7 `irq`:** `SamplingBufferedChannel<uint32_t,1,KeepNewest>` (recommended) or `BufferedChannel<uint32_t,N>` Block.
- **D8 neurochannel trigger:** `BufferedChannel<trigger_t,1>` Block + trap (recommended) or KeepNewest.
- **D9 `alt_alt_test`:** turn into a "2.0 communicates" demonstration (recommended) or remove.
- **D10 `AI_testbench`:** remove (recommended), fix, or leave out of scope.
- **D11 Board:** connect the Grove Vision AI V2 for the baseline (and say which peripherals are
  available: ADXL345, PCF8574, PCA9685, camera, SD card).
