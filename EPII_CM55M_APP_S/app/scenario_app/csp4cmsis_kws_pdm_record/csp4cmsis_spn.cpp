#include "csp/csp4cmsis.h"
#include "xprintf.h"
#include <cstring>
#include <cstdint>

#include "cmsis_os2.h"
#include "FreeRTOS.h"  // StaticTask_t: the control block of a statically created thread

#include "WE2_core.h"
#include "csp4cmsis_kws_pdm_record.h"
#include "cvapp_kws.h"
#include "csp4cmsis_spn.h"

using namespace csp;

/*******************************************************************************
 * Four-process CSP network:
 *
 *   AcquisitionProcess --[Channel<AudioChunkMsg>, rendezvous]--> PreprocessingProcess
 *   PreprocessingProcess --[Channel<FeatureTensorMsg>, rendezvous]--> InferenceProcess
 *   All three of the above --[BufferedChannel<KwsReportMsg>, lossy]--> ReporterProcess
 *
 * This supersedes the earlier three-process design (Acquisition | Inference |
 * Reporter), which recomputed the full 98-frame MFCC tensor from scratch
 * inside InferenceProcess on every cycle -- meaning MFCC (~13.6 ms) sat
 * squarely ahead of every NPU dispatch in that process's own critical path,
 * even though the NPU itself is fast enough for genuine 4 Hz throughput.
 * Splitting MFCC into its own process lets PreprocessingProcess prepare the
 * NEXT 25-frame tensor update while InferenceProcess is still blocked inside
 * the CURRENT Invoke() call, at the cost of one extra pipeline stage of
 * latency (~0.25 s), taking total audio-to-classification latency from
 * ~0.25 s to ~0.5 s -- an accepted trade per the design discussion preceding
 * this implementation.
 *
 * AcquisitionProcess is now much simpler than in the previous design: it no
 * longer assembles a 4-quarter-slot window at all. It hands over a POINTER
 * to exactly one freshly-completed 0.25 s ring-buffer slot per cycle; all
 * window assembly (the persistent, incrementally-updated 98-frame tensor)
 * now lives in PreprocessingProcess via cv_kws_preprocess_step().
 *
 * Stack/priority note (API 1.3, see library/csp4cmsis/inc/csp/process.h):
 * every process below derives from CSProcessStatic<N>, not CSProcess
 * directly -- CSProcess itself is abstract, since stackWords()/
 * stackBuffer()/taskBuffer() are pure virtual and CSProcessStatic<N> is
 * what supplies them as statically-allocated members sized by N. Position
 * in InParallel(...) below carries no stack/priority meaning: each process
 * is spawned with exactly the N it declares via its own CSProcessStatic<N>,
 * and its own taskPriority() override if it has one, regardless of where
 * it's listed. InferenceProcess still has by far the deepest call chain
 * (TFLM interpreter -> CMSIS-NN -> Ethos-U driver), hence CSProcessStatic<
 * 4*2048> and an explicit taskPriority() override below; the other three
 * use CSProcessStatic<256>, carried over from the previous hardcoded
 * per-task default. PreprocessingProcess does real DSP work (FFT/DCT via
 * Mfcc.cc/PlatformMath.cc) at that same 256-word figure; this is expected
 * to be shallower than InferenceProcess's chain since it never enters
 * TFLM/CMSIS-NN/the NPU driver, but that has NOT been verified against
 * actual stack usage on hardware. Worth checking before treating this as
 * settled -- CSProcess::stackHighWaterMarkWords() (also new in this API
 * revision) is the direct way to do that per-process, without reaching for
 * uxTaskGetStackHighWaterMark() by hand.
 ******************************************************************************/

// ---- Acquisition -> Preprocessing: one raw 0.25 s ring-buffer slot per cycle ----

struct AudioChunkMsg {
    const int16_t *chunk;   // points directly into audio_buf[slot]; NUM_BUFF=8 gives
                             // ~2 s before DMA could wrap back and overwrite it, far
                             // more than PreprocessingProcess needs to consume it
};

static Channel<AudioChunkMsg> g_audioChan;   // capacity-0 rendezvous

// ---- Preprocessing -> Inference: one completed feature tensor per cycle ----

struct FeatureTensorMsg {
    void *tensor;   // one of cvapp_kws.cpp's two internally-managed handoff buffers
};

static Channel<FeatureTensorMsg> g_featureChan;   // capacity-0 rendezvous

// ---- Reporting: one shared lossy channel, fed by three producer processes ----

struct KwsReportMsg {
    enum class Kind : uint8_t {
        Detection, NoneDetected, MissedInference, Priming, AcqStats, PrepStats, InferStats
    } kind;
    char     label[16];
    int32_t  scorePct;
    uint32_t labelIdx;
    int32_t  prevBuf;
    int32_t  a;
    int32_t  missed;
    int32_t  total;
    uint32_t dmaWaitMs;       // AcqStats
    uint32_t bufAsmMs;        // AcqStats
    uint32_t mfccMs;          // PrepStats
    uint32_t copyMs;          // InferStats
    uint32_t invokeMs;        // InferStats
    uint32_t postprocMs;      // InferStats
    uint32_t chanSendWaitMs;  // AcqStats / PrepStats (meaning depends on kind)
    uint32_t elapsedMs;
    float    realtimeFactor;
};

// 8-slot lossy buffer. Plenty of headroom for a burst of detections; if it
// ever fills, we drop the oldest queued print rather than block any sender.
static BufferedChannel<KwsReportMsg, 8, BufferPolicy::KeepNewest> g_reportChan;

class ReporterProcess : public CSProcessStatic<256> {
    Chanin<KwsReportMsg> in;
public:
    explicit ReporterProcess(Chanin<KwsReportMsg> r) : in(r) {}
    const char* name() const override { return "ReporterProcess"; }

    void run() override {
        KwsReportMsg msg;
        while (true) {
            in >> msg;   // only place in the app that ever waits on UART pace
            switch (msg.kind) {
                case KwsReportMsg::Kind::Detection:
                    xprintf("Label: %s Score: %ld %% Label Index: %lu \n",
                            msg.label, (long)msg.scorePct, (unsigned long)msg.labelIdx);
                    break;
                case KwsReportMsg::Kind::NoneDetected:
                    xprintf("None \n");
                    break;
                case KwsReportMsg::Kind::MissedInference:
                    xprintf("Acquisition fell behind: expected ring slot %ld next, DMA is at %ld\n",
                            (long)msg.prevBuf, (long)msg.a);
                    break;
                case KwsReportMsg::Kind::Priming:
                    xprintf("Preprocessing: priming step %ld/3 (window not yet fully real)\n",
                            (long)msg.total);
                    break;
                case KwsReportMsg::Kind::AcqStats:
                    xprintf("[Acq]  Missed %ld/%ld | ms: dma_wait=%lu buf_asm=%lu chan_send_wait=%lu | "
                            "elapsed=%lu ms | rt=%d.%02dx\n",
                            (long)msg.missed, (long)msg.total,
                            (unsigned long)msg.dmaWaitMs,
                            (unsigned long)msg.bufAsmMs,
                            (unsigned long)msg.chanSendWaitMs,
                            (unsigned long)msg.elapsedMs,
                            (int)msg.realtimeFactor,
                            (int)((msg.realtimeFactor - (int)msg.realtimeFactor) * 100));
                    break;
                case KwsReportMsg::Kind::PrepStats:
                    xprintf("[Prep] Processed %ld | ms: mfcc=%lu chan_send_wait=%lu | "
                            "elapsed=%lu ms | rt=%d.%02dx\n",
                            (long)msg.total,
                            (unsigned long)msg.mfccMs,
                            (unsigned long)msg.chanSendWaitMs,
                            (unsigned long)msg.elapsedMs,
                            (int)msg.realtimeFactor,
                            (int)((msg.realtimeFactor - (int)msg.realtimeFactor) * 100));
                    break;
                case KwsReportMsg::Kind::InferStats:
                    xprintf("[Inf]  Processed %ld | ms: copy=%lu invoke=%lu post=%lu | "
                            "elapsed=%lu ms | rt=%d.%02dx\n",
                            (long)msg.total,
                            (unsigned long)msg.copyMs,
                            (unsigned long)msg.invokeMs,
                            (unsigned long)msg.postprocMs,
                            (unsigned long)msg.elapsedMs,
                            (int)msg.realtimeFactor,
                            (int)((msg.realtimeFactor - (int)msg.realtimeFactor) * 100));
                    break;
            } // end switch
        } // end while
    } // end run()
};

extern "C" void kws_report_detection(const char *label, int score_pct, uint32_t label_idx) {
    KwsReportMsg msg{};
    msg.kind = KwsReportMsg::Kind::Detection;
    std::strncpy(msg.label, label, sizeof(msg.label) - 1);
    msg.scorePct = score_pct;
    msg.labelIdx = label_idx;
    g_reportChan.writer() << msg;   // never blocks (KeepNewest)
}

extern "C" void kws_report_none(void) {
    KwsReportMsg msg{};
    msg.kind = KwsReportMsg::Kind::NoneDetected;
    g_reportChan.writer() << msg;
}

extern "C" void kws_report_missed_inference(int32_t prev_buf, int32_t a) {
    KwsReportMsg msg{};
    msg.kind = KwsReportMsg::Kind::MissedInference;
    msg.prevBuf = prev_buf;
    msg.a = a;
    g_reportChan.writer() << msg;
}

extern "C" void kws_report_priming(int32_t step) {
    KwsReportMsg msg{};
    msg.kind = KwsReportMsg::Kind::Priming;
    msg.total = step;
    g_reportChan.writer() << msg;
}

extern "C" void kws_report_acq_stats(int32_t missed, int32_t total,
                                      uint32_t dma_wait_ms_accum,
                                      uint32_t buf_asm_ms_accum,
                                      uint32_t chan_send_wait_ms_accum,
                                      uint32_t elapsed_ms, float realtime_factor) {
    KwsReportMsg msg{};
    msg.kind = KwsReportMsg::Kind::AcqStats;
    msg.missed = missed;
    msg.total = total;
    msg.dmaWaitMs = dma_wait_ms_accum;
    msg.bufAsmMs = buf_asm_ms_accum;
    msg.chanSendWaitMs = chan_send_wait_ms_accum;
    msg.elapsedMs = elapsed_ms;
    msg.realtimeFactor = realtime_factor;
    g_reportChan.writer() << msg;
}

extern "C" void kws_report_prep_stats(int32_t processed,
                                       uint32_t mfcc_ms_accum,
                                       uint32_t chan_send_wait_ms_accum,
                                       uint32_t elapsed_ms, float realtime_factor) {
    KwsReportMsg msg{};
    msg.kind = KwsReportMsg::Kind::PrepStats;
    msg.total = processed;
    msg.mfccMs = mfcc_ms_accum;
    msg.chanSendWaitMs = chan_send_wait_ms_accum;
    msg.elapsedMs = elapsed_ms;
    msg.realtimeFactor = realtime_factor;
    g_reportChan.writer() << msg;
}

extern "C" void kws_report_infer_stats(int32_t processed,
                                        uint32_t copy_ms_accum,
                                        uint32_t invoke_ms_accum,
                                        uint32_t postproc_ms_accum,
                                        uint32_t elapsed_ms, float realtime_factor) {
    KwsReportMsg msg{};
    msg.kind = KwsReportMsg::Kind::InferStats;
    msg.total = processed;
    msg.copyMs = copy_ms_accum;
    msg.invokeMs = invoke_ms_accum;
    msg.postprocMs = postproc_ms_accum;
    msg.elapsedMs = elapsed_ms;
    msg.realtimeFactor = realtime_factor;
    g_reportChan.writer() << msg;
}

/*******************************************************************************
 * InferenceProcess: receives a completed feature tensor, copies it into the
 * model's live input, runs Invoke(), post-processes. The blocking `in >> msg`
 * receive is the pipeline's pacing point and a genuine FreeRTOS block, so
 * lower-priority processes are never starved by this one.
 ******************************************************************************/
class InferenceProcess : public CSProcessStatic<4 * 2048> {
    Chanin<FeatureTensorMsg> in;
public:
    explicit InferenceProcess(Chanin<FeatureTensorMsg> r) : in(r) {}
    const char* name() const override { return "InferenceProcess"; }

    // API 1.3: stackWords() is now fixed by the CSProcessStatic<4*2048>
    // base above (it's `final` there) rather than overridden here --
    // this reproduces the same 4*2048-word figure this process declared
    // explicitly under API 1.2. taskPriority() remains a normal virtual
    // override, unaffected by that change.
    // osPriorityLow3 was tskIDLE_PRIORITY + 3 (D5 mapping +0..+4 -> Low..Low4):
    // above the other three processes (the network default, was +2).
    osPriority_t taskPriority() const override { return osPriorityLow3; }

    void run() override {
        int32_t processed = 0;
        uint32_t copy_ms_accum = 0;
        uint32_t invoke_ms_accum = 0;
        uint32_t postproc_ms_accum = 0;
        uint32_t windowStartTick = osKernelGetTickCount();

        while (true) {
            FeatureTensorMsg msg;
            in >> msg;   // blocks until PreprocessingProcess hands over a tensor

            cv_kws_infer_step(msg.tensor);   // sets g_kws_copy_ms/invoke_ms/postproc_ms

            copy_ms_accum     += g_kws_copy_ms;
            invoke_ms_accum   += g_kws_invoke_ms;
            postproc_ms_accum += g_kws_postproc_ms;
            processed++;

            if (processed % 20 == 0) {
                uint32_t now = osKernelGetTickCount();
                uint32_t elapsedMs = ticksToMs(now - windowStartTick);
                // 20 windows x 0.25 s hop = 5 s of new audio per batch.
                float realtimeFactor = elapsedMs > 0 ? (5000.0f / (float)elapsedMs) : 0.0f;

                kws_report_infer_stats(processed, copy_ms_accum, invoke_ms_accum,
                                        postproc_ms_accum, elapsedMs, realtimeFactor);

                copy_ms_accum = 0;
                invoke_ms_accum = 0;
                postproc_ms_accum = 0;
                windowStartTick = now;
            }
        }
    }
};

/*******************************************************************************
 * PreprocessingProcess: receives one raw 0.25 s quarter-buffer, feeds it into
 * the persistent incremental-MFCC state machine (cv_kws_preprocess_step()),
 * and -- once the window is fully populated with real audio -- hands the
 * completed tensor to InferenceProcess. During the 3 priming steps after
 * startup, cv_kws_preprocess_step() returns nullptr and nothing is sent.
 ******************************************************************************/
class PreprocessingProcess : public CSProcessStatic<256> {
    Chanin<AudioChunkMsg> in;
    Chanout<FeatureTensorMsg> out;
public:
    PreprocessingProcess(Chanin<AudioChunkMsg> r, Chanout<FeatureTensorMsg> w) : in(r), out(w) {}
    const char* name() const override { return "PreprocessingProcess"; }

    void run() override {
        int32_t processed = 0;
        int32_t priming_step = 0;
        uint32_t mfcc_ms_accum = 0;
        uint32_t chan_send_wait_ms_accum = 0;
        uint32_t windowStartTick = osKernelGetTickCount();

        while (true) {
            AudioChunkMsg msg;
            in >> msg;   // blocks until AcquisitionProcess hands over a chunk

            void *tensor = cv_kws_preprocess_step(msg.chunk);   // sets g_kws_mfcc_ms
            mfcc_ms_accum += g_kws_mfcc_ms;

            if (tensor != nullptr) {
                FeatureTensorMsg out_msg{ tensor };
                uint32_t sendStart = osKernelGetTickCount();
                out << out_msg;   // blocks iff InferenceProcess is still mid-Invoke
                uint32_t sendEnd = osKernelGetTickCount();
                chan_send_wait_ms_accum += ticksToMs(sendEnd - sendStart);
            } else {
                priming_step++;
                kws_report_priming(priming_step);
            }

            processed++;
            if (processed % 20 == 0) {
                uint32_t now = osKernelGetTickCount();
                uint32_t elapsedMs = ticksToMs(now - windowStartTick);
                float realtimeFactor = elapsedMs > 0 ? (5000.0f / (float)elapsedMs) : 0.0f;

                kws_report_prep_stats(processed, mfcc_ms_accum, chan_send_wait_ms_accum,
                                       elapsedMs, realtimeFactor);

                mfcc_ms_accum = 0;
                chan_send_wait_ms_accum = 0;
                windowStartTick = now;
            }
        }
    }
};

/*******************************************************************************
 * AcquisitionProcess: owns the DMA ring-buffer bookkeeping. No longer
 * assembles a multi-slot window -- hands over a pointer to exactly one
 * freshly-completed 0.25 s ring slot per cycle.
 ******************************************************************************/
class AcquisitionProcess : public CSProcessStatic<256> {
    Chanout<AudioChunkMsg> out;
public:
    explicit AcquisitionProcess(Chanout<AudioChunkMsg> w) : out(w) {}
    const char* name() const override { return "AcquisitionProcess"; }

    void run() override {
        int32_t last_current_buf = -1;   // -1 == "no completed iteration yet"
        int32_t miss_inf = 0;

        uint32_t dma_wait_ms_accum = 0;
        uint32_t buf_asm_ms_accum = 0;
        uint32_t chan_send_wait_ms_accum = 0;
        uint32_t windowStartTick = osKernelGetTickCount();

        // One hop = one quarter-slot's real duration: 250 ms for BLK_NUM=1.
        const uint32_t kHopBudgetMs =
            (BLK_NUM * QUARTER_SECOND_MONO_BYTES / 2) * 1000UL / 16000UL;

        while (true) {
            uint32_t iterStart = osKernelGetTickCount();

            uint32_t dmaWaitStart = osKernelGetTickCount();
            while (!kws_processing_complete) {
                SleepFor(Ticks(1));
            }
            while (w_buf_idx == last_current_buf) {
                SleepFor(Ticks(1));
            }
            uint32_t dmaWaitEnd = osKernelGetTickCount();
            dma_wait_ms_accum += ticksToMs(dmaWaitEnd - dmaWaitStart);

            int32_t current_buf = w_buf_idx;   // the slot that just completed

            // Diagnostic only -- does NOT gate what gets sent below.
            if (last_current_buf >= 0) {
                int32_t expected = (last_current_buf + 1) % NUM_BUFF;
                if (current_buf != expected) {
                    miss_inf++;
                    kws_report_missed_inference(expected, current_buf);
                }
            }

            uint32_t bufAsmStart = osKernelGetTickCount();
            SCB_InvalidateDCache_by_Addr((uint32_t*)audio_buf[current_buf], QUARTER_SECOND_MONO_BYTES);
            uint32_t bufAsmEnd = osKernelGetTickCount();
            buf_asm_ms_accum += ticksToMs(bufAsmEnd - bufAsmStart);

            AudioChunkMsg msg{ audio_buf[current_buf] };
            uint32_t sendStart = osKernelGetTickCount();
            out << msg;   // blocks here iff PreprocessingProcess is still busy with the previous chunk
            uint32_t sendEnd = osKernelGetTickCount();
            chan_send_wait_ms_accum += ticksToMs(sendEnd - sendStart);

            last_current_buf = current_buf;
            r_buf_idx++;

            if (r_buf_idx % 20 == 0) {
                uint32_t now = osKernelGetTickCount();
                uint32_t elapsedMs = ticksToMs(now - windowStartTick);
                float realtimeFactor = elapsedMs > 0 ? (5000.0f / (float)elapsedMs) : 0.0f;

                kws_report_acq_stats(miss_inf, r_buf_idx,
                                      dma_wait_ms_accum, buf_asm_ms_accum, chan_send_wait_ms_accum,
                                      elapsedMs, realtimeFactor);

                dma_wait_ms_accum = 0;
                buf_asm_ms_accum = 0;
                chan_send_wait_ms_accum = 0;
                windowStartTick = now;
            }

            // Only spend slack we actually have. If this iteration already
            // ate most/all of the 250 ms hop budget, skip the yield rather
            // than risk pushing this iteration past the next DMA buffer.
            uint32_t elapsedThisIterMs = ticksToMs(osKernelGetTickCount() - iterStart);
            if (elapsedThisIterMs + 1 < kHopBudgetMs) {
                SleepFor(Milliseconds(1));
            }
        }
    }
};

// Priorities keep the pre-2.0 order: MainApp (was tskIDLE_PRIORITY + 3) above the
// network default (was + 2), so Run(..., StaticNetwork) creates all processes before any runs.
static constexpr osPriority_t MAIN_APP_PRIORITY = osPriorityLow3;
static constexpr osPriority_t NETWORK_PRIORITY  = osPriorityLow2;

// MainApp's stack and control block are static: creating the thread takes no heap.
// CMSIS-RTOS2 counts the stack in bytes. Provisional (was 4*2048 words); to be
// right-sized from measurements.
alignas(8) static uint8_t mainAppStack[4096];
static StaticTask_t mainAppControlBlock;

void MainApp_Task(void* params) {
    (void)params;
    SleepFor(Milliseconds(10));
    xprintf("\r\n--- KWS Processing (4-process pipeline: Acquisition | Preprocessing | Inference | Reporter) ---\r\n");

    if (cv_kws_preprocess_init() != 0) {
        xprintf("ERROR: cv_kws_preprocess_init failed!\r\n");
        osThreadExit();  // a thread must not return from its function
    }

    // API 1.2/1.3: argument order is not priority/stack-significant --
    // each process declares its own requirements via its CSProcessStatic<N>
    // base and (optionally) taskPriority(). Listed here in physical
    // pipeline order for readability.
    static AcquisitionProcess acquisition(g_audioChan.writer());
    static PreprocessingProcess preprocessing(g_audioChan.reader(), g_featureChan.writer());
    static InferenceProcess inference(g_featureChan.reader());
    static ReporterProcess reporter(g_reportChan.reader());

    Run(
        InParallel(acquisition, preprocessing, inference, reporter),
        ExecutionMode::StaticNetwork,
        NETWORK_PRIORITY
    );

    // API 1.2: MainApp_Task no longer executes any CSP process inline --
    // Run() above spawns all four as their own tasks and returns
    // immediately (StaticNetwork mode). There is nothing further for this
    // thread to do, so it ends itself (its stack is static, see above).
    osThreadExit();
}

extern "C" void RunProcessingChainTest(void)
{
    // This thread's stack only has to hold MainApp_Task itself (spawn calls,
    // cv_kws_preprocess_init(), a couple of xprintf calls); every CSP process
    // brings its own (see InferenceProcess's CSProcessStatic<4*2048> base).
    osThreadAttr_t attr = {};
    attr.name       = "MainApp";
    attr.stack_mem  = mainAppStack;
    attr.stack_size = sizeof(mainAppStack);
    attr.cb_mem     = &mainAppControlBlock;
    attr.cb_size    = sizeof(mainAppControlBlock);
    attr.priority   = MAIN_APP_PRIORITY;
    if (osThreadNew(MainApp_Task, NULL, &attr) == NULL) {
        xprintf("ERROR: MainApp_Task creation failed!\r\n");
    }
}
