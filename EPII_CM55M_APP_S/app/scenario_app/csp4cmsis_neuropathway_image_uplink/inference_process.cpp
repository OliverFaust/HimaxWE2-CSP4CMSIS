#include "inference_process.h"
#include "cvapp.h"
#include "uplink.h"

using namespace csp;

#ifdef UPLINK_SCORE_LOG
static int8_t g_scores[2][2 * UPLINK_WINDOW];
#endif

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

    settings_t settings = f.settings;
    uint32_t window_size = settings.value[SETTING_WINDOW];
    uint32_t window_id = f.index / window_size;
    uint32_t pos = 0;
    bool window_requested = false;
    uint8_t pending = 0;
    uint8_t pending_failed = 0;
    uint32_t applied_at[SETTING_COUNT] = {};
    uint64_t y_sum = 0;
    uint32_t y_pixels = 0;
    uint32_t y_clipped = 0;

    uint32_t first = f.index;
    int16_t merged = 0;
    int32_t failed = 0;
    bool have_best = false;
    frame_t best = {};
    int8_t best_score = 0;
#ifdef UPLINK_SCORE_LOG
    uint8_t log_block = 0;
#endif

    while (true) {
        if (poll_free.priSelect() == 0) {
            spare[spares++] = returned;
            uplink_free = true;
        }

        cv_prepare();
        m_release_out.write(release_t { spare[--spares] });

        uint32_t sum, clipped;
        y_pixels += cv_input_stats(&sum, &clipped);
        y_sum += sum;
        y_clipped += clipped;

        for (uint8_t k = 0; k < SETTING_COUNT; k++) {
            uint8_t bit = (uint8_t)(1u << k);
            if (!(f.changed & bit)) continue;
            if (k == SETTING_WINDOW) {
                window_requested = true;
                continue;
            }
            pending |= bit;
            applied_at[k] = f.index;
            if (f.failed & bit) pending_failed |= bit;
            else pending_failed &= (uint8_t)~bit;
        }
        if (f.changed & SETTINGS_GET) pending |= SETTINGS_GET;
        settings = f.settings;

        int8_t person_score = 0, no_person_score = 0;
        int status = cv_invoke(&person_score, &no_person_score);
#ifdef UPLINK_SCORE_LOG
        g_scores[log_block][pos] = person_score;
        g_scores[log_block][UPLINK_WINDOW + pos] = no_person_score;
#endif

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

        if (++pos == window_size) {
            if (uplink_free) {
                r = {};
                r.kind = ReportKind::Window;
                r.name = name();
                r.code = merged;
                r.index = window_id;
                r.value[0] = (int32_t)first;
                r.value[1] = (int32_t)f.index;
                r.value[2] = have_best ? (int32_t)best.index : -1;
                r.value[3] = best_score;
                r.value[4] = failed;
                r.value[5] = (int32_t)(y_sum * 10 / y_pixels);
                r.value[6] = (int32_t)((uint64_t)y_clipped * 10000 / y_pixels);
#ifdef UPLINK_SCORE_LOG
                r.scores = g_scores[log_block];
                r.score_count = (uint8_t)window_size;
                log_block ^= 1;
#endif
                m_report_out.write(r);
                for (uint8_t k = 0; k < SETTING_COUNT; k++) {
                    uint8_t bit = (uint8_t)(1u << k);
                    if (!(pending & bit)) continue;
                    r = {};
                    r.kind = ReportKind::Applied;
                    r.name = (k == SETTING_WINDOW) ? name() : "Camera";
                    r.code = (pending_failed & bit) ? 1 : 0;
                    r.index = applied_at[k];
                    r.value[0] = k;
                    r.value[1] = (k == SETTING_WINDOW) ? (int32_t)window_size : settings.value[k];
                    m_report_out.write(r);
                }
                if (pending & SETTINGS_GET) {
                    r = {};
                    r.kind = ReportKind::Settings;
                    r.name = "Camera";
                    for (uint8_t k = 0; k < SETTING_COUNT; k++) r.value[k] = settings.value[k];
                    r.value[SETTING_WINDOW] = (int32_t)window_size;
                    m_report_out.write(r);
                }
                pending = 0;
                pending_failed = 0;
                if (have_best) {
#ifndef UPLINK_STAGE0
                    r = {};
                    r.kind = ReportKind::Image;
                    r.name = name();
                    r.code = best.buf;
                    r.index = best.index;
                    r.value[0] = (int32_t)best.jpeg_addr;
                    r.value[1] = (int32_t)best.jpeg_sz;
                    r.value[2] = (int32_t)window_id;
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
                y_sum = 0;
                y_pixels = 0;
                y_clipped = 0;
            } else {
                if (merged < INT16_MAX) merged++;
            }
            pos = 0;
            window_id++;
            if (window_requested) {
                window_size = settings.value[SETTING_WINDOW];
                window_requested = false;
                pending |= (uint8_t)(1u << SETTING_WINDOW);
                applied_at[SETTING_WINDOW] = f.index + 1;
            }
        }

        m_frame_in.read(f);
    }
}
