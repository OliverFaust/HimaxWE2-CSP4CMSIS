#ifndef COMMON_TYPES_H
#define COMMON_TYPES_H

#include <stdint.h>
#include <type_traits>

struct trigger_t {};

struct release_t {
    uint8_t buf;
};

enum Setting : uint8_t {
    SETTING_AGAIN,
    SETTING_DGAIN,
    SETTING_EXPOSURE,
    SETTING_FRAMELEN,
    SETTING_WINDOW,
    SETTING_COUNT,
};

static constexpr uint8_t SETTINGS_GET = 1u << 7;

struct settings_t {
    uint16_t value[SETTING_COUNT];
};

enum class CommandOp : uint8_t {
    Set,
    Get,
};

struct command_t {
    CommandOp op;
    uint8_t   setting;
    uint16_t  value;
};

struct frame_t {
    uint32_t   index;
    uint32_t   jpeg_addr;
    uint32_t   jpeg_sz;
    uint8_t    buf;
    uint8_t    changed;
    uint8_t    failed;
    settings_t settings;
};

enum class ReportKind : uint8_t {
    Started,
    Failed,
    Stack,
    Image,
    Window,
    Applied,
    Settings,
    Rejected,
#ifdef UPLINK_STAGE0
    BufferCheck,
    BufferTail,
    BufferVerdict,
    JpegDump,
#endif
};

enum RejectReason : int16_t {
    REJECT_UNKNOWN_COMMAND = 1,
    REJECT_UNKNOWN_SETTING,
    REJECT_BAD_VALUE,
    REJECT_OUT_OF_RANGE,
    REJECT_LINE_TOO_LONG,
    REJECT_BYTES_LOST,
};

struct report_t {
    ReportKind  kind;
    int16_t     code;
    const char* name;
    uint32_t    index;
    int32_t     value[7];
#ifdef UPLINK_STAGE0
    uint8_t     bytes[16];
#endif
#ifdef UPLINK_SCORE_LOG
    const int8_t* scores;
    uint8_t     score_count;
#endif
};
static_assert(std::is_trivially_copyable<report_t>::value, "channel element types must be trivially copyable");
static_assert(std::is_trivially_copyable<frame_t>::value, "channel element types must be trivially copyable");
static_assert(std::is_trivially_copyable<command_t>::value, "channel element types must be trivially copyable");

#endif
