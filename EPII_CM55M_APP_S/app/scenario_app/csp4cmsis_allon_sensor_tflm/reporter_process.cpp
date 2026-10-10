// reporter_process.cpp
#include "reporter_process.h"
#include "xprintf.h"

using namespace csp;

Reporter::Reporter(Chanin<report_t> in) : m_in(in)
{
}

// The only process that prints while the network runs: xprintf() has no locking.
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
        case ReportKind::Result:
            if (r.code == 0) {
                xprintf("Frame %lu: prediction = %d\n", (unsigned long)r.index, (int)r.value[0]);
            } else {
                xprintf("Frame %lu: inference failed\n", (unsigned long)r.index);
            }
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
        }
    }
}
