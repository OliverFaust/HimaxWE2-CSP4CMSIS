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
| `kws_pdm_record` | runs with the on-board microphone: model loaded from flash, results ("None"), timing reports (`rt` 0.85–1.03×) |

Not run: `shake_detection` (ADXL345), `kws_iic`/`kws_PCA9685`/`kws_PCA9685_alt` (I2C actuator
boards), `allon_sensor_tflm` (camera) — peripherals to be confirmed.

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
