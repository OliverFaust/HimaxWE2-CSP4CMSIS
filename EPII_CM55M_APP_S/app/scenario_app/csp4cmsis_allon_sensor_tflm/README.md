# CSP-based Person Detection on Himax WE2

This project implements a robust, lossless image processing pipeline using **Communicating Sequential Processes (CSP)** patterns on the Himax WE2 (Grove Vision AI V2) hardware. It uses CSP4CMSIS 3.0.0 on FreeRTOS 10.5.1, through the SDK's CMSIS-RTOS2 adapter (`OS_HAL := y`; the kernel is started with `osKernelInitialize()`/`osKernelStart()`), and the Ethos-U55 NPU to perform real-time person detection.



## 🏗 Architecture Overview

The system is designed as a **Static Network** of independent processes communicating via synchronous, zero-copy channels.

### 1. Camera Handshake (ISR to Process)
To ensure no frames are dropped or partially read, the system uses a private trigger channel:
* **The ISR:** the sensor data path calls `os_app_dplib_cb` from its frame-end interrupt (`SC_sen_nframe_end_IRQn`, measured on the board). On `SENSORDPLIB_STATUS_XDMA_FRAME_READY` it writes a trigger to a one-slot `BufferedChannel<trigger_t, 1>` through `isrWriter().putFromISR()`.
* **Why not a rendezvous channel:** a rendezvous completes only when writer and reader meet, so the writer must be able to wait for its partner. An interrupt cannot wait, so CSP4CMSIS gives rendezvous channels no ISR writer at all. Before 2.0 the ISR used `putFromISR()` on a rendezvous anyway; when the Camera process was not already waiting, the trigger was simply dropped -- and since Camera re-arms the capture only after a trigger, the camera then stopped for good. The one-slot buffer keeps the trigger until Camera reads it.
* **One slot is enough:** Camera re-arms the capture only after it has read the trigger, so at most one frame-ready can be pending. If a write ever fails, a second frame-ready arrived before the first was read (a driver bug): the callback prints `FATAL: camera frame-ready trigger lost ...` and halts instead of losing the frame silently.
* **Interrupt priority:** an interrupt whose handler calls CSP4CMSIS or FreeRTOS must run at priority 5..7 (`CSP4CMSIS_MAX_SYSCALL_INTERRUPT_PRIORITY` = 5, 3 priority bits); the SDK leaves every interrupt at 0. `Camera::run()` sets `SC_sen_nframe_end_IRQn` to 5 before the data path starts. The data path's other interrupts (84, 143, 154-157) and the NPU's make no RTOS or CSP4CMSIS calls and stay as they are.
* **The Process:** the Camera process blocks on this trigger, ensuring a lossless, synchronized handshake between hardware and software.

### 2. Frame Re-triggering
To prevent buffer overruns and keep the pipeline in lockstep, the Camera process explicitly calls `sensordplib_retrigger_capture()` only **after** the current frame has been successfully passed to the inference stage. This creates natural back-pressure.

### 3. Model Inference
The inference process utilizes the `cvapp` module from the Himax SDK:
* **NPU:** Initialises the Ethos‑U55.
* **Model:** Loads a specialized person‑detection TFLM model.
* **Data Path:** Runs inference on raw YUV frames (accessed via `app_get_raw_addr()`).

### 4. Memory & Performance
* **Zero Heap:** All CSP channels and processes, and every thread's stack, are statically allocated at compile time; the FreeRTOS heap is not used (`configTOTAL_HEAP_SIZE` 1 KB, 0 allocations measured).
* **Concurrency:** Each process runs in its own thread (`osPriorityLow2`), created by `Run(..., ExecutionMode::StaticNetwork)` from `MainApp_Task` (`osPriorityLow3`).
* **Console output:** each result is printed twice by design -- by Inference (`dbg_printf`, debug level) and by Console (`xprintf`) -- and lines from different processes can interleave mid-string, because `xprintf()` has no locking (e.g. `Frame 114: prediction = -Frame 114: prediction = -94`). Both are unchanged from before 2.0.

---

## 🔧 Key Code Snippets

### Camera Process (`camera_process.cpp`)
```cpp
static BufferedChannel<trigger_t, 1> g_trigger_chan;

extern "C" void os_app_dplib_cb(SENSORDPLIB_STATUS_E event) {
    if (event == SENSORDPLIB_STATUS_XDMA_FRAME_READY) {
        // Interrupt context: write through the ISR end of a buffered channel
        if (!g_trigger_chan.isrWriter().putFromISR(trigger_t{})) {
            __disable_irq();
            xprintf("\r\nFATAL: camera frame-ready trigger lost ...\r\n");
            for (;;) { }
        }
    }
}

void Camera::run() {
    auto trigger_reader = g_trigger_chan.reader();
    // ... sensor initialisation ...

    while (true) {
        trigger_t t;
        trigger_reader.read(t);                      // Block until ISR fires

        uint32_t jpeg_addr, jpeg_sz;
        cisdp_get_jpginfo(&jpeg_sz, &jpeg_addr);

        frame_t f = { m_frame_counter++, jpeg_addr, jpeg_sz };
        m_frame_out.write(f);                        // Send to inference (blocks if busy)

        sensordplib_retrigger_capture();             // Acknowledge and allow next capture
    }
}
```

### Inference Process (`inference_process.cpp`)
```cpp
void Inference::run() {
    if (cv_init(true, true) < 0) return;             // Initialise NPU

    while (true) {
        frame_t f;
        m_frame_in.read(f);                          // Wait for frame from Camera

        int8_t score = cv_run();                     // Run NPU inference
        
        result_t res = { f.index, score };
        m_result_out.write(res);                     // Send result to Console
    }
}
```
### Network Construction (`csp4cmsis_spn.cpp`)
```cpp
void MainApp_Task(void* params) {
    static Channel<frame_t>  frame_chan;
    static Channel<result_t> result_chan;

    static Camera    camera(frame_chan.writer());
    static Inference inference(frame_chan.reader(), result_chan.writer());
    static Console   console(result_chan.reader());

    // Kept as a named object -- ParallelHelper still holds references to
    // camera/inference/console after Run() returns, which the stack
    // reporting loop below needs.
    auto network = InParallel(camera, inference, console);
    Run(network, ExecutionMode::StaticNetwork, NETWORK_PRIORITY);

    // camera/inference/console each run forever, so there's no natural
    // "network finished" point -- instead, MainApp_Task periodically
    // walks the network and reports FreeRTOS stack high-water-mark
    // usage for every process, plus its own.
    while (true) {
        SleepFor(Milliseconds(CSP_STACK_REPORT_INTERVAL_MS));
        // ... report CSP_Main HWM, then network.forEachProcess(...) ...
    }
}
```

## 📊 Stack Occupancy Reporting

`MainApp_Task` isn't a `CSProcess` itself, so it isn't sized via `CSProcessStatic<N>` -- its stack is allocated explicitly (`mainAppStack`, 2048 bytes) and given to `osThreadNew` along with a static control block.

Once the network is started, `MainApp_Task` becomes a monitoring loop: every `CSP_STACK_REPORT_INTERVAL_MS` (default 3000 ms, overridable at compile time) it:

* Reads its own unused stack via `osThreadGetStackSpace()` and reports `CSP_Main`'s usage.
* Calls `network.forEachProcess(...)` to walk every process in the static network and report each one's allocated stack, used bytes, unused headroom, and HWM in words. If a process doesn't expose a HWM, this is reported as unavailable rather than guessed at.

Because camera/inference/console all run forever, there's no natural "network finished" point to take a single reading at -- these are *live, worst-observed-so-far* readings, and are only trustworthy once each process's deepest call path has actually been exercised (e.g. after error/edge-case branches in inference or console have run at least once).

### Sample Output
```text
invoke pass
person_score:-37
Frame 114: prediction = -Frame 114: prediction = -94
94
CSP_Main: 560/2048 bytes used (1488 bytes unused headroom)
Camera: 744/1536 bytes used (792 bytes unused headroom, 198 words HWM)
Inference: 472/1024 bytes used (552 bytes unused headroom, 138 words HWM)
Console: 360/1024 bytes used (664 bytes unused headroom, 166 words HWM)
Camera: retrigger hardware for next frame
```

| Task | Allocated | Used | Unused Headroom |
|---|---|---|---|
| CSP_Main | 2048 bytes | 560 bytes | 1488 bytes |
| Camera | 1536 bytes | 744 bytes | 792 bytes |
| Inference | 1024 bytes | 472 bytes | 552 bytes |
| Console | 1024 bytes | 360 bytes | 664 bytes |

Camera uses 744 bytes, as before 2.0, when it had only 1024 bytes (280 bytes of headroom); with CSP4CMSIS 2.0.1 it has 1536 bytes (384 words). Inference and Console have comfortable margins, despite Inference being the process that drives the Ethos‑U55 NPU call.

## 🚀 How to Run
### Prerequisites

* **Hardware:** Himax WE2‑based board (Grove Vision AI Module V2).
* **Sensor:** IMX219 Camera Module.
* **Toolchain:** ARM GNU Toolchain (13.2.Rel1 or later).
* **Build system:** Himax WE2 SDK.

### Build Instructions
1. Navigate to the application directory:
```
CSP4CMSIS/EPII_CM55M_APP_S
```
2. Set the application type in the `makefile`:
```
APP_TYPE=csp4cmsis_allon_sensor_tflm
```
3. Build the project:
```
make clean 
make
```
4. Generate the image and flash it over the USB serial port with xmodem, as described in the top-level README.

### Expected UART Output
```text
Camera: initializing sensor
Ethos-U55 device initialised
model's schema version 3
initial done
...
IMX219 on by app done
Camera: retrigger hardware for next frame
invoke pass
person_score:-40
Frame 0: prediction = -40
Frame 0: prediction = -40
...
CSP_Main: 560/2048 bytes used (1488 bytes unused headroom)
Camera: 744/1536 bytes used (792 bytes unused headroom, 198 words HWM)
Inference: 472/1024 bytes used (552 bytes unused headroom, 138 words HWM)
Console: 360/1024 bytes used (664 bytes unused headroom, 166 words HWM)
...
```
Stack occupancy lines like the block above are printed every `CSP_STACK_REPORT_INTERVAL_MS` (3 s by default) once the network is running -- see [Stack Occupancy Reporting](#-stack-occupancy-reporting) below.

## 📁 File Structure
```text
app/scenario_app/csp4cmsis_allon_sensor_tflm/
├── camera_process.h        // Camera process declaration
├── camera_process.cpp      // Camera implementation + ISR handling
├── inference_process.h     // Inference process declaration
├── inference_process.cpp   // Inference implementation (Ethos-U55)
├── console_process.h       // Console process declaration
├── console_process.cpp     // Console implementation (UART output)
├── common_types.h          // Shared structs (frame_t, result_t)
├── csp4cmsis_spn.cpp       // Network construction & Main task
└── app.mk                  // Makefile source list
```

## 🐛 Troubleshooting
* No "Frame ready IRQ"Hardware InitVerify cisdp_sensor_start() returns 0 and check sensor cables.
* `FATAL: camera frame-ready trigger lost` — a second frame-ready arrived before Camera read the first, although Camera re-arms only after reading: check the data-path driver.
* `IMX219 off by app fail` / `Camera: sensor init failed` (I2C error -60 at start-up) — the camera module keeps its state across a WE2 reset; seen intermittently with both the pre-2.0 and the 2.0.1 build. Run the app again (or flash a non-camera app first).
* Pipeline stallsMissing RetriggerEnsure sensordplib_retrigger_capture() is called at the end of the camera loop.
* Memory OverrunBuffer sizeIf using BufferedChannel, ensure the size is sufficient for your FPS.
* Stack overflow / corruptionTask stack too smallCheck the periodic stack report (see [Stack Occupancy Reporting](#-stack-occupancy-reporting)); if a process's unused headroom is trending toward 0, increase its `CSProcessStatic<N>` size (or `MAIN_APP_STACK_WORDS` for `CSP_Main`).

## 📝 License
This example is provided under the standard Himax SDK license terms. Refer to the top‑level license file in the SDK for details.
