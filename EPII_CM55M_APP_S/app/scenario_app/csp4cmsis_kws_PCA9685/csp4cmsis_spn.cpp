#include "csp/csp4cmsis.h"
#include "xprintf.h"
#include <cstring>
#include <cstdint>

#include "cmsis_os2.h"
#include "FreeRTOS.h"  // StaticTask_t: the control block of a statically created thread

#include "WE2_core.h"
#include "csp4cmsis_kws_PCA9685.h"
#include "cvapp_kws.h"
#include "csp4cmsis_spn.h"

// Bring in the Himax C drivers
extern "C" {
#include "hx_drv_scu.h"
#include "hx_drv_iic.h"
}

using namespace csp;

/*******************************************************************************
 * Five-process CSP network:
 *
 *   AcquisitionProcess --[Channel<AudioChunkMsg>]---> PreprocessingProcess
 *   PreprocessingProcess --[Channel<FeatureTensorMsg>]---> InferenceProcess
 *   InferenceProcess (hooks) --[Channel<KwsTokenMsg>]---> FilterProcess (New!)
 *   FilterProcess --[Channel<KwsTokenMsg>]---> FsmProcess
 *   All Producers --[SamplingBufferedChannel<KwsReportMsg>]---> ReporterProcess
 ******************************************************************************/

struct AudioChunkMsg {
    const int16_t *chunk;
};
static BufferedChannel<AudioChunkMsg, 2> g_audioChan;

struct FeatureTensorMsg {
    void *tensor;
};
static BufferedChannel<FeatureTensorMsg, 2> g_featureChan;

// ---- Communication tokens for Filtering and FSM Stages ----
struct KwsTokenMsg {
    char label[16];
};
static Channel<KwsTokenMsg> g_rawKwsChan;       // Inference Hooks -> FilterProcess
static Channel<KwsTokenMsg> g_filteredKwsChan;  // FilterProcess -> FsmProcess

// ---- Reporting Types ----
struct KwsReportMsg {
    enum class Kind : uint8_t {
        Detection, NoneDetected, MissedInference, Priming, AcqStats, PrepStats, InferStats,
        FsmAbort, FsmCommand, SemStats, DmaCbStats, MemStats   // NEW
    } kind;
    char    label[16];
    int32_t  scorePct;
    uint32_t labelIdx;
    int32_t  prevBuf;
    int32_t  a;
    int32_t  missed;
    int32_t  total;
    uint32_t dmaWaitMs;
    uint32_t bufAsmMs;
    uint32_t mfccMs;
    uint32_t copyMs;
    uint32_t invokeMs;
    uint32_t postprocMs;
    uint32_t chanSendWaitMs;
    uint32_t elapsedMs;
    float    realtimeFactor;
    uint32_t semTakeCount;   // NEW
    uint32_t semGiveCount;   // NEW
    uint32_t dmaCbCount;         // NEW: real ISR-measured DMA callback count
    uint32_t dmaCbAvgIntervalMs; // NEW: real ISR-measured avg interval between callbacks
};

static SamplingBufferedChannel<KwsReportMsg, 8, BufferPolicy::KeepNewest> g_reportChan;

// --- I2C hardware synchronization for PCA9685 ---
// The I2C completion interrupt signals the actuator process through a one-slot
// buffered channel: an interrupt cannot wait for a partner, so it writes via
// isrWriter(), and the slot keeps a completion that arrives before the process
// waits for it (a rendezvous would lose it). The process starts one transfer
// at a time, so at most one completion can be pending; a second one means a
// driver bug. Runs in the I2C interrupt (priority set in the app's .c file).
static BufferedChannel<bool, 1> g_pca9685_i2c_isr_chan;

extern "C" void pca9685_i2c_callback(void) {
    if (!g_pca9685_i2c_isr_chan.isrWriter().putFromISR(true)) {
        // A second completion before the first was read: stop here instead of
        // losing it. Polled UART output works with interrupts disabled.
        __disable_irq();
        xprintf("\r\nFATAL: I2C completion lost (the previous one was not read yet)\r\n");
        for (;;) { }
    }
}

// Channel to pass executed commands from the FSM to the hardware controller
static Channel<KwsTokenMsg> g_hwCmdChan;

namespace {
    // 20 iterations x one native DMA hop (now 0.5 s per slot, BLK_NUM=2) is
    // the nominal real-time duration of every %20 report window below --
    // replaces a hardcoded "5000.0f" left over from when native hops were
    // 0.25 s (BLK_NUM=1), which was silently inflating every realtimeFactor
    // reading ~2x once BLK_NUM changed. Shared by Acquisition/Preprocessing/
    // Inference since all three window on 20 iterations of their respective
    // (now equally 0.5 s-cadenced) inputs.
    constexpr uint32_t kNativeHopMs    = (BLK_NUM * QUARTER_SECOND_MONO_BYTES / 2) * 1000UL / 16000UL; // 500
    constexpr float     kReportWindowMs = 20.0f * (float)kNativeHopMs; // 10000.0f
}

// CSProcess itself is abstract: stackWords()/stackBuffer()/taskBuffer() are
// pure virtual so each task supplies its own static stack + StaticTask_t
// storage (no more implicit fallback, per the v1.3 API notes above
// InferenceProcess/PreprocessingProcess). CSProcessStatic<N> is the library
// helper that supplies that storage for you -- inherit from it instead of
// CSProcess directly and give it the stack size in words. Sizes below are
// provisional (same "measure the HWM report line, then right-size" caveat
// as MAIN_APP_STACK_WORDS); ReporterProcess just does xprintf formatting so
// 1024 words is a generous starting point.
class ReporterProcess : public CSProcessStatic<1024> {
    Chanin<KwsReportMsg> in;
public:
    explicit ReporterProcess(Chanin<KwsReportMsg> r) : in(r) {}
    osPriority_t taskPriority() const override { return osPriorityLow; }  // was tskIDLE_PRIORITY + 0
    void run() override {
        KwsReportMsg msg;
        while (true) {
            in >> msg;
            switch (msg.kind) {
                case KwsReportMsg::Kind::Detection:
                    xprintf("Label: %s Score: %ld %% Label Index: %lu \n",
                            msg.label, (long)msg.scorePct, (unsigned long)msg.labelIdx);
                    break;
                case KwsReportMsg::Kind::NoneDetected:
                    //xprintf("None \n");
                    break;
                case KwsReportMsg::Kind::MissedInference:
                    xprintf("Acquisition fell behind: expected ring slot %ld next, DMA is at %ld\n",
                            (long)msg.prevBuf, (long)msg.a);
                    break;
                case KwsReportMsg::Kind::Priming:
                    xprintf("Preprocessing: priming step %ld/1 (window not yet fully real)\n",
                            (long)msg.total);
                    break;
                case KwsReportMsg::Kind::AcqStats:
                    xprintf("[Acq]  Missed %ld/%ld | ms: dma_wait=%lu buf_asm=%lu chan_send_wait=%lu | elapsed=%lums rtf=%d.%02d\n",
                            (long)msg.missed, (long)msg.total, (unsigned long)msg.dmaWaitMs, 
                            (unsigned long)msg.bufAsmMs, (unsigned long)msg.chanSendWaitMs,
                            (unsigned long)msg.elapsedMs, (int)msg.realtimeFactor, (int)((msg.realtimeFactor - (int)msg.realtimeFactor) * 100));
                    break;
                case KwsReportMsg::Kind::PrepStats:
                    xprintf("[Prep] Processed %ld | ms: mfcc=%lu chan_send_wait=%lu | elapsed=%lums rtf=%d.%02d\n",
                            (long)msg.total, (unsigned long)msg.mfccMs, (unsigned long)msg.chanSendWaitMs,
                            (unsigned long)msg.elapsedMs, (int)msg.realtimeFactor, (int)((msg.realtimeFactor - (int)msg.realtimeFactor) * 100));
                    break;
                case KwsReportMsg::Kind::InferStats:
                    xprintf("[Inf]  Processed %ld | ms: copy=%lu invoke=%lu post=%lu | elapsed=%lums rtf=%d.%02d\n",
                            (long)msg.total, (unsigned long)msg.copyMs, (unsigned long)msg.invokeMs, (unsigned long)msg.postprocMs,
                            (unsigned long)msg.elapsedMs, (int)msg.realtimeFactor, (int)((msg.realtimeFactor - (int)msg.realtimeFactor) * 100));
                    break;
                case KwsReportMsg::Kind::FsmAbort:
                    xprintf("[FSM] Sequence aborted! Returning to Idle.\n");
                    break;
                case KwsReportMsg::Kind::FsmCommand:
                    xprintf("[FSM] Executing Command Console Output: %s\n", msg.label);
                    break;
                case KwsReportMsg::Kind::SemStats:
		    xprintf("[Sem]  take=%lu give=%lu\n",
			    (unsigned long)msg.semTakeCount, (unsigned long)msg.semGiveCount);
		    break;
                case KwsReportMsg::Kind::DmaCbStats:
                    xprintf("[DMA]  cb_count=%lu avg_interval=%lums (ground truth, ISR-measured)\n",
                            (unsigned long)msg.dmaCbCount, (unsigned long)msg.dmaCbAvgIntervalMs);
                    break;
                case KwsReportMsg::Kind::MemStats:
                    xprintf("[Mem]  free_heap=%lu min_ever_free=%lu | stack_hwm(words): prep=%lu infer=%lu\n",
                            (unsigned long)msg.dmaWaitMs, (unsigned long)msg.bufAsmMs,
                            (unsigned long)msg.mfccMs, (unsigned long)msg.copyMs);
                    break;
            }
        }
    }
};

extern "C" void kws_report_detection(const char *label, int score_pct, uint32_t label_idx) {
    KwsReportMsg msg{};
    msg.kind = KwsReportMsg::Kind::Detection;
    std::strncpy(msg.label, label, sizeof(msg.label) - 1);
    msg.scorePct = score_pct;
    msg.labelIdx = label_idx;
    g_reportChan.writer() << msg;

    // Send only actual detections to the filter stage
    KwsTokenMsg token{};
    std::strncpy(token.label, label, sizeof(token.label) - 1);
    g_rawKwsChan.writer() << token;
}

extern "C" void kws_report_none(void) {
    KwsReportMsg msg{};
    msg.kind = KwsReportMsg::Kind::NoneDetected;
    g_reportChan.writer() << msg; // No longer sends anything to g_rawKwsChan
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

extern "C" void kws_report_acq_stats(int32_t missed, int32_t total, uint32_t dma_wait_ms_accum,
                                      uint32_t buf_asm_ms_accum, uint32_t chan_send_wait_ms_accum,
                                      uint32_t elapsed_ms, float realtime_factor) {
    KwsReportMsg msg{};
    msg.kind = KwsReportMsg::Kind::AcqStats;
    msg.missed = missed; msg.total = total; msg.dmaWaitMs = dma_wait_ms_accum;
    msg.bufAsmMs = buf_asm_ms_accum; msg.chanSendWaitMs = chan_send_wait_ms_accum;
    msg.elapsedMs = elapsed_ms; msg.realtimeFactor = realtime_factor;
    g_reportChan.writer() << msg;
}

extern "C" void kws_report_prep_stats(int32_t processed, uint32_t mfcc_ms_accum,
                                       uint32_t chan_send_wait_ms_accum, uint32_t elapsed_ms, float realtime_factor) {
    KwsReportMsg msg{};
    msg.kind = KwsReportMsg::Kind::PrepStats;
    msg.total = processed; msg.mfccMs = mfcc_ms_accum; msg.chanSendWaitMs = chan_send_wait_ms_accum;
    msg.elapsedMs = elapsed_ms; msg.realtimeFactor = realtime_factor;
    g_reportChan.writer() << msg;
}

extern "C" void kws_report_infer_stats(int32_t processed, uint32_t copy_ms_accum, uint32_t invoke_ms_accum,
                                        uint32_t postproc_ms_accum, uint32_t elapsed_ms, float realtime_factor) {
    KwsReportMsg msg{};
    msg.kind = KwsReportMsg::Kind::InferStats;
    msg.total = processed; msg.copyMs = copy_ms_accum; msg.invokeMs = invoke_ms_accum; msg.postprocMs = postproc_ms_accum;
    msg.elapsedMs = elapsed_ms; msg.realtimeFactor = realtime_factor;
    g_reportChan.writer() << msg;
}

extern "C" {
    extern volatile uint32_t g_ethosu_sem_take_count;
    extern volatile uint32_t g_ethosu_sem_give_count;
}

extern "C" void kws_report_sem_stats(uint32_t take_count, uint32_t give_count) {
    KwsReportMsg msg{};
    msg.kind = KwsReportMsg::Kind::SemStats;
    msg.semTakeCount = take_count;
    msg.semGiveCount = give_count;
    g_reportChan.writer() << msg;
}

extern "C" void kws_report_dma_cb_stats(uint32_t count, uint32_t avg_interval_ms) {
    KwsReportMsg msg{};
    msg.kind = KwsReportMsg::Kind::DmaCbStats;
    msg.dmaCbCount = count;
    msg.dmaCbAvgIntervalMs = avg_interval_ms;
    g_reportChan.writer() << msg;
}

extern "C" void kws_report_mem_stats(uint32_t free_heap_bytes, uint32_t min_ever_free_heap_bytes,
                                      uint32_t prep_stack_hwm_words, uint32_t infer_stack_hwm_words) {
    KwsReportMsg msg{};
    msg.kind = KwsReportMsg::Kind::MemStats;
    // Reusing existing generic uint32 fields rather than adding four more
    // dedicated ones -- this report kind is diagnostic-only and short-lived.
    msg.dmaWaitMs = free_heap_bytes;
    msg.bufAsmMs = min_ever_free_heap_bytes;
    msg.mfccMs = prep_stack_hwm_words;
    msg.copyMs = infer_stack_hwm_words;
    g_reportChan.writer() << msg;
}

// --- Memory diagnostics: each task reports its own high-water mark into
// these; AcquisitionProcess's periodic report reads them alongside heap
// stats. Best-effort, no synchronization -- diagnostic only. ---
volatile uint32_t g_prep_stack_hwm_words = 0;
volatile uint32_t g_infer_stack_hwm_words = 0;

namespace {
    // ---- PCA9685 register map (standard 16-ch 12-bit I2C PWM driver) ----
    constexpr uint8_t PCA9685_MODE1     = 0x00;
    constexpr uint8_t PCA9685_MODE2     = 0x01;
    constexpr uint8_t PCA9685_PRESCALE  = 0xFE;
    constexpr uint8_t PCA9685_LED0_ON_L = 0x06; // LEDn regs = LED0_ON_L + 4*n

    constexpr uint8_t MODE1_AI      = 0x20; // register auto-increment enable
    constexpr uint8_t MODE2_OUTDRV  = 0x04; // totem-pole (push-pull) outputs

    // Prescale for a 50 Hz update rate (standard analog-servo PWM rate),
    // from the datasheet formula: round(25MHz / (4096 * 50Hz)) - 1 = 121.
    // Only writable while MODE1.SLEEP=1 -- true by default at power-on
    // (POR value of MODE1 is 0x11), so no separate sleep step is needed
    // the first time this runs.
    constexpr uint8_t PCA9685_PRESCALE_50HZ = 121;

    constexpr int kNumPositions   = 5;
    constexpr int kMiddlePosition = 2;
    const char *const kPositionNames[kNumPositions] = {
        "Max Left", "Half Left", "Middle", "Half Right", "Full Right"
    };

    // Converts a pulse width in microseconds to a 12-bit (0-4095) tick count
    // for a 20ms (50Hz) period: ticks = us * 4096 / 20000.
    constexpr uint16_t usToTicks(uint32_t pulse_us) {
        return (uint16_t)((pulse_us * 4096UL + 10000UL) / 20000UL);
    }

    // Pulse widths for the 5 discrete positions. 1000-2000us is the
    // conservative "safe" sweep that most analog hobby servos accept
    // without hitting a mechanical end-stop; widen towards 500/2500us
    // for full-travel servos once you've confirmed yours tolerates it.
    constexpr uint16_t kServoTicks[kNumPositions] = {
        usToTicks(1000), // Max Left
        usToTicks(1250), // Half Left
        usToTicks(1500), // Middle
        usToTicks(1750), // Half Right
        usToTicks(2000), // Full Right
    };
}

// I2C register writes only, no deep call stack -- 1024 words is generous.
class Pca9685Process : public CSProcessStatic<1024> {
    Chanin<bool> i2c_sync;
    Chanin<KwsTokenMsg> in_cmd;

    // Default 7-bit address for a PCA9685 module with all A0-A5 address
    // pads left unbridged (tied low).
    const uint8_t slave_addr = 0x40;

    // Channel 0 drives the up/down servo, channel 1 the left/right servo.
    // Both start at index 2 ("Middle") and are clamped to [0, kNumPositions-1].
    int position[2] = { kMiddlePosition, kMiddlePosition };

    void wait_for_i2c_isr() {
        bool dummy;
        i2c_sync >> dummy; // Blocks task until ISR fires
    }

    void write_reg(uint8_t reg, uint8_t val) {
        uint8_t buf[2] = { reg, val };
        hx_drv_i2cm_interrupt_write(USE_DW_IIC_0, slave_addr, buf, sizeof(buf), (void *)pca9685_i2c_callback);
        wait_for_i2c_isr();
    }

    // Writes LEDn_ON_L/H and LEDn_OFF_L/H in one auto-incrementing transaction.
    void set_pwm(uint8_t channel, uint16_t on, uint16_t off) {
        uint8_t buf[5];
        buf[0] = (uint8_t)(PCA9685_LED0_ON_L + 4 * channel);
        buf[1] = (uint8_t)(on & 0xFF);
        buf[2] = (uint8_t)(on >> 8);
        buf[3] = (uint8_t)(off & 0xFF);
        buf[4] = (uint8_t)(off >> 8);
        hx_drv_i2cm_interrupt_write(USE_DW_IIC_0, slave_addr, buf, sizeof(buf), (void *)pca9685_i2c_callback);
        wait_for_i2c_isr();
    }

    void set_position(uint8_t channel, int pos) {
        set_pwm(channel, 0, kServoTicks[pos]);
    }

    void init() {
        write_reg(PCA9685_MODE2, MODE2_OUTDRV);            // push-pull outputs
        write_reg(PCA9685_PRESCALE, PCA9685_PRESCALE_50HZ); // OK: chip is asleep at POR
        write_reg(PCA9685_MODE1, MODE1_AI);                 // auto-increment on, wakes oscillator (SLEEP=0)
        SleepFor(1);                        // datasheet: wait >=500us after waking osc.

        // Initialise both servos to the middle position.
        set_position(0, position[0]);
        set_position(1, position[1]);
    }

public:
    Pca9685Process(Chanin<bool> sync_in, Chanin<KwsTokenMsg> cmd_in)
        : i2c_sync(sync_in), in_cmd(cmd_in) {}
    osPriority_t taskPriority() const override { return osPriorityLow; }  // was tskIDLE_PRIORITY + 0

    void run() override {
        xprintf("[PCA9685] Initializing PWM driver, centering both servos...\r\n");
        init();
        xprintf("[PCA9685] Ch0 (up/down) -> %s | Ch1 (left/right) -> %s\r\n",
                kPositionNames[position[0]], kPositionNames[position[1]]);

        while (true) {
            KwsTokenMsg cmd;
            in_cmd >> cmd; // Wait for a confirmed FSM command

            // up/down step channel 0, left/right step channel 1. "up" and
            // "left" both step towards Max Left (-1); "down" and "right"
            // both step towards Full Right (+1).
            int channel = -1, delta = 0;
            if (std::strcmp(cmd.label, "up") == 0)         { channel = 0; delta = -1; }
            else if (std::strcmp(cmd.label, "down") == 0)  { channel = 0; delta = +1; }
            else if (std::strcmp(cmd.label, "left") == 0)  { channel = 1; delta = -1; }
            else if (std::strcmp(cmd.label, "right") == 0) { channel = 1; delta = +1; }

            if (channel < 0) {
                continue; // FSM only ever forwards up/down/left/right here
            }

            int newPos = position[channel] + delta;
            bool atLimit = (newPos < 0) || (newPos > kNumPositions - 1);
            if (newPos < 0) newPos = 0;
            if (newPos > kNumPositions - 1) newPos = kNumPositions - 1;

            if (newPos != position[channel]) {
                position[channel] = newPos;
                set_position((uint8_t)channel, newPos);
            }

            xprintf("[PCA9685] Ch%d <- '%s' -> position %d/%d (%s)%s\r\n",
                    channel, cmd.label, newPos, kNumPositions - 1,
                    kPositionNames[newPos], atLimit ? " [at limit]" : "");
        }
    }
};

/*******************************************************************************
 * FilterProcess: Pre-processing continuous duplicate filter.
 * Only lets through the command vocabulary (up/down/left/right/go);
 * everything else (_silence_, _unknown_, yes, no, on, off, stop, ...)
 * is silently dropped before it ever reaches the FSM.
 ******************************************************************************/
// Trivial string-compare filter, minimal stack needed.
class FilterProcess : public CSProcessStatic<512> {
    Chanin<KwsTokenMsg> in;
    Chanout<KwsTokenMsg> out;

    static bool isAllowed(const char *label) {
        static const char *const kAllowed[] = { "up", "down", "left", "right", "go" };
        for (const char *allowed : kAllowed) {
            if (std::strcmp(label, allowed) == 0) {
                return true;
            }
        }
        return false;
    }

public:
    FilterProcess(Chanin<KwsTokenMsg> r, Chanout<KwsTokenMsg> w) : in(r), out(w) {}
    osPriority_t taskPriority() const override { return osPriorityLow1; }  // was tskIDLE_PRIORITY + 1

    void run() override {
        char lastLabel[16] = {0};

        while (true) {
            KwsTokenMsg msg;
            in >> msg; // Synchronous block waiting for a real keyword

            // 1. Drop everything outside the command vocabulary
            if (!isAllowed(msg.label)) {
                continue; // Skips to the next iteration without updating lastLabel
            }

            // 2. Drop duplicates (if incoming is different from the last one sent)
            if (std::strcmp(msg.label, lastLabel) != 0) {
                // Update our memory to this new keyword
                std::strncpy(lastLabel, msg.label, sizeof(lastLabel) - 1);
                
                // Push it forward to the command FSM
                out << msg;
            }
        }
    }
};

// Simple state machine, minimal stack needed.
class FsmProcess : public CSProcessStatic<512> {
    Chanin<KwsTokenMsg> in;
    Chanout<KwsReportMsg> out_report;
    Chanout<KwsTokenMsg> out_hw; // New: sends execution to hardware
public:
    FsmProcess(Chanin<KwsTokenMsg> r, Chanout<KwsReportMsg> w_rep, Chanout<KwsTokenMsg> w_hw) 
        : in(r), out_report(w_rep), out_hw(w_hw) {}
        
    osPriority_t taskPriority() const override { return osPriorityLow1; }  // was tskIDLE_PRIORITY + 1

    void run() override {
        enum class State { Idle, Go };
        State state = State::Idle;
        char savedCommand[16] = {0};

        while (true) {
            KwsTokenMsg msg;
            in >> msg;

            if (state == State::Idle) {
                if (std::strcmp(msg.label, "up") == 0 ||
                    std::strcmp(msg.label, "down") == 0 ||
                    std::strcmp(msg.label, "left") == 0 ||
                    std::strcmp(msg.label, "right") == 0) {
                    
                    std::strncpy(savedCommand, msg.label, sizeof(savedCommand) - 1);
                    state = State::Go;
                }
            } 
            else if (state == State::Go) {
                if (std::strcmp(msg.label, "go") == 0) {
                    // 1. Send report to console
                    KwsReportMsg cmdReport{};
                    cmdReport.kind = KwsReportMsg::Kind::FsmCommand;
                    std::strncpy(cmdReport.label, savedCommand, sizeof(cmdReport.label) - 1);
                    out_report << cmdReport;

                    // 2. Send command to hardware controller (NEW)
                    KwsTokenMsg hwCmd{};
                    std::strncpy(hwCmd.label, savedCommand, sizeof(hwCmd.label) - 1);
                    out_hw << hwCmd;
			state = State::Idle;
			std::memset(savedCommand, 0, sizeof(savedCommand));
		    } 
		    else if (std::strcmp(msg.label, "up") == 0 ||
			     std::strcmp(msg.label, "down") == 0 ||
			     std::strcmp(msg.label, "left") == 0 ||
			     std::strcmp(msg.label, "right") == 0) {
			// Implicitly abort the old sequence and start a new one
			std::strncpy(savedCommand, msg.label, sizeof(savedCommand) - 1);
			// State remains State::Go
		    } 
		    else {
			// Abort on actual garbage or unrecognized tokens
			KwsReportMsg abortReport{};
			abortReport.kind = KwsReportMsg::Kind::FsmAbort;
			out_report << abortReport;
			
			state = State::Idle;
			std::memset(savedCommand, 0, sizeof(savedCommand));
		    }
		}
	}
    }
};

/*******************************************************************************
 * InferenceProcess, PreprocessingProcess, AcquisitionProcess remains identical
 ******************************************************************************/
class InferenceProcess : public CSProcessStatic<4 * 2048> {
    Chanin<FeatureTensorMsg> in;
public:
    explicit InferenceProcess(Chanin<FeatureTensorMsg> r) : in(r) {}
    osPriority_t taskPriority() const override { return osPriorityLow2; }  // was tskIDLE_PRIORITY + 2

    void run() override {
        int32_t processed = 0;
        uint32_t copy_ms_accum = 0; uint32_t invoke_ms_accum = 0; uint32_t postproc_ms_accum = 0;
        uint32_t windowStartTick = osKernelGetTickCount();

        while (true) {
            FeatureTensorMsg msg;
            in >> msg;
            cv_kws_infer_step(msg.tensor);

            copy_ms_accum     += g_kws_copy_ms;
            invoke_ms_accum   += g_kws_invoke_ms;
            postproc_ms_accum += g_kws_postproc_ms;
            processed++;

		if (processed % 20 == 0) {
		    uint32_t now = osKernelGetTickCount();
		    uint32_t elapsedMs = ticksToMs(now - windowStartTick);
		    float realtimeFactor = elapsedMs > 0 ? (kReportWindowMs / (float)elapsedMs) : 0.0f;
		    kws_report_infer_stats(processed, copy_ms_accum, invoke_ms_accum, postproc_ms_accum, elapsedMs, realtimeFactor);
		    kws_report_sem_stats(g_ethosu_sem_take_count, g_ethosu_sem_give_count);  // NEW
		    g_infer_stack_hwm_words = (osThreadGetStackSpace(osThreadGetId()) / sizeof(uint32_t));
		    copy_ms_accum = 0; invoke_ms_accum = 0; postproc_ms_accum = 0;
		    windowStartTick = now;
		}
        }
    }
};

class PreprocessingProcess : public CSProcessStatic<2 * 2048> {
    Chanin<AudioChunkMsg> in;
    Chanout<FeatureTensorMsg> out;
public:
    PreprocessingProcess(Chanin<AudioChunkMsg> r, Chanout<FeatureTensorMsg> w) : in(r), out(w) {}
    osPriority_t taskPriority() const override { return osPriorityLow3; }  // was tskIDLE_PRIORITY + 3
    // 2*2048 words (was: 256-word CSP4CMSIS composition default from the
    // v1.2 API, which was very tight given this calls through nested
    // std::vector / std::function MFCC code 50 frames deep every cycle).

    void run() override {
        int32_t processed = 0; int32_t priming_step = 0;
        uint32_t mfcc_ms_accum = 0; uint32_t chan_send_wait_ms_accum = 0;
        uint32_t windowStartTick = osKernelGetTickCount();

        while (true) {
            AudioChunkMsg msg;
            in >> msg;

            void *tensor = cv_kws_preprocess_step(msg.chunk);
            mfcc_ms_accum += g_kws_mfcc_ms;

            if (tensor != nullptr) {
                FeatureTensorMsg out_msg{ tensor };
                uint32_t sendStart = osKernelGetTickCount();
                out << out_msg;
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
                float realtimeFactor = elapsedMs > 0 ? (kReportWindowMs / (float)elapsedMs) : 0.0f;
                kws_report_prep_stats(processed, mfcc_ms_accum, chan_send_wait_ms_accum, elapsedMs, realtimeFactor);
                g_prep_stack_hwm_words = (osThreadGetStackSpace(osThreadGetId()) / sizeof(uint32_t));
                mfcc_ms_accum = 0; chan_send_wait_ms_accum = 0;
                windowStartTick = now;
            }
        }
    }
};

class AcquisitionProcess : public CSProcessStatic<2048> {
    Chanout<AudioChunkMsg> out;
public:
    explicit AcquisitionProcess(Chanout<AudioChunkMsg> w) : out(w) {}
    osPriority_t taskPriority() const override { return osPriorityLow4; }  // was tskIDLE_PRIORITY + 4
    void run() override {
        int32_t last_current_buf = -1; int32_t miss_inf = 0;
        int32_t last_w_buf_idx = -1; // separate from last_current_buf: tracks the RAW
                                      // w_buf_idx last observed, for the freshness wait below.
                                      // last_current_buf holds w_buf_idx-1 (the completed
                                      // slot) and can never legitimately equal a live
                                      // w_buf_idx, so reusing it here never actually blocked --
                                      // this was silently true even at BLK_NUM=1; it only
                                      // became visible once the native cadence diverged from
                                      // downstream's incidental processing rate at BLK_NUM=2.
        uint32_t dma_wait_ms_accum = 0; uint32_t buf_asm_ms_accum = 0; uint32_t chan_send_wait_ms_accum = 0;
        uint32_t windowStartTick = osKernelGetTickCount();
        const uint32_t kHopBudgetMs = (BLK_NUM * QUARTER_SECOND_MONO_BYTES / 2) * 1000UL / 16000UL;

        while (true) {
            uint32_t iterStart = osKernelGetTickCount();
            uint32_t dmaWaitStart = osKernelGetTickCount();
            while (!kws_processing_complete) { SleepFor(1); }
            while (w_buf_idx == last_w_buf_idx) { SleepFor(1); }
            uint32_t dmaWaitEnd = osKernelGetTickCount();
            dma_wait_ms_accum += ticksToMs(dmaWaitEnd - dmaWaitStart);

            // Snapshot once: the rest of this iteration (memcpy/cache-invalidate/
            // channel send) can take longer than one native hop, so re-reading
            // the live w_buf_idx later would drift out of sync with what
            // current_buf below was actually computed from.
            int32_t observedWBufIdx = w_buf_idx;

            //int32_t current_buf = w_buf_idx;
            int32_t current_buf = (observedWBufIdx + NUM_BUFF - 1) % NUM_BUFF;
            if (last_current_buf >= 0) {
                int32_t expected = (last_current_buf + 1) % NUM_BUFF;
                if (current_buf != expected) {
                    miss_inf++;
                    kws_report_missed_inference(expected, current_buf);
                }
            }

            uint32_t bufAsmStart = osKernelGetTickCount();
            SCB_InvalidateDCache_by_Addr((uint32_t*)audio_buf[current_buf], BLK_NUM * QUARTER_SECOND_MONO_BYTES);
            uint32_t bufAsmEnd = osKernelGetTickCount();
            buf_asm_ms_accum += ticksToMs(bufAsmEnd - bufAsmStart);

            AudioChunkMsg msg{ audio_buf[current_buf] };
            uint32_t sendStart = osKernelGetTickCount();
            out << msg;
            uint32_t sendEnd = osKernelGetTickCount();
            chan_send_wait_ms_accum += ticksToMs(sendEnd - sendStart);

            last_current_buf = current_buf;
            last_w_buf_idx = observedWBufIdx;
            r_buf_idx++;

            if (r_buf_idx % 20 == 0) {
                uint32_t now = osKernelGetTickCount();
                uint32_t elapsedMs = ticksToMs(now - windowStartTick);
                float realtimeFactor = elapsedMs > 0 ? (kReportWindowMs / (float)elapsedMs) : 0.0f;
                kws_report_acq_stats(miss_inf, r_buf_idx, dma_wait_ms_accum, buf_asm_ms_accum, chan_send_wait_ms_accum, elapsedMs, realtimeFactor);

                // Snapshot + reset the ISR-updated ground-truth counters.
                // Not interrupt-safe against a torn read of the two u32s
                // together, but this is diagnostic-only and off by at most
                // one interval's worth -- irrelevant at this granularity.
                uint32_t dmaCbCount = g_dma_cb_count;
                uint32_t intervalAccum = g_dma_cb_interval_accum_ms;
                uint32_t intervalCount = g_dma_cb_interval_count;
                g_dma_cb_interval_accum_ms = 0;
                g_dma_cb_interval_count = 0;
                uint32_t avgIntervalMs = intervalCount > 0 ? (intervalAccum / intervalCount) : 0;
                kws_report_dma_cb_stats(dmaCbCount, avgIntervalMs);

                // FreeRTOS heap statistics (native: CMSIS-RTOS2 has no equivalent);
                // only the Ethos-U semaphore lives in this heap since 2.0.
                kws_report_mem_stats((uint32_t)xPortGetFreeHeapSize(),
                                      (uint32_t)xPortGetMinimumEverFreeHeapSize(),
                                      g_prep_stack_hwm_words, g_infer_stack_hwm_words);

                dma_wait_ms_accum = 0; buf_asm_ms_accum = 0; chan_send_wait_ms_accum = 0;
                windowStartTick = now;
            }

            uint32_t elapsedThisIterMs = ticksToMs(osKernelGetTickCount() - iterStart);
            if (elapsedThisIterMs + 1 < kHopBudgetMs) { SleepFor(1); }
        }
    }
};

// Priorities keep the pre-2.0 order (D5: tskIDLE_PRIORITY + 0..4 -> osPriorityLow..Low4,
// see each process's taskPriority()): MainApp (was + 4) above the network default
// (was + 2), so Run(..., StaticNetwork) creates all processes before any runs.
static constexpr osPriority_t MAIN_APP_PRIORITY = osPriorityLow4;
static constexpr osPriority_t NETWORK_PRIORITY  = osPriorityLow2;

// MainApp's stack and control block are static: creating the thread takes no heap.
// CMSIS-RTOS2 counts the stack in bytes. Provisional (was 4*2048 words); to be
// right-sized from measurements.
alignas(8) static uint8_t mainAppStack[4096];
static StaticTask_t mainAppControlBlock;

void MainApp_Task(void* params) {
    (void)params;
    SleepFor(10);  // 10 ms (1000 Hz tick)
    xprintf("\r\n--- KWS Pipeline starting (incl. PCA9685 I2C servo control) ---\r\n");

    if (cv_kws_preprocess_init() != 0) {
        xprintf("ERROR: cv_kws_preprocess_init failed!\r\n");
        osThreadExit();  // a thread must not return from its function
    }

    static AcquisitionProcess   acquisition(g_audioChan.writer());
    static PreprocessingProcess preprocessing(g_audioChan.reader(), g_featureChan.writer());
    static InferenceProcess     inference(g_featureChan.reader());
    static FilterProcess        filter(g_rawKwsChan.reader(), g_filteredKwsChan.writer());
    
    // Updated FSM initialization with the extra hardware output channel
    static FsmProcess           fsm(g_filteredKwsChan.reader(), g_reportChan.writer(), g_hwCmdChan.writer());
    static ReporterProcess      reporter(g_reportChan.reader());
    
    // PCA9685 process taking the ISR channel and the HW Command channel
    static Pca9685Process       pca9685_hw(g_pca9685_i2c_isr_chan.reader(), g_hwCmdChan.reader());

    // Execute the network (now 7 processes)
    Run(
        InParallel(acquisition, preprocessing, inference, filter, fsm, reporter, pca9685_hw),
        ExecutionMode::StaticNetwork,
        NETWORK_PRIORITY
    );

    osThreadExit();
}

extern "C" void RunProcessingChainTest(void)
{
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
