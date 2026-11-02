#ifndef REPORTER_PROCESS_H
#define REPORTER_PROCESS_H

#include <csp/csp4cmsis.h>
#include "common_types.h"

class Reporter : public csp::CSProcessStatic<256> {
public:
    Reporter(csp::Chanin<report_t> in, csp::Chanout<uint8_t> free_out);
    void run() override;
    const char* name() const override { return "Reporter"; }

private:
    void send_image(const report_t& r);

    csp::Chanin<report_t> m_in;
    csp::Chanout<uint8_t> m_free_out;
    uint16_t m_seq;
    uint32_t m_eoi_errors;
};

#endif
