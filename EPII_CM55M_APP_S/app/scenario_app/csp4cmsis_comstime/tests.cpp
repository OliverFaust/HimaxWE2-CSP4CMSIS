#include "csp/csp4cmsis.h"
#include "cmsis_os2.h"
#include "FreeRTOS.h"  // StaticTask_t: the control block of a statically created thread
#include <cstdio>

using namespace csp;

// How often to print a stack-usage report for the whole network. This is a
// *live* reading (CSProcess::stackHighWaterMarkWords()), not a one-shot
// end-of-run report -- every process in this ring runs forever by design,
// so the report loop below keeps running for the life of the task. Read
// the HWM columns to right-size the provisional CSProcessStatic<N> values
// below -- those numbers were picked before this test ever ran, not
// measured.
#ifndef CSP_STACK_REPORT_INTERVAL_MS
#define CSP_STACK_REPORT_INTERVAL_MS (3000)
#endif

// Priorities keep the pre-2.0 order: MainApp (was tskIDLE_PRIORITY + 3) above the
// network (was + 2), so Run(..., StaticNetwork) creates all processes before any runs.
static constexpr osPriority_t MAIN_APP_PRIORITY = osPriorityLow3;
static constexpr osPriority_t NETWORK_PRIORITY  = osPriorityLow2;

// MainApp's stack and control block are static: creating the thread takes no heap.
// CMSIS-RTOS2 counts the stack in bytes. Provisional (was 2048 words); the report
// loop below prints MainApp's own headroom, to right-size it from.
alignas(8) static uint8_t mainAppStack[4096];
static StaticTask_t mainAppControlBlock;

// --- 1. Basic Ring Components ---

// CSProcess is abstract: stackWords()/stackBuffer()/taskBuffer() are pure
// virtual, so each process needs its own static stack + StaticTask_t
// storage. CSProcessStatic<N> is the library helper that supplies that
// storage -- inherit from it instead of CSProcess directly, with N as the
// stack size in words. 512 is a provisional starting point for the trivial
// ring stages (Prefix/Successor/Delta/Trigger); confirm/right-size against
// the HWM report added to MainApp_Task below.
class Prefix : public CSProcessStatic<512> {
    Chanin<int> in; Chanout<int> out; int initial_val;
public:
    Prefix(Chanin<int> r, Chanout<int> w, int init) : in(r), out(w), initial_val(init) {}
    const char* name() const override { return "Prefix"; }
    void run() override {
        out << initial_val; 
        int x;
        while (true) { in >> x; out << x; }
    }
};

class Successor : public CSProcessStatic<512> {
    Chanin<int> in; Chanout<int> out;
public:
    Successor(Chanin<int> r, Chanout<int> w) : in(r), out(w) {}
    const char* name() const override { return "Successor"; }
    void run() override {
        int x;
        while (true) { in >> x; out << (x + 1); }
    }
};

class Delta : public CSProcessStatic<512> {
    Chanin<int> in; Chanout<int> outA, outB;
public:
    Delta(Chanin<int> r, Chanout<int> wA, Chanout<int> wB) : in(r), outA(wA), outB(wB) {}
    const char* name() const override { return "Delta"; }
    void run() override {
        int x;
        while (true) {
            in >> x;
            outB << x; // Branch to Consumer
            outA << x; // Branch to Ring
        }
    }
};

// --- 2. The Consumer using ALT ---

// 1024 words is provisional: holds a 2-guard Alternative on the stack plus
// calls printf with float formatting (%.2f), which is stack-hungrier on
// newlib than plain integer printf. Confirm against the HWM report below.
class ComstimeConsumer : public CSProcessStatic<1024> {
    Chanin<int> data_in;
    Chanin<bool> trigger_in;
public:
    ComstimeConsumer(Chanin<int> data, Chanin<bool> trigger) 
        : data_in(data), trigger_in(trigger) {}
    const char* name() const override { return "ComstimeConsumer"; }

    void run() override {
        int val = 0;
        bool signal = false;
        uint32_t count = 0;
        const uint32_t benchmark_limit = 10000;

        Alternative alt(data_in | val, trigger_in | signal);

        printf("[Comstime] Benchmark starting. Measuring %lu cycles...\n", benchmark_limit);
        
        uint32_t start_time = osKernelGetTickCount();

        while (true) {
            int selected = alt.fairSelect();

            if (selected == 0) { 
                if (++count >= benchmark_limit) {
                    uint32_t end_time = osKernelGetTickCount();
                    float total_ms = (float)(end_time - start_time) * 1000.0f / (float)osKernelGetTickFreq();
                    float micro_per_loop = (total_ms * 1000.0f) / (float)benchmark_limit;
                    
                    printf("--- Comstime Results ---\r\n");
                    printf("Iterations: %lu\r\n", count);
                    printf("Total Time: %.2f ms\r\n", total_ms);
                    printf("Avg Latency: %.2f us/cycle\r\n", micro_per_loop);
                    printf("Last Value: %d\r\n", val);
                    printf("------------------------\r\n");
                    
                    count = 0;
                    start_time = osKernelGetTickCount();
                }
            } else if (selected == 1) {
                printf(">>> [ALT] External Trigger Event Latency Check <<<\r\n");
            }
        }
    }
};

// --- 3. External Trigger ---

class Trigger : public CSProcessStatic<512> {
    Chanout<bool> out;
public:
    Trigger(Chanout<bool> w) : out(w) {}
    const char* name() const override { return "Trigger"; }
    void run() override {
        while (true) {
            SleepFor(1000);  // 1 s (1000 Hz tick)
            bool dummy = true;
            out << dummy;
        }
    }
};

// --- 4. Main App Task ---

void MainApp_Task(void* params) {
    (void)params;
    SleepFor(500);  // 500 ms (1000 Hz tick)
    
    // Channels
    static Channel<int> c1, c2, c3, c4;
    static Channel<bool> c_trigger;

    // Process Instances
    static Successor proc_succ(c3.reader(), c1.writer());
    static Prefix    proc_pref( c1.reader(),  c2.writer(), 0);
    static Delta     proc_delt( c2.reader(),  c3.writer(), c4.writer());
    static ComstimeConsumer proc_cons(c4.reader(), c_trigger.reader());
    static Trigger   proc_trig(c_trigger.writer());

    auto network = InParallel(proc_succ, proc_pref, proc_delt, proc_cons, proc_trig);
    Run(network, ExecutionMode::StaticNetwork, NETWORK_PRIORITY);

    printf("*** MainApp_Task: Run() returned, entering stack-report loop ***\r\n");

    // Every process in the ring runs forever by design, so there's no
    // "network finished" point to report stack usage at -- report
    // periodically instead.
    while (true) {
        SleepFor(CSP_STACK_REPORT_INTERVAL_MS);  // ticks = ms at 1000 Hz

        uint32_t unused_bytes = osThreadGetStackSpace(osThreadGetId());
        printf("MainApp: %u/%u bytes used (%u bytes unused headroom)\r\n",
                (unsigned)(sizeof(mainAppStack) - unused_bytes),
                (unsigned)sizeof(mainAppStack), (unsigned)unused_bytes);

        network.forEachProcess([](CSProcess& p) {
            // API 1.3: stack depth is fixed at compile time -- no more
            // resolveStackWords()/fallback constant to consult, just ask
            // the process directly.
            size_t allocated_words = p.stackWords();
            size_t allocated_bytes = allocated_words * sizeof(uint32_t);

            uint32_t hwm = p.stackHighWaterMarkWords();
            if (hwm == CSP_STACK_HWM_UNAVAILABLE) {
                printf("%s: allocated = %u words (%u bytes), HWM unavailable\r\n",
                        p.name(), (unsigned)allocated_words, (unsigned)allocated_bytes);
            } else {
                size_t unused_bytes = hwm * sizeof(uint32_t);
                size_t used_bytes = (unused_bytes <= allocated_bytes)
                                        ? allocated_bytes - unused_bytes
                                        : 0; // guard against any inconsistency
                printf("%s: %u/%u bytes used (%u bytes unused headroom, %u words HWM)\r\n",
                        p.name(), (unsigned)used_bytes, (unsigned)allocated_bytes,
                        (unsigned)unused_bytes, (unsigned)hwm);
            }
        });
    }
}

extern "C" void RunProcessingChainTest(void) {
    osThreadAttr_t attr = {};
    attr.name       = "ComsMain";
    attr.stack_mem  = mainAppStack;
    attr.stack_size = sizeof(mainAppStack);
    attr.cb_mem     = &mainAppControlBlock;
    attr.cb_size    = sizeof(mainAppControlBlock);
    attr.priority   = MAIN_APP_PRIORITY;
    if (osThreadNew(MainApp_Task, NULL, &attr) == NULL) {
        printf("ERROR: MainApp_Task creation failed!\r\n");
    }
}
