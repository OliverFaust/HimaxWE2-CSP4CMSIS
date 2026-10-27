#ifndef COMMON_TYPES_H
#define COMMON_TYPES_H

#include <stdint.h>
#include <type_traits>

struct trigger_t {};

struct frame_t {
    uint32_t index;
    uint32_t jpeg_addr;
    uint32_t jpeg_sz;
};

enum class ReportKind : uint8_t {
    Started,
    Failed,
    Result,
    Stack,
    BufferCheck,
    BufferVerdict,
    JpegDump,
};

struct report_t {
    ReportKind  kind;
    int16_t     code;
    const char* name;
    uint32_t    index;
    int32_t     value[3];
};
static_assert(std::is_trivially_copyable<report_t>::value, "channel element types must be trivially copyable");

#endif
