#include "inference_process.h"
#include "cvapp.h"
#include "uplink.h"

using namespace csp;

Inference::Inference(Chanin<frame_t> in, Chanout<release_t> release, Chanin<uint8_t> free_in,
                     Chanout<report_t> report)
    : m_frame_in(in), m_release_out(release), m_free_in(free_in), m_report_out(report) {}

void Inference::run()
{
    frame_t f;
    m_frame_in.read(f);

    report_t r = {};
    r.name = name();

    int err = cv_init(true, true);
    if (err < 0) {
        r.kind = ReportKind::Failed;
        r.code = (int16_t)err;
        m_report_out.write(r);
        return;
    }
    r.kind = ReportKind::Started;
    m_report_out.write(r);

    uint8_t spare[UPLINK_BUFFERS];
    uint8_t spares = 0;
    for (uint8_t id = 0; id < UPLINK_BUFFERS; id++) {
        if (id != f.buf) spare[spares++] = id;
    }

    uint8_t returned = 0;
    RelTimeoutGuard skip(Milliseconds(0));
    Alternative poll_free(m_free_in | returned, skip);
    bool uplink_free = true;

    uint32_t first = f.index;
    int16_t merged = 0;
    int32_t failed = 0;
    bool have_best = false;
    frame_t best = {};
    int8_t best_score = 0;

    while (true) {
        if (poll_free.priSelect() == 0) {
            spare[spares++] = returned;
            uplink_free = true;
        }

        cv_prepare();
        m_release_out.write(release_t { spare[--spares] });

        int8_t person_score = 0, no_person_score = 0;
        int status = cv_invoke(&person_score, &no_person_score);

        if (status != 0) {
            failed++;
            spare[spares++] = f.buf;
        } else if (!have_best || person_score > best_score) {
            if (have_best) spare[spares++] = best.buf;
            best = f;
            best_score = person_score;
            have_best = true;
        } else {
            spare[spares++] = f.buf;
        }

        if (f.index % UPLINK_WINDOW == UPLINK_WINDOW - 1) {
            if (uplink_free) {
                r = {};
                r.kind = ReportKind::Window;
                r.name = name();
                r.code = merged;
                r.index = f.index / UPLINK_WINDOW;
                r.value[0] = (int32_t)first;
                r.value[1] = (int32_t)f.index;
                r.value[2] = have_best ? (int32_t)best.index : -1;
                r.value[3] = best_score;
                r.value[4] = failed;
                m_report_out.write(r);
                if (have_best) {
#ifndef UPLINK_STAGE0
                    r = {};
                    r.kind = ReportKind::Image;
                    r.name = name();
                    r.code = best.buf;
                    r.index = best.index;
                    r.value[0] = (int32_t)best.jpeg_addr;
                    r.value[1] = (int32_t)best.jpeg_sz;
                    r.value[2] = (int32_t)(f.index / UPLINK_WINDOW);
                    r.value[3] = best_score;
                    m_report_out.write(r);
                    uplink_free = false;
#else
                    spare[spares++] = best.buf;
#endif
                    have_best = false;
                }
                first = f.index + 1;
                merged = 0;
                failed = 0;
            } else {
                merged++;
            }
        }

        m_frame_in.read(f);
    }
}
