#ifndef REPORTER_PROCESS_H
#define REPORTER_PROCESS_H

#include <csp/csp4cmsis.h>
#include "common_types.h"    // for report_t

// The only process that prints while the network runs: it reads reports from one
// rendezvous channel (writers: Camera, Inference, MainApp) and prints each one as one line.
// It keeps no state and no timer: the stack report is MainApp's, so it does not depend on
// report traffic. 256 words (1 KB), as the earlier Console: measured on the board, it uses
// 408 bytes.
class Reporter : public csp::CSProcessStatic<256> {
public:
    explicit Reporter(csp::Chanin<report_t> in);
    void run() override;
    const char* name() const override { return "Reporter"; }

private:
    csp::Chanin<report_t> m_in;
};

#endif // REPORTER_PROCESS_H
