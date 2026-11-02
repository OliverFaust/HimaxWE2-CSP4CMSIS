#include "inference_process.h"
#include "cvapp.h"
#include "uplink.h"

using namespace csp;

Inference::Inference(Chanin<frame_t> in, Chanout<release_t> release, Chanout<report_t> report)
    : m_frame_in(in), m_release_out(release), m_report_out(report) {}

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

    uint32_t first = f.index;
    uint32_t best_index = f.index;
    int8_t best_score = INT8_MIN;

    while (true) {
        cv_prepare();
        m_release_out.write(release_t {});

        int8_t person_score = 0, no_person_score = 0;
        int status = cv_invoke(&person_score, &no_person_score);

        if (status != 0) {
            r = {};
            r.kind = ReportKind::Result;
            r.name = name();
            r.code = (int16_t)status;
            r.index = f.index;
            m_report_out.write(r);
        } else if (person_score > best_score) {
            best_score = person_score;
            best_index = f.index;
        }

        if (f.index % UPLINK_WINDOW == UPLINK_WINDOW - 1) {
            r = {};
            r.kind = ReportKind::Window;
            r.name = name();
            r.code = 0;
            r.index = f.index / UPLINK_WINDOW;
            r.value[0] = (int32_t)first;
            r.value[1] = (int32_t)f.index;
            r.value[2] = (int32_t)best_index;
            r.value[3] = best_score;
            m_report_out.write(r);
#ifndef UPLINK_STAGE0
            r = {};
            r.kind = ReportKind::Image;
            r.name = name();
            r.index = f.index;
            r.value[0] = (int32_t)f.jpeg_addr;
            r.value[1] = (int32_t)f.jpeg_sz;
            r.value[2] = (int32_t)(f.index / UPLINK_WINDOW);
            r.value[3] = person_score;
            m_report_out.write(r);
#endif
            first = f.index + 1;
            best_index = first;
            best_score = INT8_MIN;
        }

        m_frame_in.read(f);
    }
}
