#ifndef COMMON_TYPES_H
#define COMMON_TYPES_H

#include <stdint.h>
#include <type_traits>

struct trigger_t {};

struct release_t {
    uint8_t buf;
};

struct frame_t {
    uint32_t index;
    uint32_t jpeg_addr;
    uint32_t jpeg_sz;
    uint8_t  buf;
};

enum class ReportKind : uint8_t {
    Started,
    Failed,
    Stack,
    Image,
    Window,
#ifdef UPLINK_STAGE0
    BufferCheck,
    BufferTail,
    BufferVerdict,
    JpegDump,
#endif
};

struct report_t {
    ReportKind  kind;
    int16_t     code;
    const char* name;
    uint32_t    index;
    int32_t     value[5];
#ifdef UPLINK_STAGE0
    uint8_t     bytes[16];
#endif
#ifdef UPLINK_SCORE_LOG
    const int8_t* scores;
#endif
};
static_assert(std::is_trivially_copyable<report_t>::value, "channel element types must be trivially copyable");

#endif
