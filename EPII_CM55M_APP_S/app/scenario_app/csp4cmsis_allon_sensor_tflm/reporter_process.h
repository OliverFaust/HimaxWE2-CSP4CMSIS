#ifndef REPORTER_PROCESS_H
#define REPORTER_PROCESS_H

#include <stddef.h>
#include <csp/csp4cmsis.h>
#include "common_types.h"    // for report_t

// The only process that prints while the network runs: it reads the other processes'
// reports from one rendezvous channel (several writers) and prints them, and it prints the
// stack report every CSP_STACK_REPORT_INTERVAL_MS. 256 words (1 KB), as the earlier Console:
// measured on the board, it uses 408 bytes.
class Reporter : public csp::CSProcessStatic<256> {
public:
    // others: the processes whose stacks the stack report lists, besides the Reporter itself.
    Reporter(csp::Chanin<report_t> in, csp::CSProcess* const* others, size_t other_count);
    void run() override;
    const char* name() const override { return "Reporter"; }

private:
    void print(const report_t& r);
    void printStackReport();

    csp::Chanin<report_t> m_in;
    csp::CSProcess* const* m_others;
    size_t m_other_count;
};

#endif // REPORTER_PROCESS_H
