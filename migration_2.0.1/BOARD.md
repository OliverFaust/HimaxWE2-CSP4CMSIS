# Board results — baseline, NVIC read-out, pilot comparison

**Board:** Grove Vision AI V2 (WE2), USB serial CH343 (`1a86:55d3`), 921600 baud. **Date:** 2026-10-04.
**Toolchain:** Arm GNU 13.2.rel1. Logs: `results/board/` (UART output from the first boot line on).

**Flashing without the reset button:** opening the serial port raises RTS, which resets the WE2,
so `xmodem/xmodem_send.py` meets the bootloader's 100 ms prompt without a button press. For a capture
from a clean boot, open the port (or pulse RTS) and read.
Sequence per app: ELF → `we2_image_gen_local/input_case1_secboot/` → `./we2_local_image_gen
project_case1_blp_wlcsp.json` → `xmodem_send.py --port=/dev/ttyACM0 --baudrate=921600
--protocol=xmodem --file=…/output.img` → capture.

## Baseline: old state (`main`, 77124fa), 25 s capture per app

| App | Result |
|---|---|
| `sieve` | primes 2…47 (filters 2, 3, 5, 7, 11; sink 13…47) |
| `alt_test` | 20 000 messages verified, SUCCESS; both senders finish at the end (fair); stacks: MainApp 864 B of 16 KB, Snd 736/800 of 2048 B, Receiver 968 of 4096 B |
| `alt_test_max` | 16 senders; 1 104 000 of 1 600 000 messages in 25 s, spread grows to ~2000 (max−min per sender), drift ~3 %; senders 160–200 of 2048 B |
| `comstime` | 22.30 µs/cycle (10 000 cycles in 223 ms), repeated |
| `chain_test` | 1000 values through 5 relays, SUCCESS |
| `matrix_multiplication` | 3×3 systolic A × I, all 9 PEs COMPLETED |
| `dining_philosophers` | deadlocks as designed: 10 meals, then all five have picked up the left fork and wait for the right; output stops |
| `asymmetric_philosophers` | no deadlock: 628 EATING lines in 25 s |
| `lossy_policy_test` | **timing-dependent, as predicted:** the receiver drains after its fixed 100 ms, in the middle of the first burst — KeepNewest shows 68 930…70 271 with gaps (sum 695 309), not the last ten; the KeepOldest burst starts after draining began. Hence D: "done" rendezvous |
| `irq` | timer 1 → channel: 22 values received in 25 s (~1 per s, two heartbeats between) |
| `allon_sensor_tflm` (neurochannel, IMX219 camera on CSI; 40 s) | 764 frames in ~39 s (≈ 19.6 frames/s), no stall; person scores −51…8 (no person in view); stacks: Camera 744/1024 B (280 B headroom — the tightest), Inference 472/1024 B, Console 320/1024 B, CSP_Main 376 of 2048 B. Each result is printed twice by design (Inference's `dbg_printf` and Console's `xprintf`), and lines interleave mid-string (unlocked `xprintf` from several processes) |
| `kws_pdm_record` | runs with the on-board microphone: model loaded from flash, results ("None"), timing reports (`rt` 0.85–1.03×) |

Not run: `shake_detection` (ADXL345), `kws_iic`/`kws_PCA9685`/`kws_PCA9685_alt` (I2C actuator
boards) — peripherals not available so far.

## NVIC priorities (old state)

Scratch builds of `main` with a diagnostic task (`results/board/nvic_readout_diag.c.txt`, not
committed to any app) that prints the priority of every enabled interrupt 3 s and 10 s after boot,
after the apps' drivers have started (`results/board/nvic_readout_main.txt`):

- **every enabled interrupt is at priority 0** — the highest, above the syscall threshold 5
  (`configMAX_SYSCALL_INTERRUPT_PRIORITY`); SVCall 0, PendSV 7, SysTick 7.
- Relevant ones: `TIMER1INT_IRQn` 35 (`irq`), `I2C_MST_0_intr_IRQn` 93 (I2C apps, enabled in all),
  `HimaxPDM_int_rx_avail_IRQn` 114, `HimaxPDM_int_err_IRQn` 115, `DMAC1/2` 133/66 (KWS),
  `U55_IRQn` 192 (NPU: KWS, allon), `TIMER3INT_IRQn` 37 and `I2C_SLAVE`/`I2C_Slave_1` 92/112 (allon);
  the rest are the SDK's security/bus-fault interrupts (MPC/PPC, MBOX).
- So neither the SDK nor the prebuilt drivers set priorities: each app must call
  `NVIC_SetPriority(irq, 5..7)` for every interrupt whose handler calls CSP4CMSIS or FreeRTOS (timer 1,
  I2C master 0, U55, PDM/DMA callbacks if they signal tasks, sensor data path). Today those handlers
  run at 0 and call `…FromISR()` — outside what FreeRTOS allows; it has worked so far, but a critical
  section does not mask them.
- `kws_pdm_record`'s read-out build stopped after the KWS initialisation (the unmodified `main` build
  runs, see above): the diagnostic task interferes with that app; not pursued, `kws_iic` covers the
  same interrupts.

## Pilot comparison (branch `csp4cmsis-2.0.1`)

| App | 2.0.1 vs baseline |
|---|---|
| `sieve` | output **identical** (byte-for-byte after the boot lines) |
| `alt_test` | same: 20 000 verified, 0 errors, SUCCESS, both senders finish at the end; process stacks identical (Snd 736/800 B, Receiver 952 vs 968 B); MainApp 896 B of the new static 4 KB (old: 864 B of 16 KB) |
| forced `configASSERT(0)` (scratch build of `sieve`) | prints `configASSERT failed: app/scenario_app/csp4cmsis_sieve/tests.cpp:94` with interrupts disabled, then halts — the UART write is blocking, as hoped |

MainApp needs < 1 KB; the 4 KB launcher stacks can be reduced (e.g. 2 KB) when the remaining apps are
migrated.

## Remaining A-apps (branch `csp4cmsis-2.0.1`, 2026-10-05)

Migrated as the pilots: launcher on `osThreadNew()` with a static 4 KB stack, `osThreadExit()`,
`SleepFor()`, `osKernelGetTickCount()`, named priorities in the old order (MainApp `osPriorityLow3`
above the network `osPriorityLow2`; `kws_pdm_record`'s Inference `osPriorityLow3`), current channel
names. Built with Arm GNU 13.2.rel1: no new warnings in app code (`results/phaseB2_build_summary.txt`).
Logs: `results/board/migrated_<app>.txt` (final build), `results/board/measure_<app>.txt`.

| App | 2.0.1 vs `main` baseline | Class |
|---|---|---|
| `alt_test_max` | 1 600 000 messages verified, no errors, SUCCESS (the 25 s baseline capture reached 1.1 M). Fairness: spread 0–17 messages, drift ≤ 0.4 % (mostly 0.0 %); baseline: spread up to ~2000, drift ~2.9 % | (a) `fairSelect()` fairness fixed |
| `comstime` | 22.7 µs/cycle (227 ms per 10 000), baseline 22.3 µs/cycle: +0.4 µs (1.8 %); trigger events identical (24 in 25 s) | (b) different channel/RTOS layer; small, not a functional change |
| `chain_test` | output identical | — |
| `matrix_multiplication` | results and line order identical; PE stacks 8–40 B smaller | — |
| `dining_philosophers` | output identical, same deadlock after 10 meals | — |
| `asymmetric_philosophers` | output identical (628 meals in 25 s, no deadlock) | — |
| `lossy_policy_test` | KeepNewest 999 990…999 999, KeepOldest 0…9, sums 9 999 945 / 45, `PASS`; baseline was timing-dependent (drained mid-burst) | (a) via the "done" rendezvous (test design) |
| `kws_pdm_record` | first build: `std::bad_alloc` after the banner (`migrated_kws_pdm_record_before_heap_fix.txt`); final build: output matches the baseline over the whole baseline capture (on-board microphone, quiet room: "None"; timing reports equal within 1 ms; only the tensor-arena address differs) | (b), see below |

**Why `kws_pdm_record` threw `std::bad_alloc`:** the pre-2.0 library overrode the global
`operator new`/`delete` with `pvPortMalloc`/`vPortFree`; 2.0 removed that (`glue.cpp`). The KWS code's
C++ allocations (~30 KB) therefore moved from the FreeRTOS heap to the C library heap (`__HEAP_SIZE`
in the app's `.ld`, 0x7000 = 28 KB), which overflowed. Measured with the same diagnostic on both
builds (`measure_kws_pdm_record_baseline_main.txt` vs `measure_kws_pdm_record.txt`): baseline
FreeRTOS heap minimum-ever-free 1384 of 65 536 B, C heap 4616 B; 2.0.1 FreeRTOS heap 0 allocations,
C heap 34 840 B. Fix: `__HEAP_SIZE` 0xB000 (44 KB, +16 KB), FreeRTOS heap 1 KB (−63 KB) — net 47 KB less RAM.

**Ethos-U semaphore:** `kws_pdm_record` has no RTOS override (only `kws_iic`, `kws_PCA9685`,
`kws_PCA9685_alt` carry `ethosu_rtos_semaphore.c`); it uses the driver's weak default, a
`__WFE()` loop, so `Invoke()` does not block in the RTOS — unchanged from `main`.

### Stack and heap measurements (2.0.1)

Scratch builds with a diagnostic thread (`results/board/measure_diag.c.txt`, not committed to any
app): every thread's stack high-water mark, the launcher stack (scanned for the fill pattern after
it exited; 8 KB in these builds), FreeRTOS heap statistics and the C library heap, at 3/10/25/40 s.

| App | Launcher used (of 4096 B) | Process stacks: most used / allocated (B) | FreeRTOS heap allocations | C heap used / `__HEAP_SIZE` |
|---|---|---|---|---|
| `alt_test_max` | 1088 | Receiver 1176/8192, Snd 248/2048 | 0 | 46 408 / 65 536 (16 Senders via `new`) |
| `comstime` | 904 | Consumer 952/4096, others 232/2048 | 0 | 3456 / 65 536 |
| `chain_test` | 352 | Relay 224/1024 (sender and checker finish before the first read-out) | 0 | 3936 / 65 536 |
| `matrix_multiplication` | 2256 | PE 856/4096, feeders/sinks 248/2048 | 0 | 3760 / 16 384 |
| `dining_philosophers` | 440 | Philosopher 800/1024, Fork 224/1024 | 0 | 2304 / 65 536 |
| `asymmetric_philosophers` | 456 | Philosopher 840/1024, Fork 224/1024 | 0 | 2136 / 65 536 |
| `lossy_policy_test` | 336 | (both processes finish before the first read-out) | 0 | 3312 / 65 536 |
| `kws_pdm_record` | 456 | Inference 1256/32 768, Preprocessing 792/1024, Acquisition 512/1024, Reporter 544/1024 | 0 | 34 840 / 45 056 (after the fix) |

Consequences, applied: `configTOTAL_HEAP_SIZE` 64 KB → 1 KB in all eight (comment with these values);
`kws_pdm_record` `__HEAP_SIZE` 0x7000 → 0xB000. RAM (`.bss`) per app ~60 KB smaller. Not changed
(stack sizes were not part of this step): the philosophers' 1 KB stacks have 184–224 B headroom,
Preprocessing 232 B (as on `main`); Inference's 32 KB stack uses 1.3 KB.

## Apps needing decisions (branch `csp4cmsis-2.0.1`, 2026-10-05)

Hardware: Grove Vision AI V2 with the on-board microphone and the IMX219 camera; **no ADXL345,
PCF8574 or PCA9685** (none listed). Builds: no new warnings in app code
(`results/phaseB3_build_summary.txt`).

### Pilot heaps
`csp4cmsis_sieve`, `csp4cmsis_alt_test`: 0 FreeRTOS heap allocations (C heap 4.0 / 1.1 KB) →
`configTOTAL_HEAP_SIZE` 1 KB (`measure_sieve.txt`, `measure_alt_test.txt`).

### Interrupt priorities
Read on `main` with the drivers running (static diagnostic thread, `nvic_readout_diag2.c.txt`;
`nvic_readout_main_drivers_running.txt`): **every enabled interrupt at priority 0** in all seven
interrupt-using apps, including those the neurochannel enables with the camera attached:
`SC_trigger_timeout_IRQn` 84, `SC_sen_nframe_end_IRQn` 85, `edm_int_out_IRQn` 143, `WDMA2_int_IRQn`
154/155, `WDMA3_int_IRQn` 156/157, besides `TIMER3INT_IRQn` 37, I2C 92/93/112 and `U55_IRQn` 192.

Interrupts whose handler calls CSP4CMSIS or FreeRTOS, now set to 5 with `NVIC_SetPriority(…,
CSP4CMSIS_MAX_SYSCALL_INTERRUPT_PRIORITY)` before they are enabled or the driver starts (comment at
each call; rule in the top-level README):

| App | Interrupt | Handler's RTOS/CSP call | Read back after migration |
|---|---|---|---|
| `irq` | `TIMER1INT_IRQn` 35 | `isrWriter().putFromISR()` | 5 |
| `shake_detection` | `I2C_MST_0_intr_IRQn` 93 | `isrWriter().putFromISR()` | 5 |
| `kws_iic`, `kws_PCA9685`, `kws_PCA9685_alt` | `I2C_MST_0_intr_IRQn` 93 | `isrWriter().putFromISR()` | 5 |
| | `DMAC2_DMACINTR_IRQn` 66 (PDM DMA) | tick read (`osKernelGetTickCount()`, was `xTaskGetTickCountFromISR()`) | 5 |
| | `U55_IRQn` 192 (NPU) | `xSemaphoreGiveFromISR()` (Ethos-U override) | 5 |

`kws_pdm_record` needs none: its NPU handler uses the driver's bare-metal semaphore and its PDM DMA
callback makes no RTOS call. The neurochannel's camera interrupt is for its own step.

### Results

| App | 2.0.1 vs `main` | Class |
|---|---|---|
| `irq` (D7) | count 1…23 in 25 s, no gaps (`main`: 1…22; the ISR wrote to a rendezvous with `putFromISR()`, dropping ticks whenever TimerProcess was not waiting) | (a) ISR path no longer drops ticks silently; a miss would now show as a gap |
| `shake_detection` (D6) | start-up output identical; measured ~40 I2C completions/s for 25 s (driver completes unacknowledged transfers), none lost | — (sensor not available) |
| `kws_iic`, `kws_PCA9685`, `kws_PCA9685_alt` (D6, D5) | audio path matches over the whole baseline capture: no missed buffers, rtf 0.97; MFCC 120 vs 140 ms per 20 steps (C++ allocations now in newlib instead of the FreeRTOS heap), Invoke 0.1–1 ms slower per call, `[Mem] free_heap` reports the new 1 KB FreeRTOS heap; print interleaving and two ambient "yes" detections differ between runs | (b) |

Not tested: the I2C devices themselves (README of each app says so).

### Heaps (measured, then set)

| App | FreeRTOS heap: allocations / used | → `configTOTAL_HEAP_SIZE` | C heap used | → `__HEAP_SIZE` |
|---|---|---|---|---|
| `irq` | 0 | 64 KB → 1 KB | 2.1 KB | 64 KB (unchanged) |
| `shake_detection` | 0 | 64 KB → 1 KB | 2.8 KB | 28 KB (unchanged) |
| `kws_iic`, `kws_PCA9685` | 2 / 200 B (Ethos-U semaphore) | 300 KB → 1 KB | 34.7 KB | 28 → 44 KB |
| `kws_PCA9685_alt` | 2 / 200 B | 300 KB → 1 KB | 32.0 KB | 28 → 44 KB |

Stacks (`measure_<app>.txt`): launchers 228–552 B of 4096; irq TimerProcess 712/1024 B; shake
processes ≤ 368/1024 B; KWS Acquisition 464/8192, Preprocessing 800/16 384, Inference 1264/32 768,
Filter/FSM/Console ≤ 400/2048, Reporter and the I2C process ≤ 608/4096 B.
