#ifndef REPORTER_PROCESS_H
#define REPORTER_PROCESS_H

#include <csp/csp4cmsis.h>
#include "common_types.h"    // for report_t

// Prints each report as one line. 256 words = 1 KB; about 430 bytes used (measured).
class Reporter : public csp::CSProcessStatic<256> {
public:
    explicit Reporter(csp::Chanin<report_t> in);
    void run() override;
    const char* name() const override { return "Reporter"; }

private:
    csp::Chanin<report_t> m_in;
};

#endif // REPORTER_PROCESS_H
