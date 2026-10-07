# Test Scenario: Systolic Array Matrix Multiplication

## 📌 Overview
The `csp4cmsis_matrix_multiplication` scenario demonstrates a complex, multi-dimensional process network implementing a **Systolic Array**. It simulates a hardware-like parallel processing architecture where data "flows" through a grid of Processing Elements (PEs) to perform matrix multiplication ($C = A \times B$).

This test showcases the framework's ability to manage a high density of concurrent processes (21 in total) and their inter-dependencies, proving that `csp4cmsis` can orchestrate sophisticated parallel algorithms on the **Cortex-M55**.



---

## 🏗 Architecture

The system is organized as a 3x3 grid of Processing Elements, supported by "Feeders" that inject data and "Sinks" that consume the final output to maintain flow.

| Component | Quantity | Responsibility |
| :--- | :--- | :--- |
| **Feeder (Rows)** | 3 | Injects rows of Matrix A into the left side of the grid. |
| **Feeder (Cols)** | 3 | Injects columns of Matrix B into the top of the grid. |
| **Processing Element (PE)** | 9 | Performs the Multiply-Accumulate (MAC) operation and passes data Right/Down. |
| **Sink** | 6 | Consumes data at the right and bottom edges to prevent pipeline stalls. |

### The Data Flow
In each "pulse" of the system, a PE:
1.  **Input:** Reads a value from the left (Matrix A) and a value from the top (Matrix B).
2.  **Compute:** Multiplies the two values and adds them to its internal `accumulator`.
3.  **Output:** Forwards the A-value to the right neighbor and the B-value to the bottom neighbor.



---

## 🛠 Technical Details

### 1. Synchronous Pulse Orchestration
Because all channels use **Zero-Capacity Rendezvous**, the entire 3x3 grid is self-synchronizing. No PE can advance to Pulse $i+1$ until its neighbors have consumed the data from Pulse $i$. This eliminates the need for global barriers or complex mutex locks.

### 2. Static Grid Allocation
The network of 42 channels (`static Channel<int> h[3][4], v[4][3]`) and 21 processes is allocated entirely in static memory. This ensures that the high-concurrency model does not cause heap fragmentation or stack overflows during execution on the Cortex-M55.

### 3. Pipeline Staggering & Flushing
To align the correct row and column elements, the `Feeder` processes can "stagger" data entry using initial zeros. Once the multiplication is complete, the `Sink` processes ensure that every PE can finish its final `write` operation, preventing "hanging" processes at the edge of the array.

---

## 🚀 How to Run

### Prerequisites
* **Hardware:** Himax WE2 (Cortex-M55).
* **Library and RTOS:** CSP4CMSIS 3.0.0 on FreeRTOS 10.5.1 through the SDK's CMSIS-RTOS2 adapter (`OS_HAL := y`); the app starts the kernel with `osKernelInitialize()`/`osKernelStart()`. The 21 CSP threads and the launcher have static stacks.
* **Make environment** in `CSP4CMSIS/EPII_CM55M_APP_S/makefile` set `APP_TYPE = csp4cmsis_matrix_multiplication`.

### Expected UART Output
The test multiplies a 3x3 matrix $A$ by an Identity Matrix $I$, meaning the final accumulators in each PE should match the original values of Matrix $A$.

```text
--- Systolic Array 3x3: A * Identity ---
[PE 0,0] Pulse 0: In(1, 1) Accum: 1
[PE 1,1] Pulse 1: In(5, 1) Accum: 5
...
>>> [PE 0,0] COMPLETED. Final: 1
>>> [PE 1,1] COMPLETED. Final: 5
>>> [PE 2,2] COMPLETED. Final: 9
