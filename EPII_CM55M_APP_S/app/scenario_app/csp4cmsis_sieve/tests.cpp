#include "csp/csp4cmsis.h"
#include "cmsis_os2.h"
#include "FreeRTOS.h"  // StaticTask_t: the control block of a statically created thread
#include <cstdio>

using namespace csp;

// --- 1. The Number Generator ---
// Sends numbers 2, 3, 4, 5... into the chain.
class NaturalNumbers : public CSProcessStatic<256> {
private:
    Chanout<int> out;
    int limit;
public:
    NaturalNumbers(Chanout<int> w, int max_n) : out(w), limit(max_n) {}
    const char* name() const override { return "NaturalNumbers"; }

    void run() override {
        for (int i = 2; i <= limit; ++i) {
            out << i;
        }
        // Done: returning from run() ends this process's thread.
    }
};

// --- 2. The Prime Filter Process ---
// Holds a prime 'p'. For every 'n' it receives, it only passes 'n' 
// to the next stage if (n % p != 0).
class PrimeFilter : public CSProcessStatic<256> {
private:
    Chanin<int> in;
    Chanout<int> out;
    int my_prime = -1;
    int id;
public:
    PrimeFilter(Chanin<int> r, Chanout<int> w, int filter_id) 
        : in(r), out(w), id(filter_id) {}
    const char* name() const override { return "PrimeFilter"; }

    void run() override {
        int candidate;
        
        // The very first number this filter receives is its own prime
        in >> my_prime;
        printf("[Filter %d] Discovered Prime: %d\r\n", id, my_prime);

        while (true) {
            in >> candidate;
            if (candidate % my_prime != 0) {
                // Not divisible, pass it to the next filter in the chain
                out << candidate;
            }
        }
    }
};

// --- 3. The Sink (Receiver) ---
// The final stage that just prints whatever makes it through all filters.
class PrimeSink : public CSProcessStatic<256> {
private:
    Chanin<int> in;
public:
    PrimeSink(Chanin<int> r) : in(r) {}
    const char* name() const override { return "PrimeSink"; }

    void run() override {
        int found;
        while (true) {
            in >> found;
            printf("[Sink] Leaked through all filters: %d (Potential Prime)\r\n", found);
        }
    }
};

// --- 4. Main Network Construction ---
#define NUM_FILTERS 5 

// Priorities keep the pre-2.0 order: MainApp (was tskIDLE_PRIORITY + 3) above the
// network (was + 2), so Run(..., StaticNetwork) creates all processes before any runs.
static constexpr osPriority_t MAIN_APP_PRIORITY = osPriorityLow3;
static constexpr osPriority_t NETWORK_PRIORITY  = osPriorityLow2;

// MainApp's stack and control block are static: creating the thread takes no heap.
// CMSIS-RTOS2 counts the stack in bytes. Provisional (was 4096 words): printf from
// full newlib needs a generous stack; to be right-sized from measurements.
alignas(8) static uint8_t mainAppStack[4096];
static StaticTask_t mainAppControlBlock;

void MainApp_Task(void* params) {
    (void)params;
    SleepFor(Milliseconds(500));
    printf("\r\n--- Launching Prime Sieve Daisy Chain ---\r\n");

    // We need NUM_FILTERS + 1 channels to connect the stages
    // Generator -> [C0] -> Filter0 -> [C1] -> Filter1 -> [C2] -> Sink
    static Channel<int> channels[NUM_FILTERS + 1];

    static NaturalNumbers generator(channels[0].writer(), 50);
    static PrimeSink sink(channels[NUM_FILTERS].reader());

    // Create the filters
    static PrimeFilter f0(channels[0].reader(), channels[1].writer(), 0);
    static PrimeFilter f1(channels[1].reader(), channels[2].writer(), 1);
    static PrimeFilter f2(channels[2].reader(), channels[3].writer(), 2);
    static PrimeFilter f3(channels[3].reader(), channels[4].writer(), 3);
    static PrimeFilter f4(channels[4].reader(), channels[5].writer(), 4);

    Run(
        InParallel(generator, f0, f1, f2, f3, f4, sink),
        ExecutionMode::StaticNetwork,
        NETWORK_PRIORITY
    );

    // Run() returns immediately in StaticNetwork mode; the thread must
    // end itself rather than fall off the end of the function.
    osThreadExit();
}

void RunProcessingChainTest(void) {
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
