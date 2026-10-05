# Test Scenario: Comstime (Communication Time Benchmark)

## 📌 Overview
The `csp4cmsis_comstime` scenario is a classic CSP benchmark used to measure the communication overhead and scheduling latency of the framework. It implements a cyclic process network—a "feedback loop"—where data is constantly transformed and passed between concurrent processes.

This test is critical for establishing the **performance baseline** of `csp4cmsis` on the **Cortex-M55**, specifically measuring how many microseconds it takes for a single data token to undergo a full context-switch and synchronization cycle.



---

## 🏗 Architecture

The benchmark consists of five processes operating in parallel, forming a self-sustaining feedback loop with an external trigger:

| Process | Responsibility |
| :--- | :--- |
| **Prefix** | Bootstraps the loop by sending an initial value (0), then acts as a buffer. |
| **Successor** | Performs a simple arithmetic transformation (`x + 1`) on incoming data. |
| **Delta** | Duplicates incoming data, sending one copy back into the ring and one to the consumer. |
| **Consumer** | Uses the `Alternative` mechanism to monitor data and an external trigger simultaneously. |
| **Trigger** | Periodically injects a signal to verify that the `Alternative` selection remains responsive during high-throughput. |



---

## 🛠 Technical Details

### 1. The Feedback Loop Logic
The "Ring" is formed by the path: `Prefix -> Delta -> Successor -> Prefix`. Because these are synchronous rendezvous channels, the speed of the loop is limited strictly by the efficiency of the `csp4cmsis` scheduler and the underlying FreeRTOS context switching.

### 2. High-Performance `Alternative` Usage
The `ComstimeConsumer` utilizes the `fairSelect()` method. This ensures that even though the loop is pushing data as fast as the CPU allows, the `Trigger` process is never starved of service. 

### 3. Latency Measurement
The test calculates the average latency per communication cycle by:
1. Recording the start tick count.
2. Running **10,000 iterations** of the loop.
3. Calculating the delta time in microseconds ($\mu s$) per cycle.

---

## 🚀 How to Run

### Prerequisites
* **Hardware:** Himax WE2 (Cortex-M55).
* **Library and RTOS:** CSP4CMSIS 2.0.1 on FreeRTOS 10.5.1 through the SDK's CMSIS-RTOS2 adapter (`OS_HAL := y`); the app starts the kernel with `osKernelInitialize()`/`osKernelStart()`. The latency is measured with `osKernelGetTickCount()` (1 ms tick).
* **Make environment** in `CSP4CMSIS/EPII_CM55M_APP_S/makefile` set `APP_TYPE = csp4cmsis_comstime`.

### Expected UART Output
The console will display the results of the 10,000-cycle stress test. The "Avg Latency" value represents the cost of a rendezvous on your specific hardware configuration.

```text
[Comstime] Benchmark starting. Measuring 10000 cycles...
--- Comstime Results ---
Iterations: 10000
Total Time: 227.00 ms
Avg Latency: 22.70 us/cycle
Last Value: 9999
------------------------
>>> [ALT] External Trigger Event Latency Check <<<
