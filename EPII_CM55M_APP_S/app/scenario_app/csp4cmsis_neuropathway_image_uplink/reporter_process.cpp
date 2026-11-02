#include "reporter_process.h"
#include "uplink.h"
#include "cisdp_sensor.h"
#include "WE2_device.h"
#include "xprintf.h"

using namespace csp;

static constexpr uint8_t FRAME_TYPE_IMAGE = 1;
static constexpr uint32_t IMAGE_META_SIZE = 9;

static void put_bytes(const uint8_t* p, uint32_t n)
{
    for (uint32_t i = 0; i < n; i++) xfunc_out(p[i]);
}

static void put_le(uint8_t* p, uint32_t v, int n)
{
    for (int i = 0; i < n; i++) p[i] = (uint8_t)(v >> (8 * i));
}

#ifdef UPLINK_STAGE0
static void dump_jpeg(const report_t& r)
{
    static const char hex[] = "0123456789abcdef";
    static char line[2 * 32 + 1];
    const uint8_t* p = (const uint8_t*)(uintptr_t)(uint32_t)r.value[0];
    uint32_t sz = (uint32_t)r.value[1];
    xprintf("JPEG BEGIN buf=%d frame=%lu size=%lu\r\n", (int)r.code, (unsigned long)r.index, (unsigned long)sz);
    for (uint32_t i = 0; i < sz; i += 32) {
        uint32_t n = (sz - i < 32) ? sz - i : 32;
        for (uint32_t k = 0; k < n; k++) {
            line[2 * k] = hex[p[i + k] >> 4];
            line[2 * k + 1] = hex[p[i + k] & 15];
        }
        line[2 * n] = 0;
        xprintf("%s\r\n", line);
    }
    xprintf("JPEG END buf=%d\r\n", (int)r.code);
}

static void print_offset(const char* label, int32_t v)
{
    if (v == INT32_MIN) {
        xprintf(" %s none", label);
    } else {
        xprintf(" %s %ld", label, (long)v);
    }
}

static void print_tail(const report_t& r)
{
    static const char hex[] = "0123456789abcdef";
    static char line[3 * 16];
    for (int k = 0; k < 16; k++) {
        line[3 * k] = hex[r.bytes[k] >> 4];
        line[3 * k + 1] = hex[r.bytes[k] & 15];
        line[3 * k + 2] = (k == 15) ? 0 : ' ';
    }
    xprintf("%s: frame %lu buf %d tail %s", r.name, (unsigned long)r.index, (int)r.code, line);
    print_offset("eoi_back", r.value[0]);
    print_offset("eoi_fwd", r.value[1]);
    print_offset("dma_end", r.value[2]);
    xprintf("\r\n");
}
#endif

Reporter::Reporter(Chanin<report_t> in) : m_in(in), m_seq(0), m_eoi_errors(0)
{
}

void Reporter::send_image(const report_t& r)
{
    const uint8_t* p = (const uint8_t*)(uintptr_t)(uint32_t)r.value[0];
    uint32_t jpeg_sz = (uint32_t)r.value[1];
    uint32_t buf_size = cisdp_get_jpeg_buf_size();
    SCB_InvalidateDCache_by_Addr((void*)p, (int32_t)((jpeg_sz <= buf_size) ? jpeg_sz : buf_size));
    uint32_t len = jpeg_length(p, jpeg_sz, buf_size);
    if (len == 0) {
        m_eoi_errors++;
        xprintf("Uplink: frame %lu not sent: no EOI 32-35 bytes before size %lu (%lu EOI errors)\r\n",
                (unsigned long)r.index, (unsigned long)jpeg_sz, (unsigned long)m_eoi_errors);
        return;
    }
    uint8_t header[12] = {0xA5, 0x5A, 'I', 'M', FRAME_TYPE_IMAGE, 0};
    put_le(&header[6], m_seq++, 2);
    put_le(&header[8], IMAGE_META_SIZE + len, 4);
    uint8_t meta[IMAGE_META_SIZE];
    put_le(&meta[0], r.index, 4);
    meta[4] = (uint8_t)(int8_t)r.value[3];
    put_le(&meta[5], (uint32_t)r.value[2], 4);
    uint32_t crc = crc32_update(0, meta, IMAGE_META_SIZE);
    crc = crc32_update(crc, p, len);
    uint8_t trailer[4];
    put_le(trailer, crc, 4);
    put_bytes(header, sizeof(header));
    put_bytes(meta, sizeof(meta));
    put_bytes(p, len);
    put_bytes(trailer, sizeof(trailer));
}

void Reporter::run()
{
    while (true) {
        report_t r;
        m_in >> r;

        switch (r.kind) {
        case ReportKind::Started:
            xprintf("%s: started\r\n", r.name);
            break;
        case ReportKind::Failed:
            xprintf("%s: initialisation FAILED (step %d)\r\n", r.name, (int)r.code);
            break;
        case ReportKind::Result:
            xprintf("Frame %lu: inference failed (%d)\r\n", (unsigned long)r.index, (int)r.code);
            break;
        case ReportKind::Window:
            xprintf("Window %lu: frames %lu-%lu best %lu score %d merged %d\r\n",
                    (unsigned long)r.index, (unsigned long)(uint32_t)r.value[0], (unsigned long)(uint32_t)r.value[1],
                    (unsigned long)(uint32_t)r.value[2], (int)r.value[3], (int)r.code);
            break;
        case ReportKind::Stack:
            if (r.value[2] < 0) {
                xprintf("%s: allocated = %u bytes, HWM unavailable\r\n", r.name, (unsigned)r.value[1]);
            } else {
                xprintf("%s: %u/%u bytes used (%u bytes unused headroom, %u words HWM)\r\n",
                        r.name, (unsigned)r.value[0], (unsigned)r.value[1],
                        (unsigned)(r.value[1] - r.value[0]), (unsigned)r.value[2]);
            }
            break;
        case ReportKind::Image:
            send_image(r);
            break;
#ifdef UPLINK_STAGE0
        case ReportKind::BufferCheck:
            xprintf("%s: frame %lu buf %d jpeg_addr 0x%08lx wdma2 0x%08lx size %lu flags %x %s\r\n",
                    r.name, (unsigned long)r.index, (int)r.code,
                    (unsigned long)(uint32_t)r.value[0], (unsigned long)(uint32_t)r.value[1],
                    (unsigned long)((uint32_t)r.value[2] >> 5), (unsigned)(r.value[2] & 31),
                    ((r.value[2] & 31) == 31) ? "ok" : "FAIL");
            break;
        case ReportKind::BufferTail:
            print_tail(r);
            break;
        case ReportKind::BufferVerdict:
            xprintf("%s: STAGE0 %s (%ld of %ld frames ok)\r\n", r.name,
                    (r.code == 0) ? "PASS" : "FAIL", (long)r.value[0], (long)r.value[1]);
            break;
        case ReportKind::JpegDump:
            dump_jpeg(r);
            break;
#endif
        }
    }
}
