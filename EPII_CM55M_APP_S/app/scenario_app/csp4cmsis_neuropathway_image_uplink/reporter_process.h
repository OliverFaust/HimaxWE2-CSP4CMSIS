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
    void send_image(const report_t& r);

    csp::Chanin<report_t> m_in;
    uint16_t m_seq;
    uint32_t m_eoi_errors;
};

#endif
