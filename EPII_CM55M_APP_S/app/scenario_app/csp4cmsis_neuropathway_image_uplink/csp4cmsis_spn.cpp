#include "csp/csp4cmsis.h"
#ifdef FRAME_SOURCE_SDCARD
#include "file_source_process.h"
#else
#include "camera_process.h"
#endif
#include "inference_process.h"
#include "reporter_process.h"
#include "command_process.h"
#ifdef SD_BENCH
#include "sd_bench_process.h"
#endif
#include "xprintf.h"
#include "cmsis_os2.h"
#include "FreeRTOS.h"

using namespace csp;

#ifndef CSP_STACK_REPORT_INTERVAL_MS
#define CSP_STACK_REPORT_INTERVAL_MS (3000)
#endif

static constexpr osPriority_t MAIN_APP_PRIORITY = osPriorityLow3;
static constexpr osPriority_t NETWORK_PRIORITY  = osPriorityLow2;

alignas(8) static uint8_t mainAppStack[1536];
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
    xprintf("CSP_Main: started\r\n");
    SleepFor(Milliseconds(500));

#ifdef SD_BENCH
    static BufferedChannel<uint8_t, 1> free_chan;
    static BufferedChannel<uint8_t, 1> ready_chan;
    static Channel<report_t> report_chan;

    static SdBench   bench(report_chan.writer());
    static Reporter  reporter(report_chan.reader(), free_chan.writer(), ready_chan.writer());

    auto network = InParallel(bench, reporter);
#else
    static Channel<frame_t>  frame_chan;
    static Channel<release_t> release_chan;
    static BufferedChannel<uint8_t, 1> free_chan;
    static BufferedChannel<uint8_t, 1> ready_chan;
    static BufferedChannel<command_t, 1> cmd_chan;
    static Channel<report_t> report_chan;

#ifdef FRAME_SOURCE_SDCARD
    static FileSource source(frame_chan.writer(), release_chan.reader(), cmd_chan.reader(), report_chan.writer());
#else
    static Camera    source(frame_chan.writer(), release_chan.reader(), cmd_chan.reader(), report_chan.writer());
#endif
    static Inference inference(frame_chan.reader(), release_chan.writer(), free_chan.reader(), ready_chan.reader(),
                               report_chan.writer());
    static Reporter  reporter(report_chan.reader(), free_chan.writer(), ready_chan.writer());
    static Command   command(cmd_chan.writer(), report_chan.writer());

    auto network = InParallel(source, inference, reporter, command);
#endif
    Run(network, ExecutionMode::StaticNetwork, NETWORK_PRIORITY);

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
