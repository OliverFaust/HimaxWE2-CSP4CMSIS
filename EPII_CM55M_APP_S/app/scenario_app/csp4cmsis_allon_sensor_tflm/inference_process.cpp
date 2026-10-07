#include "inference_process.h"
#include "cvapp.h"          // for cv_init, cv_run

using namespace csp;

Inference::Inference(Chanin<frame_t> in, Chanout<report_t> report)
    : m_frame_in(in), m_report_out(report) {}

void Inference::run()
{
    // Inference does not print: it reports to the Reporter. It initialises the model only
    // when the first frame has arrived, i.e. after Camera has started: the camera driver
    // prints its own start-up log, and this keeps that log from overlapping with anything.
    frame_t f;
    m_frame_in.read(f);

    report_t r = {};
    r.source = ReportSource::Inference;

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
        // cv_run() reads directly from the raw sensor buffer, not the
        // JPEG buffer -- a model expecting JPEG input would need a
        // decode step here first.
        int8_t person_score = 0, no_person_score = 0;
        int status = cv_run(&person_score, &no_person_score);

        r = {};
        r.kind = ReportKind::Result;
        r.source = ReportSource::Inference;
        r.code = (int16_t)status;
        r.index = f.index;
        r.value[0] = person_score;
        r.value[1] = no_person_score;
        m_report_out.write(r);

        m_frame_in.read(f);
    }
}
