#include "reporter_process.h"
#include "uplink.h"
#include "sd_result.h"
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
    xprintf(" above %ld sent %ld suppressed %ld lost %ld eoi %ld infer %ld read %ld\r\n", (long)r.value[WV_ABOVE],
            (long)r.value[WV_SENT], (long)r.value[WV_SUPPRESSED], (long)r.value[WV_LOST], (long)r.value[WV_EOI],
            (long)r.value[WV_INFER], (long)(r.value[WV_READ] / 1000));
}

static void print_ms(const char* label, int32_t us)
{
    xprintf(" %s %ld.%ld ms", label, (long)(us / 1000), (long)((us % 1000) / 100));
}

void Reporter::print_source(const report_t& r)
{
    static const char* const FILE_ERRORS[] = {"read FAILED", "wrong size", "CRC mismatch", "no SOI/EOI"};
    static const char* const MANIFEST_ERRORS[] = {"cannot open", "bad header", "bad line", "mixed frame sizes",
                                                  "unsupported frame size", "no frames"};
    const int32_t* v = r.value;
    switch (r.code) {
    case SRC_STARTED:
        xprintf("%s: started %ld frames %ldx%ld, pace %ld ms, loop %s, SPI %ld Hz\r\n", r.name, (long)v[SV_FRAMES],
                (long)v[SV_WIDTH], (long)v[SV_HEIGHT], (long)v[SV_PACE], v[SV_LOOP] ? "on" : "off", (long)v[SV_SPI_HZ]);
        break;
    case SRC_PASS:
    case SRC_END:
        xprintf("%s: %s %lu: %ld frames %ld errors (read %ld, crc %ld, jpeg %ld);", r.name,
                r.code == SRC_END ? "end" : "pass", (unsigned long)r.index, (long)v[SV_FRAMES],
                (long)(v[SV_READ_ERRORS] + v[SV_CRC_ERRORS] + v[SV_JPEG_ERRORS]), (long)v[SV_READ_ERRORS],
                (long)v[SV_CRC_ERRORS], (long)v[SV_JPEG_ERRORS]);
        print_ms("read", v[SV_READ_US]);
        print_ms("crc", v[SV_CRC_US]);
        print_ms("wait", v[SV_WAIT_US]);
        xprintf(" per frame\r\n");
        break;
    case SRC_FILE_ERROR:
        if (v[0] == FILE_READ) {
            xprintf("%s: frame %lu %s: read FAILED: %s (%ld), card step %lx\r\n", r.name, (unsigned long)r.index,
                    r.text, sd_card_result_name(v[1]), (long)v[1], (unsigned long)(uint32_t)v[2]);
        } else if (v[0] == FILE_CRC) {
            xprintf("%s: frame %lu %s: CRC mismatch: %08lx, manifest %08lx\r\n", r.name, (unsigned long)r.index,
                    r.text, (unsigned long)(uint32_t)v[1], (unsigned long)(uint32_t)v[2]);
        } else {
            xprintf("%s: frame %lu %s: %s (%ld bytes)\r\n", r.name, (unsigned long)r.index, r.text,
                    FILE_ERRORS[v[0] & 3], (long)v[1]);
        }
        break;
    case SRC_MANIFEST_ERROR:
        xprintf("%s: manifest %s line %lu: %s", r.name, r.text, (unsigned long)r.index,
                (uint32_t)v[0] < 6 ? MANIFEST_ERRORS[v[0]] : "?");
        if (v[0] == MANIFEST_OPEN) xprintf(": %s (%ld)", sd_card_result_name(v[1]), (long)v[1]);
        if (v[0] == MANIFEST_MIXED || v[0] == MANIFEST_SIZE) {
            xprintf(": %ldx%ld", (long)v[1], (long)v[2]);
            if (v[0] == MANIFEST_MIXED) xprintf(", first frame %ldx%ld", (long)v[3], (long)v[4]);
        }
        xprintf("; waiting for restart\r\n");
        break;
    case SRC_MOUNT_FAILED:
        xprintf("%s: mount FAILED: %s (%ld); waiting for restart\r\n", r.name, sd_card_result_name(v[0]), (long)v[0]);
        break;
    case SRC_PACE:
        xprintf("%s: pace %ld ms\r\n", r.name, (long)v[0]);
        break;
    case SRC_LOOP:
        xprintf("%s: loop %s\r\n", r.name, v[0] ? "on" : "off");
        break;
    case SRC_RESTART:
        xprintf("%s: restart\r\n", r.name);
        break;
    case SRC_STATUS:
        xprintf("%s: status: %ld frames,", r.name, (long)v[SV_FRAMES]);
        print_ms("slowest read", v[SV_READ_US]);
        xprintf(",");
        print_ms("longest card wait", v[SV_LONGEST_WAIT_US]);
        xprintf(", card waits over the limit %ld, timeouts %ld, remounts %ld\r\n", (long)v[SV_OVERRUNS],
                (long)v[SV_TIMEOUTS], (long)v[SV_REMOUNTS]);
        break;
    case SRC_NOT_APPLICABLE:
        xprintf("%s: %s not applicable (no sensor)\r\n", r.name, setting_name((uint8_t)v[0]));
        break;
    default:
        break;
    }
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
            case REJECT_NOT_APPLICABLE:
                if (r.value[0] == SETTING_PACE) {
                    xprintf("%s: rejected pace: not applicable to this frame source\r\n", r.name);
                } else {
                    xprintf("%s: rejected: loop and restart are not applicable to this frame source\r\n", r.name);
                }
                break;
            case REJECT_BYTES_LOST:
                xprintf("%s: %ld received bytes lost (buffer full)\r\n", r.name, (long)r.value[1]);
                break;
            default:
                xprintf("%s: rejected: unknown command (set again|dgain|exposure|framelen|window|threshold|k|pace <value>, get, loop on|off, restart)\r\n", r.name);
                break;
            }
            break;
        case ReportKind::SdMount:
            if (r.code != 0) {
                xprintf("%s: mount FAILED: %s (%d)\r\n", r.name, sd_card_result_name(r.code), (int)r.code);
            } else {
                xprintf("%s: mount %lu: FAT type %ld, %ld sectors per cluster, SPI %ld Hz, mount %ld us, core %ld Hz\r\n",
                        r.name, (unsigned long)r.index, (long)r.value[0], (long)r.value[1], (long)r.value[2], (long)r.value[3],
                        (long)r.value[4]);
            }
            break;
        case ReportKind::SdBench:
            if (r.code != 0) {
                xprintf("SdBench: mount %lu %s FAILED after %ld reads: %s (%d)\r\n", (unsigned long)r.index, r.name,
                        (long)r.value[1],
                        sd_card_result_name(r.code), (int)r.code);
            } else {
                uint64_t bytes = (uint64_t)(uint32_t)r.value[0] * (uint32_t)r.value[1];
                uint32_t read_us = (uint32_t)r.value[2];
                uint32_t all_us = read_us + (uint32_t)r.value[5];
                xprintf("SdBench: mount %lu %s %ld bytes x %ld: read %lu KB/s (min %ld us, max %ld us, mean %lu us), "
                        "with open %lu KB/s (open mean %lu us), crc %08lx %s\r\n",
                        (unsigned long)r.index, r.name, (long)r.value[0], (long)r.value[1],
                        (unsigned long)(read_us ? bytes * 1000u / read_us : 0), (long)r.value[3], (long)r.value[4],
                        (unsigned long)(read_us / (uint32_t)r.value[1]),
                        (unsigned long)(all_us ? bytes * 1000u / all_us : 0),
                        (unsigned long)((uint32_t)r.value[5] / (uint32_t)r.value[1]),
                        (unsigned long)(uint32_t)r.value[6], r.value[7] ? "same every read" : "DIFFERS between reads");
            }
            break;
        case ReportKind::SdSectors: {
            if (r.code != 0) {
                xprintf("%s: sector 0 read FAILED (%d)\r\n", r.name, (int)r.code);
                break;
            }
            char oem[9], oem1[9], fs1[9];
            for (int k = 0; k < 4; k++) {
                oem[k] = (char)(r.value[6] >> (8 * k));
                oem[4 + k] = (char)(r.value[7] >> (8 * k));
                oem1[k] = (char)(r.value[8] >> (8 * k));
                oem1[4 + k] = (char)(r.value[9] >> (8 * k));
                fs1[k] = (char)(r.value[10] >> (8 * k));
                fs1[4 + k] = (char)(r.value[11] >> (8 * k));
            }
            for (int k = 0; k < 8; k++) {
                if (oem[k] < 32 || oem[k] > 126) oem[k] = '.';
                if (oem1[k] < 32 || oem1[k] > 126) oem1[k] = '.';
                if (fs1[k] < 32 || fs1[k] > 126) fs1[k] = '.';
            }
            oem[8] = oem1[8] = fs1[8] = 0;
            xprintf("%s: sector 0 signature %04lx, partition types %02lx %02lx %02lx %02lx, first partition at %lu, "
                    "OEM '%s'\r\n", r.name, (unsigned long)r.value[0], (unsigned long)r.value[1],
                    (unsigned long)r.value[2], (unsigned long)r.value[3], (unsigned long)r.value[4],
                    (unsigned long)(uint32_t)r.value[5], oem);
            if (r.index == 1) {
                xprintf("%s: partition boot sector signature %04lx, OEM '%s', type '%s'\r\n", r.name,
                        (unsigned long)r.value[12], oem1, fs1);
            } else if (r.index > 1) {
                xprintf("%s: partition boot sector read FAILED (%d)\r\n", r.name, (int)(r.index - 1));
            }
            break;
        }
        case ReportKind::SdBenchDone:
            xprintf("%s: done in %ld ms\r\n", r.name, (long)r.value[0]);
            break;
        case ReportKind::Source:
            print_source(r);
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
