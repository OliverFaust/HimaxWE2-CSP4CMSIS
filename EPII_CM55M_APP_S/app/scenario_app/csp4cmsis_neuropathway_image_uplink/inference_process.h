#ifndef INFERENCE_PROCESS_HPP
#define INFERENCE_PROCESS_HPP

#include <csp/csp4cmsis.h>
#include "common_types.h"

class Inference : public csp::CSProcessStatic<512> {
public:
    Inference(csp::Chanin<frame_t> in, csp::Chanout<release_t> release, csp::Chanin<uint8_t> free_in,
              csp::Chanin<uint8_t> ready_in, csp::Chanout<report_t> report);
    void run() override;
    const char* name() const override { return "Inference"; }

private:
    csp::Chanin<frame_t>   m_frame_in;
    csp::Chanout<release_t> m_release_out;
    csp::Chanin<uint8_t>   m_free_in;
    csp::Chanin<uint8_t>   m_ready_in;
    csp::Chanout<report_t> m_report_out;
};

#endif
