#ifndef COMMAND_PROCESS_H
#define COMMAND_PROCESS_H

#include <csp/csp4cmsis.h>
#include "common_types.h"

class Command : public csp::CSProcessStatic<256> {
public:
    Command(csp::Chanout<command_t> cmd, csp::Chanout<report_t> report);
    void run() override;
    const char* name() const override { return "Command"; }

private:
    void handle(char* line);
    void reject(int16_t reason, uint8_t setting = 0, int32_t value = 0, int32_t lo = 0, int32_t hi = 0);

    csp::Chanout<command_t> m_cmd_out;
    csp::Chanout<report_t> m_report_out;
    settings_t m_settings;
};

#endif
