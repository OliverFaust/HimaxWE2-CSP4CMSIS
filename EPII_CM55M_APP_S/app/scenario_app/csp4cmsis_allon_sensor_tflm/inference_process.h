#ifndef INFERENCE_PROCESS_HPP
#define INFERENCE_PROCESS_HPP

#include <csp/csp4cmsis.h>
#include "common_types.h"

// 256 words = 1 KB; 480 bytes used (measured).
class Inference : public csp::CSProcessStatic<256> {
public:
    Inference(csp::Chanin<frame_t> in, csp::Chanout<report_t> report);
    void run() override;
    const char* name() const override { return "Inference"; }

private:
    csp::Chanin<frame_t>   m_frame_in;
    csp::Chanout<report_t> m_report_out;
};

#endif
