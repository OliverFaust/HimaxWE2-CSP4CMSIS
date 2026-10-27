#include "reporter_process.h"
#include "xprintf.h"

using namespace csp;

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

Reporter::Reporter(Chanin<report_t> in) : m_in(in)
{
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
            if (r.code == 0) {
                xprintf("Frame %lu: prediction = %d\n", (unsigned long)r.index, (int)r.value[0]);
            } else {
                xprintf("Frame %lu: inference failed\n", (unsigned long)r.index);
            }
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
        case ReportKind::BufferCheck:
            xprintf("%s: frame %lu buf %d jpeg_addr 0x%08lx wdma2 0x%08lx size %lu flags %x %s\r\n",
                    r.name, (unsigned long)r.index, (int)r.code,
                    (unsigned long)(uint32_t)r.value[0], (unsigned long)(uint32_t)r.value[1],
                    (unsigned long)((uint32_t)r.value[2] >> 4), (unsigned)(r.value[2] & 15),
                    ((r.value[2] & 15) == 15) ? "ok" : "FAIL");
            break;
        case ReportKind::BufferVerdict:
            xprintf("%s: STAGE0 %s (%ld of %ld frames ok)\r\n", r.name,
                    (r.code == 0) ? "PASS" : "FAIL", (long)r.value[0], (long)r.value[1]);
            break;
        case ReportKind::JpegDump:
            dump_jpeg(r);
            break;
        }
    }
}
