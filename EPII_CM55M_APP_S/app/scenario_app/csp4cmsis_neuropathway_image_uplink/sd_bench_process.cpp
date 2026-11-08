#include "sd_bench_process.h"
#include "sd_card.h"
#include "frame_buffers.h"
#include "uplink.h"
#include "WE2_device.h"
#include "cmsis_os2.h"
#include "diskio.h"

using namespace csp;

static constexpr uint32_t BENCH_REPS = 20;

static FATFS g_fs;
static FIL g_fil;

struct BenchFile {
    const char* path;
    uint32_t addr;
    uint32_t capacity;
};

static int32_t le32(const uint8_t* p)
{
    return (int32_t)((uint32_t)p[0] | ((uint32_t)p[1] << 8) | ((uint32_t)p[2] << 16) | ((uint32_t)p[3] << 24));
}

static void describe_sectors(report_t& r)
{
    uint8_t* s = (uint8_t*)frame_jpeg_addr(0);
    r.code = (int16_t)disk_read(0, s, 0, 1);
    if (r.code != RES_OK) return;
    r.value[0] = (int32_t)(s[510] | (s[511] << 8));
    for (int k = 0; k < 4; k++) r.value[1 + k] = s[0x1BE + 16 * k + 4];
    r.value[5] = le32(&s[0x1BE + 8]);
    r.value[6] = le32(&s[3]);
    r.value[7] = le32(&s[7]);
    uint32_t lba = (uint32_t)r.value[5];
    if (lba == 0) return;
    r.index = (uint32_t)disk_read(0, s, lba, 1) + 1;
    if (r.index != 1) return;
    r.value[8] = le32(&s[3]);
    r.value[9] = le32(&s[7]);
    r.value[10] = le32(&s[0x52]);
    r.value[11] = le32(&s[0x56]);
    r.value[12] = (int32_t)(s[510] | (s[511] << 8));
}

static uint32_t cycles(void)
{
    return DWT->CYCCNT;
}

static int32_t to_us(uint64_t c)
{
    return (int32_t)(c * 1000000u / SystemCoreClock);
}

SdBench::SdBench(Chanout<report_t> report) : m_report_out(report) {}

void SdBench::run()
{
    DCB->DEMCR |= DCB_DEMCR_TRCENA_Msk;
    DWT->CTRL |= DWT_CTRL_CYCCNTENA_Msk;

    report_t r = {};
    r.name = name();
    r.kind = ReportKind::Started;
    m_report_out.write(r);

    uint32_t t = cycles();
    FRESULT res = sd_card_mount(&g_fs);
    uint32_t mount_cycles = cycles() - t;
    r = {};
    r.kind = ReportKind::SdMount;
    r.name = name();
    r.code = (int16_t)res;
    r.value[0] = g_fs.fs_type;
    r.value[1] = g_fs.csize;
    r.value[2] = (int32_t)sd_card_spi_hz();
    r.value[3] = to_us(mount_cycles);
    r.value[4] = (int32_t)SystemCoreClock;
    m_report_out.write(r);
    if (res != FR_OK) {
        r = {};
        r.kind = ReportKind::SdSectors;
        r.name = name();
        describe_sectors(r);
        m_report_out.write(r);
        return;
    }

    const BenchFile files[] = {
        {"/bench/raw640.y", frame_raw_addr(), frame_raw_size()},
        {"/bench/raw320.y", frame_raw_addr(), frame_raw_size()},
        {"/bench/small.jpg", frame_jpeg_addr(0), frame_jpeg_size()},
    };

    uint32_t tick0 = osKernelGetTickCount();
    for (const BenchFile& f : files) {
        uint8_t* buf = (uint8_t*)f.addr;
        uint64_t read_total = 0, open_total = 0;
        uint32_t read_min = UINT32_MAX, read_max = 0;
        uint32_t size = 0, first_crc = 0, reps = 0;
        bool same = true;
        res = FR_OK;
        for (; reps < BENCH_REPS; reps++) {
            t = cycles();
            res = f_open(&g_fil, f.path, FA_READ);
            uint32_t open_cycles = cycles() - t;
            if (res != FR_OK) break;
            if (f_size(&g_fil) > f.capacity) {
                f_close(&g_fil);
                res = FR_INVALID_PARAMETER;
                break;
            }
            UINT br = 0;
            t = cycles();
            res = f_read(&g_fil, buf, f.capacity, &br);
            uint32_t read_cycles = cycles() - t;
            f_close(&g_fil);
            if (res != FR_OK) break;
            uint32_t crc = crc32_update(0, buf, br);
            if (reps == 0) {
                size = br;
                first_crc = crc;
            } else if (br != size || crc != first_crc) {
                same = false;
            }
            open_total += open_cycles;
            read_total += read_cycles;
            if (read_cycles < read_min) read_min = read_cycles;
            if (read_cycles > read_max) read_max = read_cycles;
        }
        r = {};
        r.kind = ReportKind::SdBench;
        r.name = f.path;
        r.code = (int16_t)res;
        r.value[0] = (int32_t)size;
        r.value[1] = (int32_t)reps;
        r.value[2] = to_us(read_total);
        r.value[3] = reps ? to_us(read_min) : 0;
        r.value[4] = reps ? to_us(read_max) : 0;
        r.value[5] = to_us(open_total);
        r.value[6] = (int32_t)first_crc;
        r.value[7] = same ? 1 : 0;
        m_report_out.write(r);
    }
    r = {};
    r.kind = ReportKind::SdBenchDone;
    r.name = name();
    r.value[0] = (int32_t)(osKernelGetTickCount() - tick0);
    m_report_out.write(r);
}
