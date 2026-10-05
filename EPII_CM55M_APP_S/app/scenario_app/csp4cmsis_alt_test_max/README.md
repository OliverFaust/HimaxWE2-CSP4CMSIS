# Test Scenario: 16-Sender ALT Stress Test (Max Capacity)

## 📌 Overview
The `csp4cmsis_alt_test_max` scenario is the ultimate stress test for the framework's **Alternative (ALT)** mechanism. It pushes the implementation to its architected limit by multiplexing **16 independent sender channels** into a single receiver process.

This test validates the stability of the **16-Guard Bit-Mapping** logic and the robustness of the **Fair Selection** algorithm under extreme congestion. It ensures that even with 1.6 million total messages ($16 \times 100,000$), the system maintains perfect data integrity and starvation-freedom.



---

## 🏗 Architecture

The process network is structured as a massive "Fan-In" pattern, utilizing the maximum guard capacity supported by the current bit-masking implementation:

| Component | Responsibility |
| :--- | :--- |
| **16 Senders** | Each sender operates in its own thread, attempting to saturate its specific channel with 100,000 sequenced messages. |
| **16 Channels** | Static `Channel<Message>` instances providing synchronous rendezvous points for each sender. |
| **1 Receiver** | Manages a single `Alternative` object with 16 registered bindings. It verifies the source and sequence of every incoming packet. |



---

## 🛠 Technical Details

### 1. Bit-Masking & Thread Flags
With CSP4CMSIS 2.0 the `Alternative` mechanism maps each of the 16 guards to its own CMSIS-RTOS2 thread flag of the receiving thread (guard *i* is signalled with bit 8 + *i*; 16 guards is the maximum). This test proves that:
* The mapping between `alt.addBinding()` index and flag bit is consistent.
* The system correctly handles "all-bits-set" scenarios where all 16 senders are waiting simultaneously.

### 2. Fair Selection at Scale
With 16 senders competing for the receiver's attention, a standard priority selection would lead to the starvation of higher-indexed senders. This test relies on `fairSelect()` to:
* Implement a circular (round-robin) search across the 16-bit mask.
* Guarantee an upper bound on latency for every sender in the network.

`priSelect()` is left in as a commented-out swap in `Receiver::run()` -- rerunning the test with it in place of `fairSelect()` is the intended way to see the starvation `fairSelect()` is protecting against.

Fairness isn't just asserted, it's measured -- see [Alt Selection Fairness Measurement](#-alt-selection-fairness-measurement) below.

### 3. Memory & Performance
Despite the scale, the **Zero-Heap** philosophy remains intact. The `Alternative` metadata and guard pointers are managed on the stack, and the data transfer remains a direct copy between process contexts during the rendezvous. Actual stack usage is now measured rather than assumed -- see [Stack Occupancy Reporting](#-stack-occupancy-reporting) below.

---

## ⚖️ Alt Selection Fairness Measurement

`fairSelect()` is asserted to be starvation-free, but the test now backs that claim with a running measurement rather than only an end-of-run message count.

Every `CHECK_INTERVAL` messages (2,000), `Receiver::run()`:
* Tracks `next_seq[i]`, the count of messages consumed so far from each of the 16 senders.
* Computes the **spread** -- `max(next_seq) - min(next_seq)` -- the gap between the most-served and least-served sender.
* Converts that into a **percentage drift**: `spread / (total_count / NUM_SENDERS) * 100`, i.e. the spread relative to the average number of messages each sender should have delivered by that point.
* Flags a `!! FAIRNESS VIOLATION !!` if drift exceeds a 15% threshold.

This gives a live, quantitative view of how evenly `fairSelect()` is servicing all 16 channels, rather than only confirming that every message eventually arrived.

### Observed Result
With CSP4CMSIS 2.0.1 the spread stays within a few tens of messages for the whole run (drift at most 0.4%, mostly 0.0%) and returns to 0 once every sender has delivered its full quota:

```text
[Receiver] Progress: 2000 / 1600000 | Spread: 0 (Min: 125, Max: 125) | Drift: 0.0%
...
[Receiver] Progress: 1594000 / 1600000 | Spread: 17 (Min: 99614, Max: 99631) | Drift: 0.0%
[Receiver] Progress: 1598000 / 1600000 | Spread: 17 (Min: 99864, Max: 99881) | Drift: 0.0%
[Receiver] Progress: 1600000 / 1600000 | Spread: 0 (Min: 100000, Max: 100000) | Drift: 0.0%
[Receiver] SUCCESS: All 1600000 messages verified with fair round-robin.
```

No `FAIRNESS VIOLATION` was logged at any point in the run. (With the pre-2.0 library the spread grew to about 2,000 messages, a drift of about 3%.)

---

## 📊 Stack Occupancy Reporting

The provisional stack sizes on `Sender` (`CSProcessStatic<512>`) and `Receiver` (`CSProcessStatic<2048>`) were picked before this test ever ran -- 512 words for Sender's tight send loop, and a larger 2048 for Receiver since it holds a 16-binding `Alternative`, a 16-entry `Message` buffer, and calls `printf` (which newlib can make stack-hungry). `MainApp_Task` itself isn't a `CSProcess`, so its stack (a static 4096-byte array) is supplied directly to `osThreadNew`.

Once the network starts, `MainApp_Task` becomes a monitoring loop: every `CSP_STACK_REPORT_INTERVAL_MS` (default 3000 ms) it reads its own high-water-mark plus, via `network.forEachProcess(...)`, the allocated size, bytes used, unused headroom, and HWM (in words) for every Sender and the Receiver. Sender and Receiver both idle in `SleepFor(osWaitForever)` once they finish rather than exiting (an exited thread's stack can no longer be queried), so -- as with the stack reporting added to the KWS pipeline -- there's no natural "network finished" point to take a single reading at; this loop keeps reporting live for the life of the task instead.

### Observed Result (CSP4CMSIS 2.0.1)
```text
MainApp: 1088/4096 bytes used (3008 bytes unused headroom)
Receiver: 1176/8192 bytes used (7016 bytes unused headroom, 1754 words HWM)
Snd1: 240/2048 bytes used (1808 bytes unused headroom, 452 words HWM)
...
Snd16: 240/2048 bytes used (1808 bytes unused headroom, 452 words HWM)
```

Both provisional sizes turned out to be generous: every Sender uses at most 248/2048 bytes, and Receiver -- despite the 16-way `Alternative` and `printf` calls -- uses only 1176/8192 bytes. `MainApp_Task` uses 1088 of its 4096 bytes while running the report loop. These numbers make `Sender`/`Receiver`'s `CSProcessStatic<N>` values good candidates for shrinking in a future pass, now that they're backed by measurement rather than a guess.

---

## 🚀 How to Run

### Prerequisites
* **Hardware:** Himax WE2 (Cortex-M55). 
* **Library and RTOS:** CSP4CMSIS 2.0.1 on FreeRTOS 10.5.1 through the SDK's CMSIS-RTOS2 adapter (`OS_HAL := y`); the app starts the kernel with `osKernelInitialize()`/`osKernelStart()`. The 16 Senders are created with `new`, so their objects (including their stacks) come from the C library heap (`__HEAP_SIZE` in the `.ld`, 46 KB of 64 KB used); the FreeRTOS heap is not used.
* **Make environment** in `CSP4CMSIS/EPII_CM55M_APP_S/makefile` set `APP_TYPE = csp4cmsis_alt_test_max`.

### Expected UART Output
The receiver logs progress, spread, and drift every 2,000 messages. Total verification of 1,600,000 messages with no fairness violation indicates a successful test. Stack occupancy lines (see [Stack Occupancy Reporting](#-stack-occupancy-reporting)) begin appearing once the network is running and continue every `CSP_STACK_REPORT_INTERVAL_MS` for the life of the task.

```text
--- Launching 16-Sender CSP Network ---
[Receiver] Stress Test: Monitoring 16 Channels.
*** MainApp_Task: Run() returned, entering stack-report loop ***
[Receiver] Stress Test: Monitoring 16 Channels.
[Receiver] Progress: 2000 / 1600000 | Spread: 0 (Min: 125, Max: 125) | Drift: 0.0%
...
[Receiver] Progress: 1598000 / 1600000 | Spread: 17 (Min: 99864, Max: 99881) | Drift: 0.0%
[Receiver] Progress: 1600000 / 1600000 | Spread: 0 (Min: 100000, Max: 100000) | Drift: 0.0%
[Receiver] SUCCESS: All 1600000 messages verified with fair round-robin.
...
MainApp: 1088/4096 bytes used (3008 bytes unused headroom)
Receiver: 1176/8192 bytes used (7016 bytes unused headroom, 1754 words HWM)
Snd1: 240/2048 bytes used (1808 bytes unused headroom, 452 words HWM)
...
Snd16: 240/2048 bytes used (1808 bytes unused headroom, 452 words HWM)
```
