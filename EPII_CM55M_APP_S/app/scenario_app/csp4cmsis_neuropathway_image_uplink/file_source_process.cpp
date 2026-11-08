#ifdef FRAME_SOURCE_SDCARD
#include "file_source_process.h"
#include "sd_card.h"
#include "mmc_we2.h"
#include "frame_buffers.h"
#include "uplink.h"
#include "WE2_device.h"
#include <string.h>

using namespace csp;


static constexpr uint32_t LINE_MAX_LEN = 160;
static constexpr uint32_t FIELDS_MAX = 12;
static constexpr uint32_t FIELDS_NEEDED = 11;
static constexpr uint32_t NAME_MAX_LEN = 39;
static constexpr uint32_t MIN_SIDE = 96;
static constexpr uint32_t SOURCE_STATUS_MS = 10000;
static const char MANIFEST_PATH[] = SD_FRAME_DIR "/manifest.csv";
static const char MANIFEST_COLUMNS[] = "index,y_file,jpg_file,width,height,crc32_y,crc32_jpg";

static FATFS g_fs;
static FIL g_manifest;
static FIL g_file;
static char g_chunk[128];
static UINT g_chunk_len;
static UINT g_chunk_pos;
static uint32_t g_line_no;
static char g_line[LINE_MAX_LEN + 1];
static char g_paths[2][sizeof(SD_FRAME_DIR) + 1 + NAME_MAX_LEN + 1];

static void rewind_manifest()
{
    f_lseek(&g_manifest, 0);
    g_chunk_len = 0;
    g_chunk_pos = 0;
    g_line_no = 0;
}

static int read_line()
{
    uint32_t n = 0;
    bool overlong = false;
    while (true) {
        if (g_chunk_pos == g_chunk_len) {
            g_chunk_pos = 0;
            if (f_read(&g_manifest, g_chunk, sizeof(g_chunk), &g_chunk_len) != FR_OK) g_chunk_len = 0;
            if (g_chunk_len == 0) {
                if (n == 0 && !overlong) return -1;
                break;
            }
        }
        char c = g_chunk[g_chunk_pos++];
        if (c == '\n') break;
        if (c == '\r') continue;
        if (n < LINE_MAX_LEN) g_line[n++] = c;
        else overlong = true;
    }
    g_line[n] = 0;
    g_line_no++;
    return overlong ? -2 : (int)n;
}

static uint32_t split(char* line, char** fields)
{
    uint32_t n = 0;
    fields[n++] = line;
    for (char* p = line; *p && n < FIELDS_MAX; p++) {
        if (*p == ',') {
            *p = 0;
            fields[n++] = p + 1;
        }
    }
    return n;
}

static bool parse_uint(const char* s, uint32_t base, uint32_t& v)
{
    if (*s == 0) return false;
    uint64_t x = 0;
    for (; *s; s++) {
        uint32_t d;
        if (*s >= '0' && *s <= '9') d = (uint32_t)(*s - '0');
        else if (base == 16 && *s >= 'a' && *s <= 'f') d = (uint32_t)(*s - 'a' + 10);
        else if (base == 16 && *s >= 'A' && *s <= 'F') d = (uint32_t)(*s - 'A' + 10);
        else return false;
        x = x * base + d;
        if (x > UINT32_MAX) return false;
    }
    v = (uint32_t)x;
    return true;
}

static bool parse_milli(const char* s, uint32_t& v)
{
    uint32_t whole = 0, frac = 0, digits = 0;
    bool point = false;
    if (*s == 0) return false;
    for (; *s; s++) {
        if (*s == '.' && !point) {
            point = true;
        } else if (*s >= '0' && *s <= '9') {
            if (!point) whole = whole * 10 + (uint32_t)(*s - '0');
            else if (digits < 3) {
                frac = frac * 10 + (uint32_t)(*s - '0');
                digits++;
            }
        } else {
            return false;
        }
    }
    while (digits < 3) {
        frac *= 10;
        digits++;
    }
    v = whole * 1000 + frac;
    return true;
}

static bool copy_name(char* dst, const char* src)
{
    uint32_t n = strlen(src);
    if (n == 0 || n > NAME_MAX_LEN) return false;
    memcpy(dst, src, n + 1);
    return true;
}

static uint32_t cycles_to_us(uint64_t c, uint32_t n)
{
    return n ? (uint32_t)(c / n / (SystemCoreClock / 1000000u)) : 0;
}

static uint32_t ms_to_ticks(uint32_t ms)
{
    return (uint32_t)(((uint64_t)ms * osKernelGetTickFreq() + 999u) / 1000u);
}

FileSource::FileSource(Chanout<frame_t> out, Chanin<release_t> release, Chanin<command_t> cmd, Chanout<report_t> report)
    : m_frame_out(out), m_release_in(release), m_cmd_in(cmd), m_report_out(report), m_settings(default_settings()),
      m_changed(0), m_buf(0), m_loop(false), m_restart(false), m_pace_set(false), m_pace_ms(0), m_index(0),
      m_frames(0), m_width(0), m_height(0), m_pass(0), m_sent(0), m_read_errors(0), m_crc_errors(0),
      m_jpeg_errors(0), m_read_cycles(0), m_crc_cycles(0), m_wait_cycles(0), m_path_slot(0), m_remounts(0),
      m_status_frames(0), m_status_slowest_us(0), m_status_tick(0)
{
}

const char* FileSource::path_of(const char* file)
{
    char* p = g_paths[m_path_slot];
    m_path_slot ^= 1;
    uint32_t d = sizeof(SD_FRAME_DIR) - 1;
    memcpy(p, SD_FRAME_DIR, d);
    p[d] = '/';
    strcpy(p + d + 1, file);
    return p;
}

void FileSource::report_simple(int16_t code, int32_t v0)
{
    report_t r = {};
    r.kind = ReportKind::Source;
    r.name = name();
    r.code = code;
    r.value[0] = v0;
    m_report_out.write(r);
}

void FileSource::report_status()
{
    report_t r = {};
    r.kind = ReportKind::Source;
    r.name = name();
    r.code = SRC_STATUS;
    uint32_t overruns, timeouts, longest_us;
    mmc_disk_wait_stats(&overruns, &timeouts, &longest_us);
    r.value[SV_FRAMES] = (int32_t)m_status_frames;
    r.value[SV_READ_US] = (int32_t)m_status_slowest_us;
    r.value[SV_OVERRUNS] = (int32_t)overruns;
    r.value[SV_TIMEOUTS] = (int32_t)timeouts;
    r.value[SV_REMOUNTS] = (int32_t)m_remounts;
    r.value[SV_LONGEST_WAIT_US] = (int32_t)longest_us;
    m_report_out.write(r);
    m_status_frames = 0;
    m_status_slowest_us = 0;
    m_status_tick = osKernelGetTickCount();
}

void FileSource::report_manifest(uint32_t line, int32_t reason, int32_t a, int32_t b, int32_t c, int32_t d)
{
    report_t r = {};
    r.kind = ReportKind::Source;
    r.name = name();
    r.code = SRC_MANIFEST_ERROR;
    r.text = MANIFEST_PATH;
    r.index = line;
    r.value[0] = reason;
    r.value[1] = a;
    r.value[2] = b;
    r.value[3] = c;
    r.value[4] = d;
    m_report_out.write(r);
}

void FileSource::report_totals(int16_t kind)
{
    report_t r = {};
    r.kind = ReportKind::Source;
    r.name = name();
    r.code = kind;
    r.index = m_pass;
    uint32_t attempts = m_sent + m_read_errors + m_crc_errors;
    r.value[SV_FRAMES] = (int32_t)m_sent;
    r.value[SV_READ_ERRORS] = (int32_t)m_read_errors;
    r.value[SV_CRC_ERRORS] = (int32_t)m_crc_errors;
    r.value[SV_JPEG_ERRORS] = (int32_t)m_jpeg_errors;
    r.value[SV_READ_US] = (int32_t)cycles_to_us(m_read_cycles, attempts);
    r.value[SV_CRC_US] = (int32_t)cycles_to_us(m_crc_cycles, m_sent + m_crc_errors);
    r.value[SV_WAIT_US] = (int32_t)cycles_to_us(m_wait_cycles, m_sent);
    m_report_out.write(r);
    m_sent = 0;
    m_read_errors = 0;
    m_crc_errors = 0;
    m_jpeg_errors = 0;
    m_read_cycles = 0;
    m_crc_cycles = 0;
    m_wait_cycles = 0;
}

void FileSource::handle(const command_t& c)
{
    switch (c.op) {
    case CommandOp::Get:
        m_changed |= SETTINGS_GET;
        break;
    case CommandOp::Set:
        if (c.setting == SETTING_WINDOW || c.setting == SETTING_THRESHOLD || c.setting == SETTING_K) {
            m_settings.value[c.setting] = c.value;
            m_changed |= (uint8_t)(1u << c.setting);
        } else {
            report_simple(SRC_NOT_APPLICABLE, c.setting);
        }
        break;
    case CommandOp::Pace:
        m_pace_ms = c.value;
        m_pace_set = true;
        report_simple(SRC_PACE, (int32_t)m_pace_ms);
        break;
    case CommandOp::Loop:
        m_loop = c.value != 0;
        report_simple(SRC_LOOP, m_loop ? 1 : 0);
        break;
    case CommandOp::Restart:
        m_restart = true;
        report_simple(SRC_RESTART, 0);
        break;
    }
}

FileSource::Next FileSource::next_entry(Entry& e)
{
    while (true) {
        int n = read_line();
        e.line = g_line_no;
        if (n == -1) return Next::End;
        if (n == -2) return Next::Bad;
        if (n == 0) continue;
        char* f[FIELDS_MAX];
        uint32_t count = split(g_line, f);
        uint32_t w, h;
        if (count < FIELDS_NEEDED || !copy_name(e.y_file, f[1]) || !copy_name(e.jpg_file, f[2])
            || !parse_uint(f[3], 10, w) || !parse_uint(f[4], 10, h) || w > 0xFFFF || h > 0xFFFF
            || !parse_uint(f[5], 16, e.crc_y) || !parse_uint(f[6], 16, e.crc_jpg)
            || !parse_milli(f[10], e.fps_milli)) {
            return Next::Bad;
        }
        e.width = (uint16_t)w;
        e.height = (uint16_t)h;
        return Next::Frame;
    }
}

bool FileSource::start_stream()
{
    m_restart = false;
    sd_card_unmount();
    FRESULT res = sd_card_mount(&g_fs);
    if (res != FR_OK) {
        report_simple(SRC_MOUNT_FAILED, res);
        return false;
    }
    res = f_open(&g_manifest, MANIFEST_PATH, FA_READ);
    if (res != FR_OK) {
        report_manifest(0, MANIFEST_OPEN, res, 0, 0, 0);
        return false;
    }
    rewind_manifest();
    if (read_line() < 0 || strncmp(g_line, MANIFEST_COLUMNS, sizeof(MANIFEST_COLUMNS) - 1) != 0) {
        report_manifest(1, MANIFEST_HEADER, 0, 0, 0, 0);
        return false;
    }
    Entry e;
    uint32_t frames = 0;
    uint32_t fps_milli = 0;
    while (true) {
        Next n = next_entry(e);
        if (n == Next::End) break;
        if (n == Next::Bad) {
            report_manifest(e.line, MANIFEST_LINE, 0, 0, 0, 0);
            return false;
        }
        if (frames == 0) {
            m_width = e.width;
            m_height = e.height;
            fps_milli = e.fps_milli;
        } else if (e.width != m_width || e.height != m_height) {
            report_manifest(e.line, MANIFEST_MIXED, e.width, e.height, m_width, m_height);
            return false;
        }
        frames++;
    }
    if (frames == 0) {
        report_manifest(g_line_no, MANIFEST_EMPTY, 0, 0, 0, 0);
        return false;
    }
    if (m_width < MIN_SIDE || m_height < MIN_SIDE || m_width > FRAME_RAW_WIDTH || m_height > FRAME_RAW_HEIGHT) {
        report_manifest(2, MANIFEST_SIZE, m_width, m_height, 0, 0);
        return false;
    }
    m_frames = frames;
    if (!m_pace_set) m_pace_ms = fps_milli ? (1000000u + fps_milli / 2) / fps_milli : 0;
    rewind_manifest();
    read_line();

    report_t r = {};
    r.kind = ReportKind::Source;
    r.name = name();
    r.code = SRC_STARTED;
    r.value[SV_FRAMES] = (int32_t)m_frames;
    r.value[SV_WIDTH] = m_width;
    r.value[SV_HEIGHT] = m_height;
    r.value[SV_PACE] = (int32_t)m_pace_ms;
    r.value[SV_LOOP] = m_loop ? 1 : 0;
    r.value[SV_SPI_HZ] = (int32_t)sd_card_spi_hz();
    m_report_out.write(r);
    return true;
}

bool FileSource::read_file(const char* file, uint8_t* buf, uint32_t capacity, uint32_t& size, uint32_t frame)
{
    const char* path = path_of(file);
    report_t r = {};
    r.kind = ReportKind::Source;
    r.name = name();
    r.code = SRC_FILE_ERROR;
    r.index = frame;
    r.text = path;
    FRESULT res = f_open(&g_file, path, FA_READ);
    if (res == FR_OK && f_size(&g_file) > capacity) {
        r.value[0] = FILE_SIZE;
        r.value[1] = (int32_t)f_size(&g_file);
        f_close(&g_file);
        m_report_out.write(r);
        return false;
    }
    UINT br = 0;
    if (res == FR_OK) {
        res = f_read(&g_file, buf, capacity, &br);
        f_close(&g_file);
    }
    if (res != FR_OK) {
        r.value[0] = FILE_READ;
        r.value[1] = res;
        r.value[2] = (int32_t)mmc_disk_last_error();
        m_report_out.write(r);
        return false;
    }
    size = br;
    return true;
}

void FileSource::send_terminator()
{
    frame_t f = {};
    f.index = m_index;
    f.buf = m_buf;
    f.end = 1;
    f.changed = m_changed;
    f.settings = m_settings;
    m_changed = 0;
    m_frame_out.write(f);
    release_t token;
    m_release_in.read(token);
    m_buf = token.buf;
}

void FileSource::wait_for_restart()
{
    while (!m_restart) {
        command_t c;
        m_cmd_in.read(c);
        handle(c);
    }
}

void FileSource::stream()
{
    m_pass = 1;
    m_status_tick = osKernelGetTickCount();
    command_t cmd = {};
    RelTimeoutGuard skip(Milliseconds(0));
    Alternative poll_cmd(m_cmd_in | cmd, skip);
    uint32_t due = osKernelGetTickCount();
    const uint32_t raw_size = (uint32_t)m_width * m_height;
    Entry e;
    while (true) {
        if (m_restart) {
            send_terminator();
            report_totals(SRC_END);
            return;
        }
        Next n = next_entry(e);
        if (n == Next::End) {
            if (m_loop) {
                report_totals(SRC_PASS);
                m_pass++;
                rewind_manifest();
                read_line();
                continue;
            }
            send_terminator();
            report_totals(SRC_END);
            wait_for_restart();
            return;
        }
        if (n == Next::Bad) {
            report_manifest(e.line, MANIFEST_LINE, 0, 0, 0, 0);
            m_read_errors++;
            continue;
        }

        uint8_t* raw = (uint8_t*)frame_raw_addr();
        uint8_t* jpg = (uint8_t*)frame_jpeg_addr(m_buf);
        uint32_t y_size = 0, jpg_size = 0;
        uint32_t t0 = DWT->CYCCNT;
        bool ok = read_file(e.y_file, raw, raw_size, y_size, m_index)
                  && read_file(e.jpg_file, jpg, frame_jpeg_size(), jpg_size, m_index);
        uint32_t t1 = DWT->CYCCNT;
        m_read_cycles += t1 - t0;
        uint32_t read_us = cycles_to_us(t1 - t0, 1);
        if (read_us > m_status_slowest_us) m_status_slowest_us = read_us;
        if (ok && y_size != raw_size) {
            report_t r = {};
            r.kind = ReportKind::Source;
            r.name = name();
            r.code = SRC_FILE_ERROR;
            r.index = m_index;
            r.text = path_of(e.y_file);
            r.value[0] = FILE_SIZE;
            r.value[1] = (int32_t)y_size;
            m_report_out.write(r);
            ok = false;
        }
        if (!ok) {
            m_read_errors++;
            m_remounts++;
            sd_card_unmount();
            FRESULT res = sd_card_mount(&g_fs);
            if (res != FR_OK) {
                report_simple(SRC_MOUNT_FAILED, res);
                send_terminator();
                report_totals(SRC_END);
                wait_for_restart();
                return;
            }
            uint32_t line = e.line;
            f_open(&g_manifest, MANIFEST_PATH, FA_READ);
            rewind_manifest();
            while (g_line_no < line && read_line() != -1) {
            }
            continue;
        }

        uint32_t crc_y = crc32_update(0, raw, y_size);
        uint32_t crc_jpg = crc32_update(0, jpg, jpg_size);
        m_crc_cycles += DWT->CYCCNT - t1;
        if (crc_y != e.crc_y || crc_jpg != e.crc_jpg) {
            bool y_bad = crc_y != e.crc_y;
            report_t r = {};
            r.kind = ReportKind::Source;
            r.name = name();
            r.code = SRC_FILE_ERROR;
            r.index = m_index;
            r.text = path_of(y_bad ? e.y_file : e.jpg_file);
            r.value[0] = FILE_CRC;
            r.value[1] = (int32_t)(y_bad ? crc_y : crc_jpg);
            r.value[2] = (int32_t)(y_bad ? e.crc_y : e.crc_jpg);
            m_report_out.write(r);
            m_crc_errors++;
            continue;
        }

        uint32_t jpeg_len = jpg_size;
        if (jpg_size < 4 || jpg[0] != 0xFF || jpg[1] != 0xD8 || jpg[jpg_size - 2] != 0xFF || jpg[jpg_size - 1] != 0xD9) {
            report_t r = {};
            r.kind = ReportKind::Source;
            r.name = name();
            r.code = SRC_FILE_ERROR;
            r.index = m_index;
            r.text = path_of(e.jpg_file);
            r.value[0] = FILE_JPEG;
            r.value[1] = (int32_t)jpg_size;
            m_report_out.write(r);
            m_jpeg_errors++;
            jpeg_len = 0;
        }
        SCB_CleanDCache_by_Addr((volatile void*)jpg, (int32_t)jpg_size);

        if (m_pace_ms) {
            uint32_t now = osKernelGetTickCount();
            while ((int32_t)(due - now) > 0 && !m_restart) {
                RelTimeoutGuard timeout(Ticks(due - now));
                Alternative wait(m_cmd_in | cmd, timeout);
                if (wait.priSelect() == 0) handle(cmd);
                now = osKernelGetTickCount();
            }
            uint32_t period = ms_to_ticks(m_pace_ms);
            due += period;
            if ((int32_t)(now - due) > (int32_t)period) due = now;
            if (m_restart) continue;
        }

        frame_t f = {};
        f.index = m_index++;
        f.jpeg_addr = (uint32_t)jpg;
        f.jpeg_len = jpeg_len;
        f.raw_addr = (uint32_t)raw;
        f.raw_w = m_width;
        f.raw_h = m_height;
        f.read_us = read_us;
        f.buf = m_buf;
        f.changed = m_changed;
        f.settings = m_settings;
        m_changed = 0;

        uint32_t tw = DWT->CYCCNT;
        m_frame_out.write(f);
        if (poll_cmd.priSelect() == 0) handle(cmd);
        release_t token;
        m_release_in.read(token);
        m_buf = token.buf;
        m_wait_cycles += DWT->CYCCNT - tw;
        m_sent++;
        m_status_frames++;
        if (osKernelGetTickCount() - m_status_tick >= ms_to_ticks(SOURCE_STATUS_MS)) report_status();
    }
}

void FileSource::run()
{
    DCB->DEMCR |= DCB_DEMCR_TRCENA_Msk;
    DWT->CTRL |= DWT_CTRL_CYCCNTENA_Msk;
    while (true) {
        if (start_stream()) {
            stream();
        } else {
            wait_for_restart();
        }
    }
}
#endif
