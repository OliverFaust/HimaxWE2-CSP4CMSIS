#include "csp/csp4cmsis.h"
#include "camera_process.h"
#include "inference_process.h"
#include "reporter_process.h"
#include "xprintf.h"
#include "cmsis_os2.h"
#include "FreeRTOS.h"  // StaticTask_t: the control block of a statically created thread

using namespace csp;

// Priorities keep the pre-2.0 order: MainApp (was tskIDLE_PRIORITY + 3) above the
// network (was + 2), so Run(..., StaticNetwork) creates all processes before any runs,
// and MainApp prints its line and ends before any of them runs.
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
    SleepFor(Milliseconds(500));

    // The console has one owner: the Reporter is the only process that prints while the
    // network runs. Camera and Inference send it report_t messages over one rendezvous
    // channel with two writers.
    static Channel<frame_t>  frame_chan;      // unbuffered
    static Channel<report_t> report_chan;     // unbuffered; writers: Camera, Inference

    static Camera    camera(frame_chan.writer(), report_chan.writer());
    static Inference inference(frame_chan.reader(), report_chan.writer());
    static CSProcess* const reported[] = { &camera, &inference };   // for the stack report
    static Reporter  reporter(report_chan.reader(), reported, 2);

    Run(InParallel(camera, inference, reporter), ExecutionMode::StaticNetwork, NETWORK_PRIORITY);

    // StaticNetwork: Run() has created the processes and returns at once; they run on their
    // own, so MainApp can end. It runs above the network, so this line is printed first.
    xprintf("*** MainApp_Task: network started. Terminating. ***\r\n");
    osThreadExit();
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
