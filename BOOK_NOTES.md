# Book notes

The source files deliberately contain no comments: the explanations are in the book, which refers to the code by line. This file keeps every comment removed from the book-facing source of the app `csp4cmsis_allon_sensor_tflm` (chapter 8) on 2026-10-12 (from commit `cfbb0a5`), so that nothing is lost.

For each file, in file order: where the comment was (line numbers before the removal), the comment itself, and the code it explains, numbered as in the source file now, i.e. as in the book listing.

## `EPII_CM55M_APP_S/app/scenario_app/csp4cmsis_allon_sensor_tflm/csp4cmsis_spn.cpp`

1. **Line 7**, at the end of the code line; explains listing line 7:

   ```cpp
   // StaticTask_t
   ```

   ```cpp
   7  #include "FreeRTOS.h"
   ```

2. **Lines 15–16**, above the code; explains listing lines 15–16:

   ```cpp
   // MainApp runs above the network: Run(..., StaticNetwork) creates all processes before any
   // runs, and a busy process cannot delay the stack report.
   ```

   ```cpp
   15  static constexpr osPriority_t MAIN_APP_PRIORITY = osPriorityLow3;
   16  static constexpr osPriority_t NETWORK_PRIORITY  = osPriorityLow2;
   ```

3. **Line 20**, above the code; explains listing lines 18–19:

   ```cpp
   // Static stack (1 KB; 464 bytes used) and control block: no heap.
   ```

   ```cpp
   18  alignas(8) static uint8_t mainAppStack[1024];
   19  static StaticTask_t mainAppControlBlock;
   ```

4. **Line 46**, at the end of the code line; explains listing line 43:

   ```cpp
   // writers: Camera, Inference, MainApp
   ```

   ```cpp
   43  static Channel<report_t> report_chan;
   ```

5. **Line 52**, at the end of the code line; explains listing line 49:

   ```cpp
   // kept for forEachProcess()
   ```

   ```cpp
   49  auto network = InParallel(camera, inference, reporter);
   ```

6. **Lines 55–56**, above the code; explains listing lines 52–55 (the first lines of the block that follows):

   ```cpp
   // MainApp is a plain CMSIS-RTOS2 thread, yet it may write to a rendezvous channel.
   // It never prints: its stack report goes to the Reporter like every other report.
   ```

   ```cpp
   52      Chanout<report_t> report_out = report_chan.writer();
   53      while (true) {
   54          SleepFor(Milliseconds(CSP_STACK_REPORT_INTERVAL_MS));
   55          network.forEachProcess([&](CSProcess& p) {
   ```

## `EPII_CM55M_APP_S/app/scenario_app/csp4cmsis_allon_sensor_tflm/camera_process.cpp`

1. **Lines 7–8**, above the code; explains listing line 7:

   ```cpp
   // Frame-ready trigger from the interrupt. One slot is enough: Camera re-arms the capture
   // only after reading the trigger, so at most one frame-ready is ever pending.
   ```

   ```cpp
   7  static BufferedChannel<trigger_t, 1> g_trigger_chan;
   ```

2. **Lines 15–16**, above the code; explains listing lines 13–15:

   ```cpp
   // A second frame-ready before the first was read: a driver bug. Stop rather than
   // lose the frame (the camera would never be re-armed).
   ```

   ```cpp
   13        __disable_irq();
   14        xprintf("\r\nFATAL: camera frame-ready trigger lost (the previous one was not read yet)\r\n");
   15        for (;;) { }
   ```

3. **Line 34**, at the end of the code line; explains listing line 30:

   ```cpp
   // sensor initialisation
   ```

   ```cpp
   30  r.code = 1;
   ```

4. **Lines 39–40**, above the code; explains listing line 35:

   ```cpp
   // The SDK leaves every interrupt at priority 0, above the RTOS's critical sections. This
   // one writes to a channel, so it must be at CSP4CMSIS_MAX_SYSCALL_INTERRUPT_PRIORITY or below.
   ```

   ```cpp
   35    NVIC_SetPriority(SC_sen_nframe_end_IRQn, CSP4CMSIS_MAX_SYSCALL_INTERRUPT_PRIORITY);
   ```

5. **Line 49**, at the end of the code line; explains listing line 43:

   ```cpp
   // data path initialisation
   ```

   ```cpp
   43  r.code = 2;
   ```

6. **Line 70**, at the end of the code line; explains listing line 64:

   ```cpp
   // only now can the next frame-ready come
   ```

   ```cpp
   64  sensordplib_retrigger_capture();
   ```

## `EPII_CM55M_APP_S/app/scenario_app/csp4cmsis_allon_sensor_tflm/camera_process.h`

1. **Line 8**, above the code; explains listing lines 8–11 (the first lines of the block that follows):

   ```cpp
   // 384 words = 1.5 KB; 768 bytes used (measured).
   ```

   ```cpp
    8  class Camera : public csp::CSProcessStatic<384> {
    9  public:
   10      Camera(csp::Chanout<frame_t> out, csp::Chanout<report_t> report);
   11      void run() override;
   ```

## `EPII_CM55M_APP_S/app/scenario_app/csp4cmsis_allon_sensor_tflm/inference_process.cpp`

1. **Line 2**, at the end of the code line; explains listing line 2:

   ```cpp
   // for cv_init, cv_run
   ```

   ```cpp
   2  #include "cvapp.h"
   ```

2. **Lines 11–12**, above the code; explains listing lines 11–12:

   ```cpp
   // The model is initialised only after the first frame, i.e. after Camera has started, so
   // that nothing is reported while the camera driver prints its start-up log.
   ```

   ```cpp
   11      frame_t f;
   12      m_frame_in.read(f);
   ```

3. **Line 30**, above the code; explains listing lines 28–29:

   ```cpp
   // cv_run() reads the raw sensor buffer, not the JPEG.
   ```

   ```cpp
   28          int8_t person_score = 0, no_person_score = 0;
   29          int status = cv_run(&person_score, &no_person_score);
   ```

## `EPII_CM55M_APP_S/app/scenario_app/csp4cmsis_allon_sensor_tflm/inference_process.h`

1. **Line 7**, above the code; explains listing lines 7–10 (the first lines of the block that follows):

   ```cpp
   // 256 words = 1 KB; 488 bytes used (measured).
   ```

   ```cpp
    7  class Inference : public csp::CSProcessStatic<256> {
    8  public:
    9      Inference(csp::Chanin<frame_t> in, csp::Chanout<report_t> report);
   10      void run() override;
   ```

## `EPII_CM55M_APP_S/app/scenario_app/csp4cmsis_allon_sensor_tflm/reporter_process.cpp`

1. **Line 1**: file header, naming the file; explains no particular line.

   ```cpp
   // reporter_process.cpp
   ```

2. **Line 11**, above the code; explains listing lines 10–13 (the first lines of the block that follows):

   ```cpp
   // The only process that prints while the network runs: xprintf() has no locking.
   ```

   ```cpp
   10  void Reporter::run()
   11  {
   12      while (true) {
   13          report_t r;
   ```

## `EPII_CM55M_APP_S/app/scenario_app/csp4cmsis_allon_sensor_tflm/reporter_process.h`

1. **Line 5**, at the end of the code line; explains listing line 5:

   ```cpp
   // for report_t
   ```

   ```cpp
   5  #include "common_types.h"
   ```

2. **Line 7**, above the code; explains listing lines 7–10 (the first lines of the block that follows):

   ```cpp
   // Prints each report as one line. 256 words = 1 KB; about 450 bytes used (measured).
   ```

   ```cpp
    7  class Reporter : public csp::CSProcessStatic<256> {
    8  public:
    9      explicit Reporter(csp::Chanin<report_t> in);
   10      void run() override;
   ```

3. **Line 18**, at the end of the code line; explains listing line 17:

   ```cpp
   // REPORTER_PROCESS_H
   ```

   ```cpp
   17  #endif
   ```

## `EPII_CM55M_APP_S/app/scenario_app/csp4cmsis_allon_sensor_tflm/common_types.h`

1. **Line 1**: file header, naming the file; explains no particular line.

   ```cpp
   // common_types.h
   ```

2. **Line 10**, above the code; explains listing lines 9–12:

   ```cpp
   // Describes a frame; the frame data itself stays in the sensor's buffer.
   ```

   ```cpp
    9  struct frame_t {
   10      uint32_t index;
   11      uint32_t jpeg_addr;
   12      uint32_t jpeg_sz;
   ```

3. **Line 18**, at the end of the code line; explains listing line 16:

   ```cpp
   // initialised and running
   ```

   ```cpp
   16  Started,
   ```

4. **Line 19**, at the end of the code line; explains listing line 17:

   ```cpp
   // initialisation failed; code says which step
   ```

   ```cpp
   17  Failed,
   ```

5. **Line 20**, at the end of the code line; explains listing line 18:

   ```cpp
   // one frame's classification
   ```

   ```cpp
   18  Result,
   ```

6. **Line 21**, at the end of the code line; explains listing line 19:

   ```cpp
   // one thread's stack use (sent by MainApp every 3 s)
   ```

   ```cpp
   19  Stack,
   ```

7. **Line 24**, above the code; explains listing lines 22–25 (the first lines of the block that follows):

   ```cpp
   // Everything the Reporter prints arrives as a report_t.
   ```

   ```cpp
   22  struct report_t {
   23      ReportKind  kind;
   24      int16_t     code;
   25      const char* name;
   ```

8. **Line 27**, at the end of the code line; explains listing line 24:

   ```cpp
   // Failed: the failing step; Result: 0 = ok, otherwise Invoke() failed
   ```

   ```cpp
   24  int16_t     code;
   ```

9. **Line 28**, at the end of the code line; explains listing line 25:

   ```cpp
   // the reporting thread's name: a string literal, so only the pointer is copied
   ```

   ```cpp
   25  const char* name;
   ```

10. **Line 29**, at the end of the code line; explains listing line 26:

   ```cpp
   // Result: the frame index
   ```

   ```cpp
   26  uint32_t    index;
   ```

11. **Lines 30–31**, at the end of the code line; explains listing line 27:

   ```cpp
   // Result: person score, no-person score, unused
   // Stack:  used bytes, allocated bytes, HWM words (-1: unavailable)
   ```

   ```cpp
   27  int32_t     value[3];
   ```

12. **Line 35**, at the end of the code line; explains listing line 31:

   ```cpp
   // COMMON_TYPES_H
   ```

   ```cpp
   31  #endif
   ```
