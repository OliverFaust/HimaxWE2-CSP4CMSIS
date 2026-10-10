#include "inference_process.h"
#include "cvapp.h"          // for cv_init, cv_run

using namespace csp;

Inference::Inference(Chanin<frame_t> in, Chanout<report_t> report)
    : m_frame_in(in), m_report_out(report) {}

void Inference::run()
{
    // The model is initialised only after the first frame, i.e. after Camera has started, so
    // that nothing is reported while the camera driver prints its start-up log.
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

    while (true) {
        // cv_run() reads the raw sensor buffer, not the JPEG.
        int8_t person_score = 0, no_person_score = 0;
        int status = cv_run(&person_score, &no_person_score);

        r = {};
        r.kind = ReportKind::Result;
        r.name = name();
        r.code = (int16_t)status;
        r.index = f.index;
        r.value[0] = person_score;
        r.value[1] = no_person_score;
        m_report_out.write(r);

        m_frame_in.read(f);
    }
}
