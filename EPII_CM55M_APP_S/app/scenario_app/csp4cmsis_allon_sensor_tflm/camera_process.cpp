#include "camera_process.h"
#include "cisdp_cfg.h"
#include "WE2_debug.h"

using namespace csp;

// Frame-ready trigger from the sensor data path's interrupt to the Camera
// process. An interrupt cannot wait for a partner, so it cannot use a
// rendezvous channel: it writes via isrWriter() to a buffered channel. One
// slot is enough: Camera re-arms the capture (sensordplib_retrigger_capture)
// only after it has read the trigger, so at most one frame-ready can be
// pending, and the slot keeps it even if Camera is not waiting yet.
static BufferedChannel<trigger_t, 1> g_trigger_chan;

extern "C"
void os_app_dplib_cb(SENSORDPLIB_STATUS_E event) {
  // No print here in normal operation: xprintf() has no locking, and this
  // callback runs in interrupt context, where a mutex-based fix isn't an
  // option (you can't block on a mutex from an ISR). Calling it here can
  // tear another task's in-progress output mid-string.
  if (event == SENSORDPLIB_STATUS_XDMA_FRAME_READY) {
    if (!g_trigger_chan.isrWriter().putFromISR(trigger_t {})) {
      // A second frame-ready before Camera read the first, although Camera
      // re-arms only after reading: a driver bug. Stop here instead of
      // losing the frame silently (the old rendezvous dropped it, and the
      // camera then stopped for good). Polled UART output works with
      // interrupts disabled.
      __disable_irq();
      xprintf("\r\nFATAL: camera frame-ready trigger lost (the previous one was not read yet)\r\n");
      for (;;) { }
    }
  }
}

Camera::Camera(Chanout < frame_t > out, Chanout < report_t > report): m_frame_out(out), m_report_out(report), m_frame_counter(0) {}

// Camera does not print: it reports to the Reporter (the camera driver prints its own
// start-up log during cisdp_sensor_init() and cisdp_dp_init(); nothing else can print then:
// Inference waits for the first frame, and the Reporter has nothing to print yet).
void Camera::run() {
  trigger_t t;
  auto trigger_reader = g_trigger_chan.reader();
  report_t r = {};
  r.source = ReportSource::Camera;
  if (cisdp_sensor_init(true) < 0) {
    r.kind = ReportKind::Failed;
    r.code = 1;  // sensor initialisation
    m_report_out.write(r);
    return;
  }

  // An ISR that calls CSP4CMSIS or FreeRTOS must run at priority 5..7: at or
  // below CSP4CMSIS_MAX_SYSCALL_INTERRUPT_PRIORITY (5; 3 priority bits), so
  // that the RTOS's and the library's critical sections mask it. The SDK
  // leaves it at 0 (the highest). Measured on the board: the frame-ready
  // callback above (the only one that writes to a channel) is called from
  // SC_sen_nframe_end_IRQn. The data path's other interrupts (84, 143,
  // 154-157) and the NPU's make no RTOS or CSP4CMSIS calls and are left as
  // they are. Set before the data path is started.
  NVIC_SetPriority(SC_sen_nframe_end_IRQn, CSP4CMSIS_MAX_SYSCALL_INTERRUPT_PRIORITY);

  if (cisdp_dp_init(true,
      SENSORDPLIB_PATH_INT_INP_HW5X5_JPEG,
      os_app_dplib_cb,
      0,
      APP_DP_RES_YUV640x480_INP_SUBSAMPLE_1X) < 0) {
    r.kind = ReportKind::Failed;
    r.code = 2;  // data path initialisation
    m_report_out.write(r);
    return;
  }

  cisdp_sensor_start();
  r.kind = ReportKind::Started;
  m_report_out.write(r);

  while (true) {
    trigger_reader.read(t);

    uint32_t jpeg_addr, jpeg_sz;
    cisdp_get_jpginfo( & jpeg_sz, & jpeg_addr);

    frame_t f;
    f.index = m_frame_counter++;
    f.jpeg_addr = jpeg_addr;
    f.jpeg_sz = jpeg_sz;

    m_frame_out.write(f);
    sensordplib_retrigger_capture();
  }
}
