# Test Scenario: Relay Chain (SPN Principle)

## 📌 Overview
The `csp4cmsis_chain_test` scenario demonstrates the **Sequential Process Network (SPN)** principle. It constructs a linear pipeline of processes where data is passed from a source to a sink through multiple intermediate "Relay" stages.

This test validates the framework's ability to handle deep synchronization chains. In a synchronous CSP model, a value can only move from the beginning of the chain to the end if every intermediate process is ready for a rendezvous, effectively proving the correctness of the back-pressure and scheduling logic.



---

## 🏗 Architecture

The network consists of $N+1$ channels connecting $N+2$ processes in a strict linear sequence:

| Component | Responsibility |
| :--- | :--- |
| **CountingSender** | The "Source". Generates a stream of 1,000 incrementing integers. |
| **Relay (x5)** | The "Middle-ware". Pure sequential actors that input a value from the left and output it to the right. |
| **CheckerReceiver** | The "Sink". Consumes the stream and verifies that every integer arrived in sequence without corruption. |

### Topology
`Sender` → `[C0]` → `Relay 0` → `[C1]` → `Relay 1` → `[C2]` → `Relay 2` → `[C3]` → `Relay 3` → `[C4]` → `Relay 4` → `[C5]` → `Receiver`



---

## 🛠 Technical Details

### 1. The SPN Principle
This test adheres to the "pure" CSP model where processes are black boxes. A `Relay` process does not know its position in the chain; it only knows its input and output ports. This modularity allows for the dynamic scaling of processing pipelines without changing individual process logic.

### 2. Back-Pressure Propagation
Because `csp4cmsis` uses **Zero-Capacity Rendezvous Channels**, the `Sender` cannot send the $i^{th}$ message until the `Receiver` is ready to consume it at the other end of the chain. This creates a natural "back-pressure" that prevents any single relay from being overwhelmed, ensuring the entire network operates at the speed of the slowest component.

### 3. Static Network Execution
All processes and channels are declared as `static`, residing in the `.data` or `.bss` segments. This ensures that even a complex chain of 7 concurrent processes consumes a fixed, predictable amount of memory, satisfying safety-critical requirements for the **Cortex-M55**.

---

## 🚀 How to Run

### Prerequisites
* **Hardware:** Himax WE2 (Cortex-M55).
* **Library and RTOS:** CSP4CMSIS 2.0.1 on FreeRTOS 10.5.1 through the SDK's CMSIS-RTOS2 adapter (`OS_HAL := y`); the app starts the kernel with `osKernelInitialize()`/`osKernelStart()`.
* **Make environment** in `CSP4CMSIS/EPII_CM55M_APP_S/makefile` set `APP_TYPE = csp4cmsis_chain_test`.

### Expected UART Output
The console will display the initialization and the verification progress of the receiver. A successful test confirms that the rendezvous logic successfully propagated data across 6 different synchronization points per message.

```text
--- Launching CSP Relay Chain (SPN Principle) ---
[Sender] Starting stream...
[Receiver] Verified up to 100...
[Receiver] Verified up to 200...
...
[Receiver] Verified up to 1000...
[Receiver] SUCCESS: All 1000 values verified through 5 relays.
[Sender] Stream complete.
