#include "csp/csp4cmsis.h"
#include "cmsis_os2.h"
#include "FreeRTOS.h"  // StaticTask_t: the control block of a statically created thread
#include <cstdio>

extern "C" {
    #include "hx_drv_timer.h"
    #include "hx_drv_scu.h"
    #include "WE2_device.h"
    #include "WE2_core.h"
}

using namespace csp;

// The timer interrupt hands over the latest tick count. An interrupt cannot
// wait for a partner, so it writes to a buffered channel through isrWriter();
// KeepNewest with one slot keeps only the latest count: if TimerProcess has
// not read the previous one yet, it is overwritten, and the missed tick shows
// up as a gap in the printed count instead of stalling anything.
static BufferedChannel<uint32_t, 1, BufferPolicy::KeepNewest> timerChannel;

extern "C" void timer1_callback(uint32_t event) {
    hx_drv_timer_ClearIRQ(TIMER_ID_1);
    static uint32_t count = 0;
    count++;
    (void)timerChannel.isrWriter().putFromISR(count);   // KeepNewest: never fails
}

class TimerProcess : public CSProcessStatic<256> {
public:
    const char* name() const override { return "TimerProcess"; }

    void run() override {
        printf("[CSP] Manual Engine Active. Waiting for Channel...\r\n");
        uint32_t val = 0;
        auto reader = timerChannel.reader();

        while (true) {
            // This blocks the task until the ISR writes to the channel
            reader.read(val); 
            printf(">>> CSP CHANNEL RECV: %lu\r\n", val);
        }
    }
};

class LogicProcess : public CSProcessStatic<256> {
public:
    const char* name() const override { return "LogicProcess"; }

    void run() override {
        while(true) {
            // Do some background AI or Logic
            SleepFor(Milliseconds(500));
            printf("Logic Heartbeat...\n");
        }
    }
};

// Priorities keep the pre-2.0 order: MainApp and the network were both
// tskIDLE_PRIORITY + 2, now both osPriorityLow2 (D5 mapping +0..+4 -> Low..Low4).
static constexpr osPriority_t MAIN_APP_PRIORITY = osPriorityLow2;
static constexpr osPriority_t NETWORK_PRIORITY  = osPriorityLow2;

// MainApp's stack and control block are static: creating the thread takes no heap.
// CMSIS-RTOS2 counts the stack in bytes. Provisional (was 4096 words); to be
// right-sized from measurements.
alignas(8) static uint8_t mainAppStack[4096];
static StaticTask_t mainAppControlBlock;

void MainApp_Task(void* params) {
    (void)params;
    SleepFor(Milliseconds(2000));
    printf("\r\n--- CSP4CMSIS Manual Channel Test ---\r\n");

    // Hardware Init
    hx_drv_scu_set_timer_clk_en(TIMER_ID_1, 1); 
    hx_drv_timer_init(TIMER_ID_1, HX_TIMER1_BASE);
    TIMER_CFG_T timer_cfg = {1000, TIMER_MODE_PERIODICAL, TIMER_CTRL_CPU, TIMER_STATE_DC};
    // An ISR that calls CSP4CMSIS or FreeRTOS must run at priority 5..7: at or
    // below CSP4CMSIS_MAX_SYSCALL_INTERRUPT_PRIORITY (5; 3 priority bits), so
    // that the RTOS's and the library's critical sections mask it. Neither the
    // SDK nor the driver sets a priority (the reset value 0 is the highest), so
    // set it here, before the interrupt is enabled.
    NVIC_SetPriority(TIMER1INT_IRQn, CSP4CMSIS_MAX_SYSCALL_INTERRUPT_PRIORITY);
    NVIC_EnableIRQ(TIMER1INT_IRQn);
    hx_drv_timer_hw_start(TIMER_ID_1, &timer_cfg, (Timer_ISREvent_t)timer1_callback);

    // Manual Execution: Just call the run method. 
    // The FreeRTOS task provides the 'life' for the process.
    static TimerProcess p1;
    static LogicProcess  p2;
    Run(InParallel(p1, p2), ExecutionMode::StaticNetwork, NETWORK_PRIORITY);

    // Run() returns immediately in StaticNetwork mode; the thread must
    // end itself rather than fall off the end of the function.
    osThreadExit();
}

extern "C" void RunProcessingChainTest(void) {
    osThreadAttr_t attr = {};
    attr.name       = "CspManual";
    attr.stack_mem  = mainAppStack;
    attr.stack_size = sizeof(mainAppStack);
    attr.cb_mem     = &mainAppControlBlock;
    attr.cb_size    = sizeof(mainAppControlBlock);
    attr.priority   = MAIN_APP_PRIORITY;
    if (osThreadNew(MainApp_Task, NULL, &attr) == NULL) {
        printf("ERROR: MainApp_Task creation failed!\r\n");
    }
}

