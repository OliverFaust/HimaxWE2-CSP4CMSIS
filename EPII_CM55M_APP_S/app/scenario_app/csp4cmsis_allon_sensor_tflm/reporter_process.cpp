// reporter_process.cpp
#include "reporter_process.h"
#include "cmsis_os2.h"
#include "xprintf.h"

using namespace csp;

// The processes run forever, so there is no natural "network finished" point to report
// stack usage at -- report periodically instead. This is a live worst-observed-so-far
// reading, trustworthy only once each process's deepest call path has been exercised.
#ifndef CSP_STACK_REPORT_INTERVAL_MS
#define CSP_STACK_REPORT_INTERVAL_MS (3000)
#endif

static const char* sourceName(ReportSource s)
{
    switch (s) {
    case ReportSource::Camera:    return "Camera";
    case ReportSource::Inference: return "Inference";
    }
    return "?";
}

Reporter::Reporter(Chanin<report_t> in, CSProcess* const* others, size_t other_count)
    : m_in(in), m_others(others), m_other_count(other_count)
{
}

void Reporter::run()
{
    const uint32_t interval = (uint32_t)((uint64_t)CSP_STACK_REPORT_INTERVAL_MS * osKernelGetTickFreq() / 1000U);
    uint32_t last_stack_report = osKernelGetTickCount();

    while (true) {
        report_t r;
        m_in >> r;
        print(r);

        // The stack report is printed here, between two reports, so that it cannot
        // interleave with anything: no other process prints.
        uint32_t now = osKernelGetTickCount();
        if (now - last_stack_report >= interval) {
            last_stack_report = now;
            printStackReport();
        }
    }
}

void Reporter::print(const report_t& r)
{
    switch (r.kind) {
    case ReportKind::Started:
        xprintf("%s: started\r\n", sourceName(r.source));
        break;
    case ReportKind::Failed:
        xprintf("%s: initialisation FAILED (step %d)\r\n", sourceName(r.source), (int)r.code);
        break;
    case ReportKind::Result:
        if (r.code == 0) {
            xprintf("Frame %lu: prediction = %d\n", (unsigned long)r.index, (int)r.value[0]);
        } else {
            xprintf("Frame %lu: inference failed\n", (unsigned long)r.index);
        }
        break;
    }
}

static void printStack(CSProcess& p)
{
    size_t allocated_bytes = p.stackWords() * sizeof(uint32_t);
    uint32_t hwm = p.stackHighWaterMarkWords();
    if (hwm == CSP_STACK_HWM_UNAVAILABLE) {
        xprintf("%s: allocated = %u bytes, HWM unavailable\r\n", p.name(), (unsigned)allocated_bytes);
        return;
    }
    size_t unused_bytes = hwm * sizeof(uint32_t);
    size_t used_bytes = (unused_bytes <= allocated_bytes) ? allocated_bytes - unused_bytes : 0;
    xprintf("%s: %u/%u bytes used (%u bytes unused headroom, %u words HWM)\r\n",
            p.name(), (unsigned)used_bytes, (unsigned)allocated_bytes,
            (unsigned)unused_bytes, (unsigned)hwm);
}

void Reporter::printStackReport()
{
    for (size_t i = 0; i < m_other_count; i++) {
        printStack(*m_others[i]);
    }
    printStack(*this);
}
