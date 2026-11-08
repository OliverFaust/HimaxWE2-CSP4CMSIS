#ifndef SD_BENCH_PROCESS_H
#define SD_BENCH_PROCESS_H

#include <csp/csp4cmsis.h>
#include "common_types.h"

class SdBench : public csp::CSProcessStatic<512> {
public:
    explicit SdBench(csp::Chanout<report_t> report);
    void run() override;
    const char* name() const override { return "SdBench"; }

private:
    csp::Chanout<report_t> m_report_out;
};

#endif
