#include "camera_process.h"
#include "cisdp_cfg.h"
#include "WE2_debug.h"
#include "WE2_device.h"
#include <string.h>

using namespace csp;

#ifdef UPLINK_STAGE0
static constexpr uint32_t STAGE0_FRAMES = 100;

enum : int32_t {
  CHECK_INFO_ADDR = 1,
  CHECK_HW_ADDR   = 2,
  CHECK_SOI       = 4,
  CHECK_EOI       = 8,
  CHECK_ALL       = 15,
};

static void arm_jpeg_buf(uint8_t id) {
  uint8_t* p = (uint8_t*)cisdp_get_jpeg_buf_addr(id);
  memset(p, 0, 32);
  SCB_CleanInvalidateDCache_by_Addr(p, 32);
  cisdp_set_jpeg_buf(id);
}

static int32_t check_jpeg_buf(uint8_t id, uint32_t jpeg_addr, uint32_t hw_addr, uint32_t jpeg_sz) {
  uint32_t buf = cisdp_get_jpeg_buf_addr(id);
  const uint8_t* p = (const uint8_t*)buf;
  SCB_InvalidateDCache_by_Addr((void*)p, cisdp_get_jpeg_buf_size());
  int32_t flags = 0;
  if (jpeg_addr == buf) flags |= CHECK_INFO_ADDR;
  if (hw_addr == buf) flags |= CHECK_HW_ADDR;
  if (p[0] == 0xFF && p[1] == 0xD8) flags |= CHECK_SOI;
  if (jpeg_sz >= 8 && jpeg_sz <= cisdp_get_jpeg_buf_size()) {
    for (uint32_t i = jpeg_sz - 2; i + 5 >= jpeg_sz; i--) {
      if (p[i] == 0xFF && p[i + 1] == 0xD9) { flags |= CHECK_EOI; break; }
    }
  }
  return flags;
}
#endif

static BufferedChannel<trigger_t, 1> g_trigger_chan;

extern "C"
void os_app_dplib_cb(SENSORDPLIB_STATUS_E event) {
  if (event == SENSORDPLIB_STATUS_XDMA_FRAME_READY) {
    if (!g_trigger_chan.isrWriter().putFromISR(trigger_t {})) {
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
    r.code = 1;
    m_report_out.write(r);
    return;
  }

  NVIC_SetPriority(SC_sen_nframe_end_IRQn, CSP4CMSIS_MAX_SYSCALL_INTERRUPT_PRIORITY);

  if (cisdp_dp_init(true,
      SENSORDPLIB_PATH_INT_INP_HW5X5_JPEG,
      os_app_dplib_cb,
      0,
      APP_DP_RES_YUV640x480_INP_SUBSAMPLE_1X) < 0) {
    r.kind = ReportKind::Failed;
    r.code = 2;
    m_report_out.write(r);
    return;
  }

#ifdef UPLINK_STAGE0
  uint8_t cur = 0;
  uint32_t passes = 0;
  uint32_t last_sz[2] = {0, 0};
  uint32_t last_index[2] = {0, 0};
  arm_jpeg_buf(cur);
#endif

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

#ifdef UPLINK_STAGE0
    uint32_t hw_addr = cisdp_get_wdma2_hw_addr();
    int32_t flags = check_jpeg_buf(cur, jpeg_addr, hw_addr, jpeg_sz);
    if (flags == CHECK_ALL) passes++;
    last_sz[cur] = jpeg_sz;
    last_index[cur] = f.index;
    r = {};
    r.kind = ReportKind::BufferCheck;
    r.name = name();
    r.code = cur;
    r.index = f.index;
    r.value[0] = (int32_t)jpeg_addr;
    r.value[1] = (int32_t)hw_addr;
    r.value[2] = (int32_t)((jpeg_sz << 4) | (uint32_t)flags);
    m_report_out.write(r);
#endif

    m_frame_out.write(f);

#ifdef UPLINK_STAGE0
    if (m_frame_counter == STAGE0_FRAMES) {
      r = {};
      r.kind = ReportKind::BufferVerdict;
      r.name = name();
      r.code = (passes == STAGE0_FRAMES) ? 0 : 1;
      r.value[0] = (int32_t)passes;
      r.value[1] = (int32_t)STAGE0_FRAMES;
      m_report_out.write(r);
      for (uint8_t id = 0; id < 2; id++) {
        r = {};
        r.kind = ReportKind::JpegDump;
        r.name = name();
        r.code = id;
        r.index = last_index[id];
        r.value[0] = (int32_t)cisdp_get_jpeg_buf_addr(id);
        r.value[1] = (int32_t)last_sz[id];
        m_report_out.write(r);
      }
      for (;;) trigger_reader.read(t);
    }
    cur ^= 1;
    arm_jpeg_buf(cur);
#endif
    sensordplib_retrigger_capture();
  }
}
