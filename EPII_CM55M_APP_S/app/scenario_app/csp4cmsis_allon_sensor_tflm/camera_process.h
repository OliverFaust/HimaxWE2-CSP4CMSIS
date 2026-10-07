#ifndef CAMERA_PROCESS_HPP
#define CAMERA_PROCESS_HPP

#include <csp/csp4cmsis.h>
#include "common_types.h"
#include "cisdp_sensor.h"

// Stack depth in words, fixed at compile time via CSProcessStatic<N>.
// Measured on the board with CSP4CMSIS 2.0.1: 744 bytes used (as before 2.0,
// when it had 1024 bytes and 280 left). 384 words = 1.5 KB leaves about 800.
class Camera : public csp::CSProcessStatic<384> {
public:
    Camera(csp::Chanout<frame_t> out, csp::Chanout<report_t> report);
    void run() override;
    const char* name() const override { return "Camera"; }

private:
    csp::Chanout<frame_t> m_frame_out;
    csp::Chanout<report_t> m_report_out;
    uint32_t m_frame_counter;
};

#ifdef __cplusplus
extern "C" {
#endif
    void os_app_dplib_cb(SENSORDPLIB_STATUS_E event);
#ifdef __cplusplus
}
#endif

#endif