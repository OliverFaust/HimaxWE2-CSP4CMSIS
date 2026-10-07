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
* **Start-up order:** Inference initialises the model only when its first frame has arrived, i.e. after Camera has started.

### 4. Reporter: the console has one owner
The console is a shared resource, and `xprintf()` has no locking, so two processes printing at the same time tear each other's lines. The **Reporter** is therefore the only process that prints while the network runs. Camera and Inference send it fixed-size `report_t` messages (`common_types.h`: kind, source, code, frame index, values) over **one rendezvous channel with two writers**; the Reporter owns every format string and prints exactly one line per frame, plus a stack report every 3 s.
* **Rendezvous, not buffered:** nothing is lost, and the cost is small: at 921 600 Bd a result line takes about 0.5 ms, against 51 ms per frame (19.6 frames/s, measured unchanged). Camera reports only at start-up, so its frame loop never waits for the console. A `KeepNewest` buffer would drop reports silently.
* **Before the Reporter's first line**, only the camera driver prints (its start-up log, during `cisdp_sensor_init()`/`cisdp_dp_init()`): Inference is still waiting for the first frame, and MainApp has printed its line and ended before the network runs. The frame-ready ISR's `FATAL` message is the one exception: it halts the system.

### 5. Memory & Performance
* **Zero Heap:** All CSP channels and processes, and every thread's stack, are statically allocated at compile time; the FreeRTOS heap is not used (`configTOTAL_HEAP_SIZE` 1 KB, 0 allocations measured).
* **Concurrency:** Each process runs in its own thread (`osPriorityLow2`), created by `Run(..., ExecutionMode::StaticNetwork)` from `MainApp_Task` (`osPriorityLow3`).
* **Console output:** one line per frame, printed by the Reporter only (before, each result was printed twice, by Inference and by a Console process, and lines from different processes interleaved mid-string).

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
    // ... sensor initialisation; on failure: report Failed and return ...
    m_report_out.write(report_t{ReportKind::Started, ReportSource::Camera});

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
    frame_t f;
    m_frame_in.read(f);                              // First frame: Camera has started

    report_t r = {};
    r.source = ReportSource::Inference;
    int err = cv_init(true, true);                   // Initialise NPU and model
    // ... on failure: report Failed (code = err) and return; otherwise report Started ...

    while (true) {
        int8_t person_score, no_person_score;
        int status = cv_run(&person_score, &no_person_score);   // Run NPU inference

        r = {};
        r.kind = ReportKind::Result;                 // One report per frame to the Reporter
        r.source = ReportSource::Inference;
        r.code = status;
        r.index = f.index;
        r.value[0] = person_score;
        r.value[1] = no_person_score;
        m_report_out.write(r);

        m_frame_in.read(f);                          // Wait for the next frame
    }
}
```
### Network Construction (`csp4cmsis_spn.cpp`)
```cpp
void MainApp_Task(void* params) {
    static Channel<frame_t>  frame_chan;      // unbuffered
    static Channel<report_t> report_chan;     // unbuffered; writers: Camera, Inference

    static Camera    camera(frame_chan.writer(), report_chan.writer());
    static Inference inference(frame_chan.reader(), report_chan.writer());
    static CSProcess* const reported[] = { &camera, &inference };   // for the stack report
    static Reporter  reporter(report_chan.reader(), reported, 2);

    Run(InParallel(camera, inference, reporter), ExecutionMode::StaticNetwork, NETWORK_PRIORITY);

    xprintf("*** MainApp_Task: network started. Terminating. ***\r\n");
    osThreadExit();                                  // the processes run on their own
}
```

## 📊 Stack Occupancy Reporting

The Reporter prints the stack report, since it owns the console: after a report, once every `CSP_STACK_REPORT_INTERVAL_MS` (default 3000 ms, overridable at compile time), it prints each process's allocated stack, used bytes, unused headroom and HWM in words (Camera, Inference, then itself). If a process doesn't expose a HWM, this is reported as unavailable rather than guessed at. `MainApp_Task` (static 2 KB stack, `CSP_Main`) ends after starting the network and is no longer reported.

Because camera/inference/reporter all run forever, there's no natural "network finished" point to take a single reading at -- these are *live, worst-observed-so-far* readings, and are only trustworthy once each process's deepest call path has actually been exercised (e.g. after error/edge-case branches in inference or the reporter have run at least once).

### Sample Output
```text
Frame 113: prediction = -13
Frame 114: prediction = -12
Camera: 760/1536 bytes used (776 bytes unused headroom, 194 words HWM)
Inference: 480/1024 bytes used (544 bytes unused headroom, 136 words HWM)
Reporter: 408/1024 bytes used (616 bytes unused headroom, 154 words HWM)
Frame 115: prediction = -12
```

| Task | Allocated | Used | Unused Headroom |
|---|---|---|---|
| Camera | 1536 bytes | 760 bytes | 776 bytes |
| Inference | 1024 bytes | 480 bytes | 544 bytes |
| Reporter | 1024 bytes | 408 bytes | 616 bytes |

Camera uses 760 bytes (744 before it sent reports); before 2.0 it had only 1024 bytes (280 bytes of headroom), since CSP4CMSIS 2.0.1 it has 1536 bytes (384 words). Inference and the Reporter have comfortable margins, despite Inference being the process that drives the Ethos‑U55 NPU call.

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
*** MainApp_Task: network started. Terminating. ***
cis_IMX219_init
...                      (the camera driver's start-up log)
IMX219 on by app done
g_cursensorstream: 0
Camera: started
Inference: started
Frame 0: prediction = -14
Frame 1: prediction = -12
...
Camera: 760/1536 bytes used (776 bytes unused headroom, 194 words HWM)
Inference: 480/1024 bytes used (544 bytes unused headroom, 136 words HWM)
Reporter: 408/1024 bytes used (616 bytes unused headroom, 154 words HWM)
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
├── reporter_process.h      // Reporter process declaration
├── reporter_process.cpp    // Reporter: the only process that prints (reports, stack report)
├── common_types.h          // Shared structs (frame_t, report_t)
├── csp4cmsis_spn.cpp       // Network construction & Main task
└── app.mk                  // Makefile source list
```

## 🐛 Troubleshooting
* No "Frame ready IRQ"Hardware InitVerify cisdp_sensor_start() returns 0 and check sensor cables.
* `FATAL: camera frame-ready trigger lost` — a second frame-ready arrived before Camera read the first, although Camera re-arms only after reading: check the data-path driver.
* `IMX219 off by app fail` / `Camera: initialisation FAILED (step 1)` (I2C error -60 at start-up) — the camera module keeps its state across a WE2 reset; seen intermittently with both the pre-2.0 and the 2.0.1 build. Run the app again (or flash a non-camera app first).
* Pipeline stallsMissing RetriggerEnsure sensordplib_retrigger_capture() is called at the end of the camera loop.
* Memory OverrunBuffer sizeIf using BufferedChannel, ensure the size is sufficient for your FPS.
* Stack overflow / corruptionTask stack too smallCheck the periodic stack report (see [Stack Occupancy Reporting](#-stack-occupancy-reporting)); if a process's unused headroom is trending toward 0, increase its `CSProcessStatic<N>` size.

## 📝 License
This example is provided under the standard Himax SDK license terms. Refer to the top‑level license file in the SDK for details.
