# Test Scenario: Dining Philosophers (Deadlock Simulation)

## 📌 Overview
The `csp4cmsis_dining_philosophers` scenario implements the classic concurrency problem designed by Edsger Dijkstra. Unlike previous tests that demonstrate success and throughput, this scenario is specifically engineered to demonstrate **Deadlock**—a state where every process is waiting for a resource held by another, causing the entire system to halt.

This test validates the framework's strict adherence to **Synchronous Rendezvous** semantics. In `csp4cmsis`, a deadlock is not a library "crash" but a formal state of the process network where no further transitions are possible, proving that the synchronization primitives correctly enforce mutual exclusion.



---

## 🏗 Architecture

The system consists of 10 concurrent processes (5 Philosophers and 5 Forks) arranged in a circular dependency graph.

| Component | Quantity | Responsibility |
| :--- | :--- | :--- |
| **Philosopher** | 5 | Alternates between "Thinking" and "Eating". To eat, a philosopher must pick up both adjacent forks. |
| **Fork** | 5 | Acts as a shared resource. It can only be "picked up" (rendezvous on `pick_up`) and then "put down" (rendezvous on `put_down`). |

### The Circular Dependency
Each Philosopher $i$ competes for:
1.  **Left Fork:** `fork[i]`
2.  **Right Fork:** `fork[(i+1) % 5]`

---

## 🛠 Technical Details

### 1. Resource Contention via Rendezvous
In this model, a `Fork` is not a passive variable or a mutex; it is a **Process**. Picking up a fork requires a synchronous handshake between the Philosopher and the Fork process. If the Fork is currently "busy" (waiting for a `put_down` signal from another philosopher), the requesting philosopher blocks on the `pick_up` channel.

### 2. The Anatomy of a Deadlock
This specific implementation induces a deadlock by having all philosophers follow the same resource acquisition order:
1.  All Philosophers become hungry.
2.  Each Philosopher successfully picks up their **Left** fork.
3.  Every Philosopher then attempts to pick up their **Right** fork.
4.  Since every Right fork is already held as a Left fork by a neighbor, every process blocks indefinitely.



### 3. Static Resource Safety
Despite the system reaching a halted state, the **Zero-Heap** philosophy ensures that no memory leaks occur. The processes remain in a blocked state within the FreeRTOS scheduler, and the internal state of the `csp4cmsis` channels remains consistent and inspectable via a debugger.

---

## 🚀 How to Run

### Prerequisites
* **Hardware:** Himax WE2 (Cortex-M55).
* **Library and RTOS:** CSP4CMSIS 2.0.1 on FreeRTOS 10.5.1 through the SDK's CMSIS-RTOS2 adapter (`OS_HAL := y`); the app starts the kernel with `osKernelInitialize()`/`osKernelStart()`. A serial terminal shows the trace.
* **Make environment** in `CSP4CMSIS/EPII_CM55M_APP_S/makefile` set `APP_TYPE = csp4cmsis_dining_philosophers`.

### Expected UART Output
The console will show philosophers thinking and eating for a short duration. Eventually, the output will stop completely once the "Circular Wait" condition is met.

```text
=== CSP4CMSIS Dining Philosophers Started ===
Expected behavior: A few eat, then a total system deadlock.

Phil 0: Thinking for 42 ms...
Phil 2: Hungry! Picking up LEFT fork...
Phil 2: EATING!
Phil 0: Hungry! Picking up LEFT fork...
...
Phil 4: Hungry! Picking up LEFT fork...
Phil 0: Picking up RIGHT fork... (Blocks)
Phil 1: Picking up RIGHT fork... (Blocks)
[Output Ceases - Deadlock Reached]
