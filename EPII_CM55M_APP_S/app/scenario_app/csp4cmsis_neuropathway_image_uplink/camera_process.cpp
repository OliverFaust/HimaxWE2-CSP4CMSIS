#include "camera_process.h"
#include "cisdp_cfg.h"
#include "WE2_debug.h"
#include "WE2_device.h"
#include "uplink.h"
#include <string.h>

using namespace csp;

#ifdef UPLINK_STAGE0
static constexpr uint32_t STAGE0_FRAMES = 100;

static constexpr uint32_t EOI_SEARCH = 64;
static constexpr int32_t EOI_NONE = INT32_MIN;

enum : int32_t {
  CHECK_INFO_ADDR = 1,
  CHECK_HW_ADDR   = 2,
  CHECK_SOI       = 4,
  CHECK_EOI       = 8,
  CHECK_OTHER     = 16,
  CHECK_ALL       = 31,
};

static uint32_t crc32_buf(uint8_t id) {
  return crc32_update(0, (const uint8_t*)cisdp_get_jpeg_buf_addr(id), cisdp_get_jpeg_buf_size());
}

static void arm_jpeg_buf(uint8_t id) {
  uint8_t* p = (uint8_t*)cisdp_get_jpeg_buf_addr(id);
  memset(p, 0, cisdp_get_jpeg_buf_size());
  SCB_CleanInvalidateDCache_by_Addr(p, cisdp_get_jpeg_buf_size());
  cisdp_set_jpeg_buf(id);
}

static void jpeg_tail(uint8_t id, uint32_t jpeg_sz, report_t& r) {
  const uint8_t* p = (const uint8_t*)cisdp_get_jpeg_buf_addr(id);
  uint32_t n = cisdp_get_jpeg_buf_size();
  for (uint32_t k = 0; k < 16; k++) r.bytes[k] = (jpeg_sz >= 16 - k && jpeg_sz <= n) ? p[jpeg_sz - 16 + k] : 0;
  r.value[0] = EOI_NONE;
  r.value[1] = EOI_NONE;
  r.value[2] = EOI_NONE;
  if (jpeg_sz < 2 || jpeg_sz > n) return;
  for (uint32_t i = jpeg_sz - 2; i + EOI_SEARCH >= jpeg_sz; i--) {
    if (p[i] == 0xFF && p[i + 1] == 0xD9) { r.value[0] = (int32_t)(jpeg_sz - i); break; }
    if (i == 0) break;
  }
  for (uint32_t i = jpeg_sz - 1; i + 1 < n && i < jpeg_sz + EOI_SEARCH; i++) {
    if (p[i] == 0xFF && p[i + 1] == 0xD9) { r.value[1] = (int32_t)(i - jpeg_sz); break; }
  }
  for (uint32_t i = n; i > 0; i--) {
    if (p[i - 1] != 0) { r.value[2] = (int32_t)i - (int32_t)jpeg_sz; break; }
  }
}

static int32_t check_jpeg_buf(uint8_t id, uint32_t jpeg_addr, uint32_t hw_addr, uint32_t jpeg_sz, uint32_t other_crc) {
  uint32_t buf = cisdp_get_jpeg_buf_addr(id);
  const uint8_t* p = (const uint8_t*)buf;
  SCB_InvalidateDCache_by_Addr((void*)p, cisdp_get_jpeg_buf_size());
  int32_t flags = 0;
  if (jpeg_addr == buf) flags |= CHECK_INFO_ADDR;
  if (hw_addr == buf) flags |= CHECK_HW_ADDR;
  if (p[0] == 0xFF && p[1] == 0xD8) flags |= CHECK_SOI;
  if (jpeg_length(p, jpeg_sz, cisdp_get_jpeg_buf_size()) != 0) flags |= CHECK_EOI;
  uint8_t other = id ^ 1;
  SCB_InvalidateDCache_by_Addr((void*)cisdp_get_jpeg_buf_addr(other), cisdp_get_jpeg_buf_size());
  if (crc32_buf(other) == other_crc) flags |= CHECK_OTHER;
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

Camera::Camera(Chanout<frame_t> out, Chanin<release_t> release, Chanout<report_t> report)
    : m_frame_out(out), m_release_in(release), m_report_out(report), m_frame_counter(0) {}

void Camera::run() {
  trigger_t t;
  release_t token;
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
  uint32_t other_crc = crc32_buf(cur ^ 1);
#else
  uint8_t cur = 0;
  cisdp_set_jpeg_buf(cur);
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
    f.buf = cur;

#ifdef UPLINK_STAGE0
    uint32_t hw_addr = cisdp_get_wdma2_hw_addr();
    int32_t flags = check_jpeg_buf(cur, jpeg_addr, hw_addr, jpeg_sz, other_crc);
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
    r.value[2] = (int32_t)((jpeg_sz << 5) | (uint32_t)flags);
    m_report_out.write(r);
    r = {};
    r.kind = ReportKind::BufferTail;
    r.name = name();
    r.code = cur;
    r.index = f.index;
    jpeg_tail(cur, jpeg_sz, r);
    m_report_out.write(r);
#endif

    m_frame_out.write(f);
    m_release_in.read(token);

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
    other_crc = crc32_buf(cur ^ 1);
#else
    cur = token.buf;
    cisdp_set_jpeg_buf(cur);
#endif
    sensordplib_retrigger_capture();
  }
}
