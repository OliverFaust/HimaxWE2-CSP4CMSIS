#include "csp/csp4cmsis.h"
#include "camera_process.h"
#include "inference_process.h"
#include "reporter_process.h"
#include "xprintf.h"
#include "cmsis_os2.h"
#include "FreeRTOS.h"  // StaticTask_t

using namespace csp;

#ifndef CSP_STACK_REPORT_INTERVAL_MS
#define CSP_STACK_REPORT_INTERVAL_MS (3000)
#endif

// MainApp runs above the network: Run(..., StaticNetwork) creates all processes before any
// runs, and a busy process cannot delay the stack report.
static constexpr osPriority_t MAIN_APP_PRIORITY = osPriorityLow3;
static constexpr osPriority_t NETWORK_PRIORITY  = osPriorityLow2;

// Static stack (1 KB; 464 bytes used) and control block: no heap.
alignas(8) static uint8_t mainAppStack[1024];
static StaticTask_t mainAppControlBlock;

static report_t stackReport(const char* name, uint32_t allocated_bytes, uint32_t hwm_words)
{
    report_t r = {};
    r.kind = ReportKind::Stack;
    r.name = name;
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

    static Channel<frame_t>  frame_chan;
    static Channel<report_t> report_chan;     // writers: Camera, Inference, MainApp

    static Camera    camera(frame_chan.writer(), report_chan.writer());
    static Inference inference(frame_chan.reader(), report_chan.writer());
    static Reporter  reporter(report_chan.reader());

    auto network = InParallel(camera, inference, reporter);   // kept for forEachProcess()
    Run(network, ExecutionMode::StaticNetwork, NETWORK_PRIORITY);

    // MainApp is a plain CMSIS-RTOS2 thread, yet it may write to a rendezvous channel.
    // It never prints: its stack report goes to the Reporter like every other report.
    Chanout<report_t> report_out = report_chan.writer();
    while (true) {
        SleepFor(Milliseconds(CSP_STACK_REPORT_INTERVAL_MS));
        network.forEachProcess([&](CSProcess& p) {
            report_out << stackReport(p.name(), p.stackWords() * sizeof(uint32_t),
                                      p.stackHighWaterMarkWords());
        });
        report_out << stackReport("CSP_Main", sizeof(mainAppStack),
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
