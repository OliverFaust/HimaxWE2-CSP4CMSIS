#ifndef REPORTER_PROCESS_H
#define REPORTER_PROCESS_H

#include <csp/csp4cmsis.h>
#include "common_types.h"

class Reporter : public csp::CSProcessStatic<256> {
public:
    Reporter(csp::Chanin<report_t> in, csp::Chanout<uint8_t> free_out, csp::Chanout<uint8_t> ready_out);
    void run() override;
    const char* name() const override { return "Reporter"; }

private:
    void send_image(uint32_t frame, int8_t score, uint32_t window, uint32_t jpeg_addr, uint32_t jpeg_sz);
    void print_scores(const score_batch_t* b);
    void print_window(const report_t& r);

    csp::Chanin<report_t> m_in;
    csp::Chanout<uint8_t> m_free_out;
    csp::Chanout<uint8_t> m_ready_out;
    uint16_t m_seq;
    uint32_t m_eoi_errors;
};

#endif
