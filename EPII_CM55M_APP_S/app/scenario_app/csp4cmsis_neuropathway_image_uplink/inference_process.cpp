#include "inference_process.h"
#include "cvapp.h"
#include "uplink.h"

using namespace csp;

static score_batch_t g_batch[2];

Inference::Inference(Chanin<frame_t> in, Chanout<release_t> release, Chanin<uint8_t> free_in,
                     Chanin<uint8_t> ready_in, Chanout<report_t> report)
    : m_frame_in(in), m_release_out(release), m_free_in(free_in), m_ready_in(ready_in), m_report_out(report) {}

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
    r = {};
    r.kind = ReportKind::Model;
    r.name = name();
    cv_output_quant(&r.value[0], &r.value[1], &r.value[2]);
    m_report_out.write(r);

    uint8_t spare[UPLINK_BUFFERS];
    uint8_t spares = 0;
    for (uint8_t id = 0; id < UPLINK_BUFFERS; id++) {
        if (id != f.buf) spare[spares++] = id;
    }

    uint8_t returned = 0;
    uint8_t token = 0;
    RelTimeoutGuard skip(Milliseconds(0));
    Alternative poll_free(m_free_in | returned, skip);
    Alternative poll_ready(m_ready_in | token, skip);
    bool uplink_free = true;
    bool ready = true;

    settings_t settings = f.settings;
    uint32_t window_size = settings.value[SETTING_WINDOW];
    int32_t threshold = setting_value(SETTING_THRESHOLD, settings);
    uint32_t k_needed = settings.value[SETTING_K];
    uint32_t window_id = f.index / window_size;
    uint32_t pos = 0;
    uint8_t requested = 0;
    uint8_t pending = 0;
    uint8_t pending_failed = 0;
    uint32_t applied_at[SETTING_COUNT] = {};
    uint64_t y_sum = 0;
    uint32_t y_pixels = 0;
    uint32_t y_clipped = 0;

    uint8_t filling = 0;
    g_batch[filling].first = f.index;
    g_batch[filling].count = 0;
    int32_t scores_lost = 0;
    int32_t suppressed = 0;
    int32_t eoi_errors = 0;

    uint32_t first = f.index;
    int16_t merged = 0;
    int32_t failed = 0;
    int32_t above = 0;
    bool have_best = false;
    frame_t best = {};
    int8_t best_score = 0;

    while (true) {
        if (poll_free.priSelect() == 0) {
            spare[spares++] = returned;
            uplink_free = true;
        }
        if (poll_ready.priSelect() == 0) ready = true;

        cv_prepare((const uint8_t*)(uintptr_t)f.raw_addr, f.raw_w, f.raw_h);
        m_release_out.write(release_t { spare[--spares] });

        uint32_t sum, clipped;
        y_pixels += cv_input_stats(&sum, &clipped);
        y_sum += sum;
        y_clipped += clipped;

        for (uint8_t k = 0; k < SETTING_COUNT; k++) {
            uint8_t bit = (uint8_t)(1u << k);
            if (!(f.changed & bit)) continue;
            if (k == SETTING_WINDOW || k == SETTING_THRESHOLD || k == SETTING_K) {
                requested |= bit;
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

        score_batch_t& b = g_batch[filling];
        if (b.count < SCORE_BATCH) {
            b.person[b.count] = person_score;
            b.no_person[b.count] = no_person_score;
            b.count++;
        } else {
            scores_lost++;
        }

        if (f.jpeg_len == 0) eoi_errors++;
        if (status != 0) {
            failed++;
            spare[spares++] = f.buf;
        } else {
            if (person_score >= threshold) above++;
            if (f.jpeg_len != 0 && (!have_best || person_score > best_score)) {
                if (have_best) spare[spares++] = best.buf;
                best = f;
                best_score = person_score;
                have_best = true;
            } else {
                spare[spares++] = f.buf;
            }
        }

        bool window_end = (++pos == window_size);
        bool reported = false;
        if (ready) {
            r = {};
            r.name = name();
            if (window_end && uplink_free) {
                bool send = have_best && best_score >= threshold && (uint32_t)above >= k_needed;
                r.kind = ReportKind::Window;
                r.code = merged;
                r.index = window_id;
                r.value[WV_FIRST] = (int32_t)first;
                r.value[WV_LAST] = (int32_t)f.index;
                r.value[WV_BEST] = have_best ? (int32_t)best.index : -1;
                r.value[WV_SCORE] = best_score;
                r.value[WV_FAILED] = failed;
                r.value[WV_Y] = (int32_t)(y_sum * 10 / y_pixels);
                r.value[WV_CLIP] = (int32_t)((uint64_t)y_clipped * 10000 / y_pixels);
                r.value[WV_ABOVE] = above;
#ifdef UPLINK_STAGE0
                send = false;
#endif
                if (!send) suppressed++;
                r.value[WV_SENT] = send ? 1 : 0;
                r.value[WV_SUPPRESSED] = suppressed;
                r.value[WV_LOST] = scores_lost;
                r.value[WV_EOI] = eoi_errors;
                if (send) {
                    r.value[WV_JPEG_ADDR] = (int32_t)best.jpeg_addr;
                    r.value[WV_JPEG_LEN] = (int32_t)best.jpeg_len;
                    r.value[WV_BUF] = best.buf;
                    uplink_free = false;
                } else if (have_best) {
                    spare[spares++] = best.buf;
                }
                have_best = false;
                first = f.index + 1;
                merged = 0;
                failed = 0;
                above = 0;
                y_sum = 0;
                y_pixels = 0;
                y_clipped = 0;
                reported = true;
            } else if (pending) {
                uint8_t k = 0;
                while (k < SETTING_COUNT && !(pending & (1u << k))) k++;
                if (k < SETTING_COUNT) {
                    uint8_t bit = (uint8_t)(1u << k);
                    bool own = (k == SETTING_WINDOW || k == SETTING_THRESHOLD || k == SETTING_K);
                    r.kind = ReportKind::Applied;
                    r.name = own ? name() : "Camera";
                    r.code = (pending_failed & bit) ? 1 : 0;
                    r.index = applied_at[k];
                    r.value[0] = k;
                    r.value[1] = (k == SETTING_WINDOW) ? (int32_t)window_size
                               : (k == SETTING_THRESHOLD) ? threshold
                               : (k == SETTING_K) ? (int32_t)k_needed : setting_value(k, settings);
                    pending &= (uint8_t)~bit;
                    pending_failed &= (uint8_t)~bit;
                } else {
                    r.kind = ReportKind::Settings;
                    r.name = "Camera";
                    for (uint8_t j = 0; j < SETTING_COUNT; j++) r.value[j] = setting_value(j, settings);
                    r.value[SETTING_WINDOW] = (int32_t)window_size;
                    r.value[SETTING_THRESHOLD] = threshold;
                    r.value[SETTING_K] = (int32_t)k_needed;
                    pending &= (uint8_t)~SETTINGS_GET;
                }
            } else {
                r.kind = ReportKind::Scores;
            }
            r.batch = &g_batch[filling];
            m_report_out.write(r);
            ready = false;
            filling ^= 1;
            g_batch[filling].first = f.index + 1;
            g_batch[filling].count = 0;
        }

        if (window_end) {
            if (!reported && merged < INT16_MAX) merged++;
            pos = 0;
            window_id++;
            if (requested & (1u << SETTING_WINDOW)) {
                window_size = settings.value[SETTING_WINDOW];
                pending |= (uint8_t)(1u << SETTING_WINDOW);
                applied_at[SETTING_WINDOW] = f.index + 1;
            }
            if (requested & (1u << SETTING_THRESHOLD)) {
                threshold = setting_value(SETTING_THRESHOLD, settings);
                pending |= (uint8_t)(1u << SETTING_THRESHOLD);
                applied_at[SETTING_THRESHOLD] = f.index + 1;
            }
            if (requested & (1u << SETTING_K)) {
                k_needed = settings.value[SETTING_K];
                pending |= (uint8_t)(1u << SETTING_K);
                applied_at[SETTING_K] = f.index + 1;
            }
            requested = 0;
        }

        m_frame_in.read(f);
    }
}
