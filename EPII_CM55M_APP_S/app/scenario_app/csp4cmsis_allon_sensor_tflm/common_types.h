// common_types.h
#ifndef COMMON_TYPES_H
#define COMMON_TYPES_H

#include <stdint.h>
#include <type_traits>

struct trigger_t {};

// Describes a frame; the frame data itself stays in the sensor's buffer.
struct frame_t {
    uint32_t index;
    uint32_t jpeg_addr;
    uint32_t jpeg_sz;
};

enum class ReportKind : uint8_t {
    Started,  // initialised and running
    Failed,   // initialisation failed; code says which step
    Result,   // one frame's classification
    Stack,    // one thread's stack use (sent by MainApp every 3 s)
};

// Everything the Reporter prints arrives as a report_t.
struct report_t {
    ReportKind  kind;
    int16_t     code;      // Failed: the failing step; Result: 0 = ok, otherwise Invoke() failed
    const char* name;      // the reporting thread's name: a string literal, so only the pointer is copied
    uint32_t    index;     // Result: the frame index
    int32_t     value[3];  // Result: person score, no-person score, unused
                           // Stack:  used bytes, allocated bytes, HWM words (-1: unavailable)
};
static_assert(std::is_trivially_copyable<report_t>::value, "channel element types must be trivially copyable");

#endif // COMMON_TYPES_H
