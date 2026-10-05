# Scenario: Interrupt-Driven Shake Detection (ADXL345 over I2C)

## 📌 Overview
The `csp4cmsis_shake_detection` scenario shows how a hardware interrupt joins a **CSP4CMSIS** process network on the Himax WE2. It reads an **ADXL345** accelerometer over **I2C master 0** (address 0x53) at about 20 Hz and reports a shake when the change between two readings exceeds a threshold.

The I2C transfers are interrupt-driven: the reader process starts a transfer with the Himax driver (`hx_drv_i2cm_interrupt_write`/`_read`) and then waits on a channel; the driver's completion callback, running in the I2C interrupt, writes to that channel.

---

## 🏗 Architecture & Process Network

```text
  [Hardware]                         [CSP processes]

+-----------+   I2C master 0   +----------------+  Channel<AccelData>  +------------+  Channel<bool>  +--------------------+
|  ADXL345  | <--------------> | Adxl345Reader  | -------------------> | ShakeLogic | --------------> | ShakeEventConsumer | --> UART
+-----------+                  +----------------+                      +------------+                 +--------------------+
      |                                ^
      | transfer complete              | BufferedChannel<bool, 1>  (written by the ISR via isrWriter())
      v                                |
 I2C_MST_0_intr_IRQn --> i2c_callback()
```

| Process | Responsibility |
| :--- | :--- |
| **Adxl345Reader** | Configures the ADXL345 (measurement mode, full resolution, ±2 g), then reads X/Y/Z (6 bytes from 0x32) every 50 ms. Each register access is one I2C transfer followed by a wait for its completion. |
| **ShakeLogic** | Sums the absolute change of X, Y and Z against the previous reading; above 300 it sends a shake event. |
| **ShakeEventConsumer** | Prints `!!! SHAKE DETECTED !!!`. |

## 🛠 Technical Details

### Interrupt → channel
An interrupt cannot wait for a partner, so it never writes to a rendezvous channel: the completion callback writes `true` to a one-slot `BufferedChannel<bool, 1>` through `isrWriter().putFromISR()`. The slot keeps a completion that arrives before the reader is waiting for it (with a rendezvous it would be lost, and the reader would wait for ever). Because the reader starts only one transfer at a time, at most one completion can be pending; if a write ever fails, a second completion arrived before the first was read (a driver bug), and the callback prints a message and halts instead of losing it silently.

### Interrupt priority
An interrupt whose handler calls CSP4CMSIS or FreeRTOS must run at priority 5..7 (at or below `CSP4CMSIS_MAX_SYSCALL_INTERRUPT_PRIORITY` = 5, 3 priority bits). The SDK leaves every interrupt at 0, the highest, so `app_main()` sets `I2C_MST_0_intr_IRQn` to 5 before the I2C driver is started.

### Library and RTOS
CSP4CMSIS 2.0.1 on FreeRTOS 10.5.1 through the SDK's CMSIS-RTOS2 adapter (`OS_HAL := y`); the app starts the kernel with `osKernelInitialize()`/`osKernelStart()`. All threads and stacks are static; the FreeRTOS heap is not used (`configTOTAL_HEAP_SIZE` 1 KB).

## 🚀 How to Run

### Prerequisites
* **Hardware:** Himax WE2 (Grove Vision AI V2) with an ADXL345 on I2C master 0 (PA2 = SCL, PA3 = SDA), address 0x53.
* **Make environment:** in `EPII_CM55M_APP_S/makefile` set `APP_TYPE = csp4cmsis_shake_detection`.

### Expected UART Output
```text
Initializing System & CSP Network...
Application initialization (via csp_app_main_init) started.
Application tasks created successfully.
[Reader] Initializing ADXL345...

============================
 !!! SHAKE DETECTED !!!
============================
```

### Test status (CSP4CMSIS 2.0.1)
The I2C part is migrated but **not tested with an ADXL345**. On the board without the sensor, the app starts, and the driver still completes every (unacknowledged) transfer: the completion path ran about 40 times per second for 25 s without a lost completion. No shake can be detected without the sensor.
