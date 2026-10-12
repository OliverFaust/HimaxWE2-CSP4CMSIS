#ifndef REPORTER_PROCESS_H
#define REPORTER_PROCESS_H

#include <csp/csp4cmsis.h>
#include "common_types.h"

class Reporter : public csp::CSProcessStatic<256> {
public:
    explicit Reporter(csp::Chanin<report_t> in);
    void run() override;
    const char* name() const override { return "Reporter"; }

private:
    csp::Chanin<report_t> m_in;
};

#endif
