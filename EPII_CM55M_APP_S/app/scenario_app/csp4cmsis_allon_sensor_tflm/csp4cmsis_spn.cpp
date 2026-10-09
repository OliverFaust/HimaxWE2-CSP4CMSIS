#include "csp/csp4cmsis.h"
#include "camera_process.h"
#include "inference_process.h"
#include "reporter_process.h"
#include "xprintf.h"
#include "cmsis_os2.h"
#include "FreeRTOS.h"  // StaticTask_t: the control block of a statically created thread

using namespace csp;

// MainApp sends the stack report every CSP_STACK_REPORT_INTERVAL_MS, whatever the network is
// doing, so the report continues when the pipeline stalls. It is a live
// worst-observed-so-far reading, trustworthy only once each thread's deepest call path has
// been exercised.
#ifndef CSP_STACK_REPORT_INTERVAL_MS
#define CSP_STACK_REPORT_INTERVAL_MS (3000)
#endif

// Priorities keep the pre-2.0 order: MainApp (was tskIDLE_PRIORITY + 3) above the
// network (was + 2). Run(..., StaticNetwork) therefore creates all processes before any
// runs, and MainApp's stack report is not held up by a busy network process; it then waits
// on the report channel while the Reporter (network priority) prints.
static constexpr osPriority_t MAIN_APP_PRIORITY = osPriorityLow3;
static constexpr osPriority_t NETWORK_PRIORITY  = osPriorityLow2;

// MainApp_Task isn't a CSProcess, so its stack isn't sized via
// CSProcessStatic<N> -- it's given explicitly here, statically, like its
// control block: creating the thread takes no heap. CMSIS-RTOS2 counts the
// stack in bytes. Measured on the board: 464 bytes used (it never prints).
alignas(8) static uint8_t mainAppStack[1024];
static StaticTask_t mainAppControlBlock;

static report_t stackReport(ReportSource source, uint32_t allocated_bytes, uint32_t hwm_words)
{
    report_t r = {};
    r.kind = ReportKind::Stack;
    r.source = source;
    r.value[1] = (int32_t)allocated_bytes;
    if (hwm_words == CSP_STACK_HWM_UNAVAILABLE) {
        r.value[2] = -1;
    } else {
        uint32_t unused_bytes = hwm_words * sizeof(uint32_t);
        r.value[0] = (int32_t)((unused_bytes <= allocated_bytes) ? allocated_bytes - unused_bytes : 0);
        r.value[2] = (int32_t)hwm_words;
    }
    return r;
}

void MainApp_Task(void* params)
{
    (void)params;
    SleepFor(Milliseconds(500));

    // The console has one owner: the Reporter is the only process that prints while the
    // network runs. Camera, Inference and MainApp send it report_t messages over one
    // rendezvous channel with three writers. MainApp never prints.
    static Channel<frame_t>  frame_chan;      // unbuffered
    static Channel<report_t> report_chan;     // unbuffered; writers: Camera, Inference, MainApp

    static Camera    camera(frame_chan.writer(), report_chan.writer());
    static Inference inference(frame_chan.reader(), report_chan.writer());
    static Reporter  reporter(report_chan.reader());

    // Kept as a named object: the stack report below walks it with forEachProcess().
    auto network = InParallel(camera, inference, reporter);
    Run(network, ExecutionMode::StaticNetwork, NETWORK_PRIORITY);

    // MainApp is an ordinary CMSIS-RTOS2 thread with its own writer end: a rendezvous may be
    // used by any thread (it blocks on thread flag 0 of the calling thread, which MainApp
    // uses for nothing else).
    Chanout<report_t> report_out = report_chan.writer();
    static constexpr ReportSource kSources[] = {
        ReportSource::Camera, ReportSource::Inference, ReportSource::Reporter };  // InParallel order

    while (true) {
        SleepFor(Milliseconds(CSP_STACK_REPORT_INTERVAL_MS));

        size_t i = 0;
        network.forEachProcess([&](CSProcess& p) {
            report_out << stackReport(kSources[i++], p.stackWords() * sizeof(uint32_t),
                                      p.stackHighWaterMarkWords());
        });
        report_out << stackReport(ReportSource::Main, sizeof(mainAppStack),
                                  osThreadGetStackSpace(osThreadGetId()) / sizeof(uint32_t));
    }
}

extern "C" void RunProcessingChainTest(void)
{
    osThreadAttr_t attr = {};
    attr.name       = "CSP_Main";
    attr.stack_mem  = mainAppStack;
    attr.stack_size = sizeof(mainAppStack);
    attr.cb_mem     = &mainAppControlBlock;
    attr.cb_size    = sizeof(mainAppControlBlock);
    attr.priority   = MAIN_APP_PRIORITY;
    if (osThreadNew(MainApp_Task, NULL, &attr) == NULL) {
        xprintf("ERROR: MainApp_Task creation failed!\r\n");
    }
}
