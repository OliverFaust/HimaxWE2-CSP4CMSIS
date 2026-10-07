#include "csp/csp4cmsis.h"
#include "cmsis_os2.h"
#include "FreeRTOS.h"  // StaticTask_t: the control block of a statically created thread
#include <cstdio>

using namespace csp;

// Constants for 3x3 Multiplication
#define DIM 3
// Originally (DIM + DIM - 1) = 5 pulses for a full systolic-array drain,
// then changed to just DIM = 3 -- collapsed to a single #define instead of
// two (the second silently redefined the first, which is what triggered
// the "TOTAL_PULSES redefined" build warning).
#define TOTAL_PULSES DIM // Change from 5 to 3

// How often to print a stack-usage report for the whole network. This is a
// *live* reading (CSProcess::stackHighWaterMarkWords()), not a one-shot
// end-of-run report -- every process here parks in SleepFor(Forever)
// once its TOTAL_PULSES are done rather than exiting (an exited thread's handle can't be queried), so the report loop
// below keeps running for the life of the task. Read the HWM columns to
// right-size the provisional CSProcessStatic<N> values below -- those
// numbers were picked before this test ever ran, not measured.
#ifndef CSP_STACK_REPORT_INTERVAL_MS
#define CSP_STACK_REPORT_INTERVAL_MS (3000)
#endif

// Priorities keep the pre-2.0 order: MainApp (was tskIDLE_PRIORITY + 3) above the
// network (was + 2), so Run(..., StaticNetwork) creates all processes before any runs.
static constexpr osPriority_t MAIN_APP_PRIORITY = osPriorityLow3;
static constexpr osPriority_t NETWORK_PRIORITY  = osPriorityLow2;

// MainApp's stack and control block are static: creating the thread takes no heap.
// CMSIS-RTOS2 counts the stack in bytes. Provisional (was 4096 words); the report
// loop below prints MainApp's own headroom, to right-size it from.
alignas(8) static uint8_t mainAppStack[4096];
static StaticTask_t mainAppControlBlock;

// CSProcess is abstract: stackWords()/stackBuffer()/taskBuffer() are pure
// virtual, so each process needs its own static stack + StaticTask_t
// storage. CSProcessStatic<N> is the library helper that supplies that
// storage -- inherit from it instead of CSProcess directly, with N as the
// stack size in words. 1024 is a provisional starting point for
// ProcessingElement (a tight loop, but with two printf calls per pulse);
// confirm/right-size against the HWM report added to MainApp_Task below.
class ProcessingElement : public CSProcessStatic<1024> {
private:
    Chanin<int>  in_left, in_top;
    Chanout<int> out_right, out_bottom;
    int accumulator = 0;
    int row, col;
    char name_buf[8]; // built once in the constructor -- distinguishes the
                       // 9 PE instances in the stack report below.

public:
    ProcessingElement(Chanin<int> l, Chanin<int> t, Chanout<int> r, Chanout<int> b, int r_idx, int c_idx)
        : in_left(l), in_top(t), out_right(r), out_bottom(b), row(r_idx), col(c_idx) {
        snprintf(name_buf, sizeof(name_buf), "PE%d%d", r_idx, c_idx);
    }
    const char* name() const override { return name_buf; }

    void run() override {
        int valA, valB;
        
        for (int i = 0; i < TOTAL_PULSES; ++i) {
            // Trace: Waiting for data
            // printf("[PE %d,%d] Pulse %d: Waiting...\r\n", row, col, i);

            in_left >> valA;
            in_top >> valB;

            accumulator += (valA * valB);

            // Trace: Calculation pulse
            printf("[PE %d,%d] Pulse %d: In(%d, %d) Accum: %d\r\n", 
                    row, col, i, valA, valB, accumulator);

            out_right << valA;
            out_bottom << valB;
        }

        printf(">>> [PE %d,%d] COMPLETED. Final: %d\r\n", row, col, accumulator);
        
        while (true) SleepFor(Forever);
    }
};

// --- 2. Feeder Process ---
// 512 words is provisional -- trivial loop, no deep call stack.
class Feeder : public CSProcessStatic<512> {
private:
    Chanout<int> out;
    int data[DIM];
    int stagger;
    const char* label; // string literal from the call site; no need to copy
public:
    Feeder(Chanout<int> o, int d0, int d1, int d2, int s, const char* lbl)
        : out(o), stagger(s), label(lbl) {
        data[0] = d0; data[1] = d1; data[2] = d2;
    }
    const char* name() const override { return label; }

    void run() override {
        // 1. Staggering: inject 0s to delay the entry of real data
        for (int i = 0; i < stagger; ++i) out << 0;
        
        // 2. Real Data: inject the row/column values
        for (int i = 0; i < DIM; ++i) out << data[i];

        // 3. Flushing: inject 0s to keep the rest of the array moving
        int remaining = TOTAL_PULSES - DIM - stagger;
        for (int i = 0; i < remaining; ++i) out << 0;

        while (true) SleepFor(Forever);
    }
};

// --- 3. Sink Process ---
// Crucial: Sinks must consume data to allow the edge PEs to finish their 'out <<' calls.
// 512 words is provisional -- trivial loop, no deep call stack.
class Sink : public CSProcessStatic<512> {
private:
    Chanin<int> in;
    const char* label;
public:
    Sink(Chanin<int> i, const char* lbl) : in(i), label(lbl) {}
    const char* name() const override { return label; }
    void run() override {
        int trash;
        for (int i = 0; i < TOTAL_PULSES; ++i) {
            in >> trash;
        }
        while (true) SleepFor(Forever);
    }
};

// --- 4. Main Application ---
void MainApp_Task(void* params) {
    (void)params;
    SleepFor(Milliseconds(1000));
    printf("\r\n--- Systolic Array 3x3: A * Identity ---\r\n");

    // Static channels for the grid
    static Channel<int> h[3][4]; // Horizontal channels
    static Channel<int> v[4][3]; // Vertical channels

    // Matrix A (Rows) - Stagger 0
    static Feeder row0(h[0][0].writer(), 1, 2, 3, 0, "row0"); 
    static Feeder row1(h[1][0].writer(), 4, 5, 6, 0, "row1"); 
    static Feeder row2(h[2][0].writer(), 7, 8, 9, 0, "row2"); 

    // Matrix B (Cols) - Identity - Stagger 0
    static Feeder col0(v[0][0].writer(), 1, 0, 0, 0, "col0"); 
    static Feeder col1(v[0][1].writer(), 0, 1, 0, 0, "col1"); 
    static Feeder col2(v[0][2].writer(), 0, 0, 1, 0, "col2");

    // Grid of PEs
    static ProcessingElement pe00(h[0][0].reader(), v[0][0].reader(), h[0][1].writer(), v[1][0].writer(), 0, 0);
    static ProcessingElement pe01(h[0][1].reader(), v[0][1].reader(), h[0][2].writer(), v[1][1].writer(), 0, 1);
    static ProcessingElement pe02(h[0][2].reader(), v[0][2].reader(), h[0][3].writer(), v[1][2].writer(), 0, 2);

    static ProcessingElement pe10(h[1][0].reader(), v[1][0].reader(), h[1][1].writer(), v[2][0].writer(), 1, 0);
    static ProcessingElement pe11(h[1][1].reader(), v[1][1].reader(), h[1][2].writer(), v[2][1].writer(), 1, 1);
    static ProcessingElement pe12(h[1][2].reader(), v[1][2].reader(), h[1][3].writer(), v[2][2].writer(), 1, 2);

    static ProcessingElement pe20(h[2][0].reader(), v[2][0].reader(), h[2][1].writer(), v[3][0].writer(), 2, 0);
    static ProcessingElement pe21(h[2][1].reader(), v[2][1].reader(), h[2][2].writer(), v[3][1].writer(), 2, 1);
    static ProcessingElement pe22(h[2][2].reader(), v[2][2].reader(), h[2][3].writer(), v[3][2].writer(), 2, 2);

    // Edge Sinks
    static Sink sH0(h[0][3].reader(), "sH0"), sH1(h[1][3].reader(), "sH1"), sH2(h[2][3].reader(), "sH2");
    static Sink sV0(v[3][0].reader(), "sV0"), sV1(v[3][1].reader(), "sV1"), sV2(v[3][2].reader(), "sV2");

    auto network = InParallel(
        row0, row1, row2, 
        col0, col1, col2, 
        pe00, pe01, pe02, 
        pe10, pe11, pe12, 
        pe20, pe21, pe22,
        sH0, sH1, sH2, sV0, sV1, sV2
    );
    Run(network, ExecutionMode::StaticNetwork, NETWORK_PRIORITY);

    printf("*** MainApp_Task: Run() returned, entering stack-report loop ***\r\n");

    // Every process here parks in SleepFor(Forever) once it's done
    // with its TOTAL_PULSES rather than exiting, so there's no "network
    // finished" point to report stack usage at -- report periodically.
    while (true) {
        SleepFor(Milliseconds(CSP_STACK_REPORT_INTERVAL_MS));

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

void RunProcessingChainTest(void) {
    // Note: Task creation is the only 'dynamic' part remaining, standard for FreeRTOS
    osThreadAttr_t attr = {};
    attr.name       = "MainApp";
    attr.stack_mem  = mainAppStack;
    attr.stack_size = sizeof(mainAppStack);
    attr.cb_mem     = &mainAppControlBlock;
    attr.cb_size    = sizeof(mainAppControlBlock);
    attr.priority   = MAIN_APP_PRIORITY;
    if (osThreadNew(MainApp_Task, NULL, &attr) == NULL) {
        printf("ERROR: MainApp_Task creation failed!\r\n");
    }
}
