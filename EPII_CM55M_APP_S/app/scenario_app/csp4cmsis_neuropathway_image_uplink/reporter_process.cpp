#include "reporter_process.h"
#include "uplink.h"
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

Reporter::Reporter(Chanin<report_t> in, Chanout<uint8_t> free_out, Chanout<uint8_t> ready_out)
    : m_in(in), m_free_out(free_out), m_ready_out(ready_out), m_seq(0), m_eoi_errors(0)
{
}

void Reporter::print_scores(const score_batch_t* b)
{
    if (b == nullptr || b->count == 0) return;
    xprintf("Scores %lu %lu:", (unsigned long)b->first, (unsigned long)b->count);
    for (uint32_t k = 0; k < b->count; k++) xprintf(" %d/%d", (int)b->person[k], (int)b->no_person[k]);
    xprintf("\r\n");
}

void Reporter::print_window(const report_t& r)
{
    xprintf("Window %lu: frames %lu-%lu", (unsigned long)r.index,
            (unsigned long)(uint32_t)r.value[WV_FIRST], (unsigned long)(uint32_t)r.value[WV_LAST]);
    if (r.value[WV_BEST] < 0) {
        xprintf(" best - score -");
    } else {
        xprintf(" best %lu score %d", (unsigned long)(uint32_t)r.value[WV_BEST], (int)r.value[WV_SCORE]);
    }
    xprintf(" merged %d failed %ld y %ld.%ld clip %ld.%02ld", (int)r.code, (long)r.value[WV_FAILED],
            (long)(r.value[WV_Y] / 10), (long)(r.value[WV_Y] % 10),
            (long)(r.value[WV_CLIP] / 100), (long)(r.value[WV_CLIP] % 100));
    xprintf(" above %ld sent %ld suppressed %ld lost %ld eoi %ld\r\n", (long)r.value[WV_ABOVE], (long)r.value[WV_SENT],
            (long)r.value[WV_SUPPRESSED], (long)r.value[WV_LOST], (long)r.value[WV_EOI]);
}

void Reporter::send_image(uint32_t frame, int8_t score, uint32_t window, uint32_t jpeg_addr, uint32_t len)
{
    const uint8_t* p = (const uint8_t*)(uintptr_t)jpeg_addr;
    SCB_InvalidateDCache_by_Addr((void*)p, (int32_t)len);
    if (len < 4 || p[0] != 0xFF || p[1] != 0xD8 || p[len - 2] != 0xFF || p[len - 1] != 0xD9) {
        m_eoi_errors++;
        xprintf("Uplink: frame %lu not sent: no SOI at 0 or no EOI at %lu (%lu errors)\r\n",
                (unsigned long)frame, (unsigned long)(len - 2), (unsigned long)m_eoi_errors);
        return;
    }
    uint8_t header[12] = {0xA5, 0x5A, 'I', 'M', FRAME_TYPE_IMAGE, 0};
    put_le(&header[6], m_seq++, 2);
    put_le(&header[8], IMAGE_META_SIZE + len, 4);
    uint8_t meta[IMAGE_META_SIZE];
    put_le(&meta[0], frame, 4);
    meta[4] = (uint8_t)score;
    put_le(&meta[5], window, 4);
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
        case ReportKind::Window:
            print_scores(r.batch);
            print_window(r);
            if (r.value[WV_SENT]) {
                send_image((uint32_t)r.value[WV_BEST], (int8_t)r.value[WV_SCORE], r.index,
                           (uint32_t)r.value[WV_JPEG_ADDR], (uint32_t)r.value[WV_JPEG_LEN]);
#ifdef UPLINK_STALL_MS
                SleepFor(Milliseconds(UPLINK_STALL_MS));
#endif
                m_free_out.write((uint8_t)r.value[WV_BUF]);
            }
            m_ready_out.write(0);
            break;
        case ReportKind::Scores:
            print_scores(r.batch);
            m_ready_out.write(0);
            break;
        case ReportKind::Model:
            xprintf("%s: output tensor type %ld scale 0.%09ld zero point %ld\r\n", r.name, (long)r.value[2],
                    (long)r.value[0], (long)r.value[1]);
            break;
        case ReportKind::Applied:
            print_scores(r.batch);
            if (r.code == 0) {
                xprintf("%s: %s=%ld applied at frame %lu\r\n", r.name, setting_name((uint8_t)r.value[0]),
                        (long)r.value[1], (unsigned long)r.index);
            } else {
                xprintf("%s: %s write FAILED at frame %lu, still %ld\r\n", r.name, setting_name((uint8_t)r.value[0]),
                        (unsigned long)r.index, (long)r.value[1]);
            }
            m_ready_out.write(0);
            break;
        case ReportKind::Settings:
            print_scores(r.batch);
            xprintf("%s: again=%ld dgain=%ld exposure=%ld framelen=%ld window=%ld threshold=%ld k=%ld\r\n", r.name,
                    (long)r.value[SETTING_AGAIN], (long)r.value[SETTING_DGAIN], (long)r.value[SETTING_EXPOSURE],
                    (long)r.value[SETTING_FRAMELEN], (long)r.value[SETTING_WINDOW],
                    (long)r.value[SETTING_THRESHOLD], (long)r.value[SETTING_K]);
            m_ready_out.write(0);
            break;
        case ReportKind::Rejected:
            switch (r.code) {
            case REJECT_UNKNOWN_SETTING:
                xprintf("%s: rejected: unknown setting\r\n", r.name);
                break;
            case REJECT_BAD_VALUE:
                xprintf("%s: rejected %s: bad value\r\n", r.name, setting_name((uint8_t)r.value[0]));
                break;
            case REJECT_OUT_OF_RANGE:
                xprintf("%s: rejected %s=%ld: out of range %ld..%ld\r\n", r.name, setting_name((uint8_t)r.value[0]),
                        (long)r.value[1], (long)r.value[2], (long)r.value[3]);
                break;
            case REJECT_LINE_TOO_LONG:
                xprintf("%s: rejected: line too long\r\n", r.name);
                break;
            case REJECT_BYTES_LOST:
                xprintf("%s: %ld received bytes lost (buffer full)\r\n", r.name, (long)r.value[1]);
                break;
            default:
                xprintf("%s: rejected: unknown command (set again|dgain|exposure|framelen|window|threshold|k <value>, get)\r\n", r.name);
                break;
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
