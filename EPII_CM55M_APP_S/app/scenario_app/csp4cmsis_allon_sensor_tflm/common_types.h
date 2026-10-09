// common_types.h
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

// One report to the Reporter, the only process that prints while the network runs: the
// console is a shared resource, and xprintf() has no locking, so two printing processes
// would tear each other's lines. Every other process sends what it has to say as a
// report_t over one rendezvous channel with several writers (Camera, Inference, MainApp);
// the Reporter owns the format.
enum class ReportSource : uint8_t { Camera, Inference, Reporter, Main };
enum class ReportKind : uint8_t {
    Started,  // the process has initialised its hardware and is running
    Failed,   // initialisation failed; code says which step
    Result,   // one frame's classification (Inference)
    Stack,    // one thread's stack use (MainApp, every 3 s); source says whose
};

struct report_t {
    ReportKind   kind;
    ReportSource source;
    int16_t      code;      // Failed: the failing step's code; Result: 0 = ok, otherwise Invoke() failed
    uint32_t     index;     // Result: the frame index
    int32_t      value[3];  // Result: [0] person score, [1] no-person score, [2] unused (0)
                            // Stack:  [0] used bytes, [1] allocated bytes, [2] HWM words (-1: unavailable)
};
static_assert(std::is_trivially_copyable<report_t>::value, "channel element types must be trivially copyable");

#endif // COMMON_TYPES_H
