#ifndef SCENARIO_KWS_CVAPP
#define SCENARIO_KWS_CVAPP

#include "spi_protocol.h"
#include "cmsis_os2.h"

#ifdef __cplusplus
extern "C" {
#endif

// ---- Legacy monolithic path -------------------------------------------
// Kept for reference; no longer called by the production pipeline, which
// now uses the split preprocess/infer functions below to enable
// double-buffered MFCC pipelining (see cvapp_kws.cpp for the rationale).
extern uint32_t g_kws_algo_tick;
int cv_kws_init(bool security_enable, bool privilege_enable, uint32_t model_addr);
int cv_kws_run(struct_kws_algoResult *algoresult_kws_pdm_record, int16_t *audio_buf, int32_t audio_clip_length, void (*callback)(void));
int cv_kws_deinit();

// ---- Split preprocessing/inference path (current production pipeline) --

// Call once, after cv_kws_init(), before any cv_kws_preprocess_step() call.
// Allocates persistent MFCC/tensor state (feature tensor working buffer,
// two handoff buffers, tail-sample buffer).
int cv_kws_preprocess_init();

// Feed ONE new 0.25 s quarter-buffer (4000 int16_t samples) into the
// persistent incremental MFCC pipeline. Internally maintains a 320-sample
// tail across calls for frame-boundary lookback (frameLength - frameStride).
// Returns a pointer to a completed, ready-to-infer feature tensor once the
// window is fully populated with real audio (from the 4th call onward);
// returns nullptr for the first 3 calls after (re)initialisation, since the
// model's 98-frame window cannot yet be validly formed from real audio (any
// earlier Invoke() would run on a partly zero-padded window).
// The returned pointer is one of two internally ping-ponged handoff buffers
// and remains valid until the call-after-next, matching the double-buffering
// discipline used elsewhere in this pipeline.
void *cv_kws_preprocess_step(const int16_t *newQuarterBuffer);

// Given a tensor pointer previously returned by cv_kws_preprocess_step(),
// copies it into the model's live input tensor, runs Invoke(), and performs
// classification postprocessing/reporting (kws_report_detection/none).
// Returns 0 on success, -1 on failure (invoke failure or null input).
int cv_kws_infer_step(void *featureTensor);

// All four are osKernelGetTickCount()-based milliseconds, each representing the
// duration of the single most recent call to the corresponding step (not an
// internal accumulation -- callers accumulate across calls themselves).
extern uint32_t g_kws_mfcc_ms;       // cv_kws_preprocess_step: time in ShiftAndAppendFrames
extern uint32_t g_kws_copy_ms;       // cv_kws_infer_step: time copying the tensor into the live model input
extern uint32_t g_kws_invoke_ms;     // cv_kws_infer_step: time inside kws_int_ptr->Invoke() (NPU dispatch)
extern uint32_t g_kws_postproc_ms;   // cv_kws_infer_step: GetClassificationResults + reporting

// Converts a difference of osKernelGetTickCount() values to milliseconds.
static inline uint32_t ticksToMs(uint32_t ticks) { return ticks * 1000U / osKernelGetTickFreq(); }

#ifdef __cplusplus
}
#endif

#endif
