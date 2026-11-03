#include "command_process.h"
#include "uplink.h"
#include "WE2_device.h"
#include "hx_drv_uart.h"
#include <string.h>

using namespace csp;

static constexpr uint32_t RX_BUFFER = 128;
static constexpr uint32_t COMMAND_LINE_MAX = 40;
static constexpr uint8_t RX_LOST_MARK = 0xFF;

static BufferedChannel<uint8_t, RX_BUFFER> g_rx_chan;
static DEV_UART* g_console;
static volatile uint32_t g_rx_lost;
static bool g_rx_mark_due;

static void console_rx_cb(void* ptr)
{
    (void)ptr;
    uint8_t c;
    auto w = g_rx_chan.isrWriter();
    while (g_console->uart_read_nonblock(&c, 1) > 0) {
        if (g_rx_mark_due && w.putFromISR(RX_LOST_MARK)) g_rx_mark_due = false;
        if (g_rx_mark_due || !w.putFromISR(c)) {
            g_rx_mark_due = true;
            g_rx_lost++;
        }
    }
}

static bool parse_number(const char* s, uint32_t* out)
{
    uint32_t v = 0;
    uint32_t base = 10;
    if (s[0] == '0' && (s[1] == 'x' || s[1] == 'X')) {
        base = 16;
        s += 2;
    }
    if (*s == 0) return false;
    for (; *s; s++) {
        uint32_t d;
        if (*s >= '0' && *s <= '9') d = (uint32_t)(*s - '0');
        else if (base == 16 && *s >= 'a' && *s <= 'f') d = (uint32_t)(*s - 'a' + 10);
        else if (base == 16 && *s >= 'A' && *s <= 'F') d = (uint32_t)(*s - 'A' + 10);
        else return false;
        v = v * base + d;
        if (v > 0xFFFF) return false;
    }
    *out = v;
    return true;
}

static char* next_word(char** p)
{
    while (**p == ' ') (*p)++;
    if (**p == 0) return nullptr;
    char* w = *p;
    while (**p && **p != ' ') (*p)++;
    if (**p) *(*p)++ = 0;
    return w;
}

Command::Command(Chanout<command_t> cmd, Chanout<report_t> report)
    : m_cmd_out(cmd), m_report_out(report), m_settings(default_settings())
{
}

void Command::reject(int16_t reason, uint8_t setting, int32_t value, int32_t lo, int32_t hi)
{
    report_t r = {};
    r.kind = ReportKind::Rejected;
    r.name = name();
    r.code = reason;
    r.value[0] = setting;
    r.value[1] = value;
    r.value[2] = lo;
    r.value[3] = hi;
    m_report_out.write(r);
}

void Command::handle(char* line)
{
    char* p = line;
    char* verb = next_word(&p);
    if (verb == nullptr) return;
    if (strcmp(verb, "get") == 0 && next_word(&p) == nullptr) {
        m_cmd_out.write(command_t { CommandOp::Get, 0, 0 });
        return;
    }
    if (strcmp(verb, "set") != 0) {
        reject(REJECT_UNKNOWN_COMMAND);
        return;
    }
    char* key = next_word(&p);
    char* arg = next_word(&p);
    if (key == nullptr || arg == nullptr || next_word(&p) != nullptr) {
        reject(REJECT_UNKNOWN_COMMAND);
        return;
    }
    uint8_t setting = SETTING_COUNT;
    for (uint8_t k = 0; k < SETTING_COUNT; k++) {
        if (strcmp(key, setting_name(k)) == 0) setting = k;
    }
    if (setting == SETTING_COUNT) {
        reject(REJECT_UNKNOWN_SETTING);
        return;
    }
    uint32_t v;
    if (!parse_number(arg, &v)) {
        reject(REJECT_BAD_VALUE, setting);
        return;
    }
    uint16_t lo = setting_min(setting, m_settings);
    uint16_t hi = setting_max(setting, m_settings);
    if (v < lo || v > hi) {
        reject(REJECT_OUT_OF_RANGE, setting, (int32_t)v, lo, hi);
        return;
    }
    m_settings.value[setting] = (uint16_t)v;
    m_cmd_out.write(command_t { CommandOp::Set, setting, (uint16_t)v });
}

void Command::run()
{
    g_console = hx_drv_uart_get_dev(USE_DW_UART_0);
    NVIC_SetPriority(UART0_intr_IRQn, CSP4CMSIS_MAX_SYSCALL_INTERRUPT_PRIORITY);
    g_console->uart_control(UART_CMD_SET_RXINT_BUF, (UART_CTRL_PARAM)nullptr);
    g_console->uart_control(UART_CMD_SET_RXCB, (UART_CTRL_PARAM)console_rx_cb);
    g_console->uart_control(UART_CMD_SET_RXINT, (UART_CTRL_PARAM)1);

    auto rx = g_rx_chan.reader();
    char line[COMMAND_LINE_MAX + 1];
    uint32_t len = 0;
    bool overlong = false;
    bool damaged = false;
    uint32_t lost_reported = 0;
    while (true) {
        uint8_t c;
        rx.read(c);
        if (c == RX_LOST_MARK) {
            damaged = true;
        } else if (c == '\r' || c == '\n') {
            if (damaged) {
                uint32_t lost = g_rx_lost;
                reject(REJECT_BYTES_LOST, 0, (int32_t)(lost - lost_reported));
                lost_reported = lost;
            } else if (overlong) {
                reject(REJECT_LINE_TOO_LONG);
            } else if (len > 0) {
                line[len] = 0;
                handle(line);
            }
            len = 0;
            overlong = false;
            damaged = false;
        } else if (len < COMMAND_LINE_MAX) {
            line[len++] = (char)c;
        } else {
            overlong = true;
        }
    }
}
