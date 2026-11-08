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
    SETTING_THRESHOLD,
    SETTING_K,
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

static constexpr uint32_t SCORE_BATCH = 64;

struct score_batch_t {
    uint32_t first;
    uint32_t count;
    int8_t   person[SCORE_BATCH];
    int8_t   no_person[SCORE_BATCH];
};

struct frame_t {
    uint32_t   index;
    uint32_t   jpeg_addr;
    uint32_t   jpeg_len;
    uint32_t   raw_addr;
    uint16_t   raw_w;
    uint16_t   raw_h;
    uint8_t    buf;
    uint8_t    changed;
    uint8_t    failed;
    settings_t settings;
};

enum class ReportKind : uint8_t {
    Started,
    Failed,
    Stack,
    Window,
    Scores,
    Model,
    Applied,
    Settings,
    Rejected,
    SdMount,
    SdBench,
    SdBenchDone,
    SdSectors,
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

enum WindowValue : uint8_t {
    WV_FIRST,
    WV_LAST,
    WV_BEST,
    WV_SCORE,
    WV_FAILED,
    WV_Y,
    WV_CLIP,
    WV_ABOVE,
    WV_SENT,
    WV_SUPPRESSED,
    WV_LOST,
    WV_EOI,
    WV_JPEG_ADDR,
    WV_JPEG_LEN,
    WV_BUF,
    WV_COUNT,
};

struct report_t {
    ReportKind  kind;
    int16_t     code;
    const char* name;
    uint32_t    index;
    int32_t     value[WV_COUNT];
    const score_batch_t* batch;
#ifdef UPLINK_STAGE0
    uint8_t     bytes[16];
#endif
};
static_assert(std::is_trivially_copyable<report_t>::value, "channel element types must be trivially copyable");
static_assert(std::is_trivially_copyable<frame_t>::value, "channel element types must be trivially copyable");
static_assert(std::is_trivially_copyable<command_t>::value, "channel element types must be trivially copyable");

#endif
