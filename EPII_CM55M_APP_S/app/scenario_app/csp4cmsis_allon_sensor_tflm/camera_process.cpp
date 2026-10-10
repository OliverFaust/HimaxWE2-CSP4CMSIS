#include "camera_process.h"
#include "cisdp_cfg.h"
#include "WE2_debug.h"

using namespace csp;

// Frame-ready trigger from the interrupt. One slot is enough: Camera re-arms the capture
// only after reading the trigger, so at most one frame-ready is ever pending.
static BufferedChannel<trigger_t, 1> g_trigger_chan;

extern "C"
void os_app_dplib_cb(SENSORDPLIB_STATUS_E event) {
  if (event == SENSORDPLIB_STATUS_XDMA_FRAME_READY) {
    if (!g_trigger_chan.isrWriter().putFromISR(trigger_t {})) {
      // A second frame-ready before the first was read: a driver bug. Stop rather than
      // lose the frame (the camera would never be re-armed).
      __disable_irq();
      xprintf("\r\nFATAL: camera frame-ready trigger lost (the previous one was not read yet)\r\n");
      for (;;) { }
    }
  }
}

Camera::Camera(Chanout<frame_t> out, Chanout<report_t> report)
    : m_frame_out(out), m_report_out(report), m_frame_counter(0) {}

void Camera::run() {
  trigger_t t;
  auto trigger_reader = g_trigger_chan.reader();
  report_t r = {};
  r.name = name();
  if (cisdp_sensor_init(true) < 0) {
    r.kind = ReportKind::Failed;
    r.code = 1;  // sensor initialisation
    m_report_out.write(r);
    return;
  }

  // The SDK leaves every interrupt at priority 0, above the RTOS's critical sections. This
  // one writes to a channel, so it must be at CSP4CMSIS_MAX_SYSCALL_INTERRUPT_PRIORITY or below.
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
    cisdp_get_jpginfo(&jpeg_sz, &jpeg_addr);

    frame_t f;
    f.index = m_frame_counter++;
    f.jpeg_addr = jpeg_addr;
    f.jpeg_sz = jpeg_sz;

    m_frame_out.write(f);
    sensordplib_retrigger_capture();  // only now can the next frame-ready come
  }
}
