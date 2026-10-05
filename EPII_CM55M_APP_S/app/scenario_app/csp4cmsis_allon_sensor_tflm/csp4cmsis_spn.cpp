#include "csp/csp4cmsis.h"
#include "camera_process.h"
#include "inference_process.h"
#include "console_process.h"
#include "xprintf.h"
#include "cmsis_os2.h"
#include "FreeRTOS.h"  // StaticTask_t: the control block of a statically created thread

using namespace csp;

// camera/inference/console run forever, so there's no natural
// "network finished" point to report stack usage at -- report
// periodically instead. This is a live worst-observed-so-far reading,
// trustworthy only once each process's deepest call path has actually
// been exercised.
#ifndef CSP_STACK_REPORT_INTERVAL_MS
#define CSP_STACK_REPORT_INTERVAL_MS (3000)
#endif

// Priorities keep the pre-2.0 order: MainApp (was tskIDLE_PRIORITY + 3) above the
// network (was + 2), so Run(..., StaticNetwork) creates all processes before any runs.
static constexpr osPriority_t MAIN_APP_PRIORITY = osPriorityLow3;
static constexpr osPriority_t NETWORK_PRIORITY  = osPriorityLow2;

// MainApp_Task isn't a CSProcess, so its stack isn't sized via
// CSProcessStatic<N> -- it's given explicitly here, statically, like its
// control block: creating the thread takes no heap. CMSIS-RTOS2 counts the
// stack in bytes (2048 = the previous 512 words).
alignas(8) static uint8_t mainAppStack[2048];
static StaticTask_t mainAppControlBlock;

void MainApp_Task(void* params)
{
    (void)params;
    SleepFor(500);  // 500 ms (1000 Hz tick)

    static Channel<frame_t>  frame_chan;      // unbuffered
    static Channel<result_t> result_chan;

    static Camera camera(frame_chan.writer());
    static Inference inference(frame_chan.reader(), result_chan.writer());
    static Console   console(result_chan.reader());

    // Kept as a named object rather than passed straight into Run() --
    // ParallelHelper still holds references to camera/inference/console
    // after Run() returns, which the report loop below needs.
    auto network = InParallel(camera, inference, console);
    Run(network, ExecutionMode::StaticNetwork, NETWORK_PRIORITY);

    xprintf("*** MainApp_Task: Run() returned, entering report loop ***\r\n");

    while (true) {
        SleepFor(CSP_STACK_REPORT_INTERVAL_MS);  // ticks = ms at 1000 Hz

        uint32_t unused_bytes = osThreadGetStackSpace(osThreadGetId());
        xprintf("CSP_Main: %u/%u bytes used (%u bytes unused headroom)\r\n",
                (unsigned)(sizeof(mainAppStack) - unused_bytes),
                (unsigned)sizeof(mainAppStack), (unsigned)unused_bytes);

        network.forEachProcess([](CSProcess& p) {
            size_t allocated_words = p.stackWords();
            size_t allocated_bytes = allocated_words * sizeof(uint32_t);

            uint32_t hwm = p.stackHighWaterMarkWords();
            if (hwm == CSP_STACK_HWM_UNAVAILABLE) {
                xprintf("%s: allocated = %u words (%u bytes), HWM unavailable\r\n",
                        p.name(), (unsigned)allocated_words, (unsigned)allocated_bytes);
            } else {
                size_t unused_bytes = hwm * sizeof(uint32_t);
                size_t used_bytes = (unused_bytes <= allocated_bytes)
                                        ? allocated_bytes - unused_bytes
                                        : 0;
                xprintf("%s: %u/%u bytes used (%u bytes unused headroom, %u words HWM)\r\n",
                        p.name(), (unsigned)used_bytes, (unsigned)allocated_bytes,
                        (unsigned)unused_bytes, (unsigned)hwm);
            }
        });
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
