# Test Scenario: Asymmetric Philosophers (Liveness & Deadlock Avoidance)

## 📌 Overview
The `csp4cmsis_asymmetric_philosophers` scenario provides the solution to the deadlock problem demonstrated in the previous "Dining Philosophers" test. It serves as a proof of **Liveness** within the `csp4cmsis` framework, showing that strategic process design can eliminate circular dependencies while maintaining strict synchronous rendezvous.

By introducing an **Asymmetric Actor**, we break the symmetry required for a "Circular Wait" condition. This ensures that the process network can continue to transition infinitely, even under heavy resource contention on the **Cortex-M55**.



---

## 🏗 Architecture

The network consists of 5 Fork processes and 5 Philosopher processes, but one philosopher is "left-handed" (asymmetric).

| Component | Quantity | Logic |
| :--- | :--- | :--- |
| **Philosopher (Standard)** | 4 | Tries to pick up the **LEFT** fork first, then the **RIGHT**. |
| **AsymmetricPhilosopher** | 1 | Tries to pick up the **RIGHT** fork first, then the **LEFT**. |
| **Fork** | 5 | Standard resource process (Wait for `pick_up`, then wait for `put_down`). |

### Breaking the Cycle
In the standard version, every philosopher reaches for their left fork simultaneously, creating a cycle. In this version, Philosopher 4 reaches for the same fork as Philosopher 0 (Fork 0) as their *first* action. This ensures that one of them will always be blocked *before* they can hold a resource, leaving a fork free for another philosopher to complete their pair and eat.



---

## 🛠 Technical Details

### 1. Breaking Symmetry
Symmetry is often the enemy of concurrency. By changing the acquisition order for just one process (`p4`), we ensure that $N$ philosophers cannot simultaneously hold $N$ forks. This is a classic example of **Formal Verification** principles applied to CSP.

### 2. Random Thinking Delays
The test uses `std::srand` and `SleepFor` to simulate non-deterministic behavior. This stress-tests the framework’s ability to handle asynchronous requests and ensures that the lack of deadlock isn't just a result of "lucky" timing, but a result of sound architectural design.

### 3. Execution Stability
The test uses `Run(InParallel(...))` in its default mode. Because all processes are declared `static`, the memory footprint is constant. This allows the test to run for days or weeks without any degradation in performance or memory leakage.

---

## 🚀 How to Run

### Prerequisites
* **Hardware:** Himax WE2 (Cortex-M55).
* **Library and RTOS:** CSP4CMSIS 3.0.0 on FreeRTOS 10.5.1 through the SDK's CMSIS-RTOS2 adapter (`OS_HAL := y`); the app starts the kernel with `osKernelInitialize()`/`osKernelStart()`.
* **Make environment** in `CSP4CMSIS/EPII_CM55M_APP_S/makefile` set `APP_TYPE = csp4cmsis_asymmetric_philosophers`.

### Expected UART Output
Unlike the previous test, the output should **never stop**. You will see a continuous stream of philosophers thinking, eating, and releasing forks.

```text
=== CSP4CMSIS Asymmetric Philosophers (Liveness Test) ===
This test should run infinitely without deadlocking.

Phil 0: Thinking for 84 ms...
Phil 4: Picking up RIGHT fork...
Phil 4: Hungry! Picking up LEFT fork...
Phil 4: EATING!
Phil 2: Hungry! Picking up LEFT fork...
...
[Output continues indefinitely]
