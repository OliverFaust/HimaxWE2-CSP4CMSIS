#include "csp/csp4cmsis.h"
#include "cmsis_os2.h"
#include "FreeRTOS.h"  // StaticTask_t: the control block of a statically created thread
#include <cstdio>
#include <vector>

using namespace csp;

// --- Configuration ---
#define NUM_RELAYS 5
#define TEST_ITERATIONS 1000
#define CHECK_INTERVAL 100

// --- 1. Define the Sequential Processes ---

/**
 * @brief Simple Source process.
 * Outputs an incrementing integer.
 */
class CountingSender : public CSProcessStatic<256> {
private:
    Chanout<int> out;
public:
    CountingSender(Chanout<int> w) : out(w) {}
    const char* name() const override { return "CountingSender"; }

    void run() override {
        printf("[Sender] Starting stream...\r\n");
        for (int i = 1; i <= TEST_ITERATIONS; ++i) {
            out << i;
        }
        printf("[Sender] Stream complete.\r\n");
        // Done: returning from run() ends this process's thread.
    }
};

/**
 * @brief The Relay process.
 * Complies with SPN by being a purely sequential actor:
 * Inputs from one channel, outputs to another.
 */
class Relay : public CSProcessStatic<256> {
private:
    Chanin<int> in;
    Chanout<int> out;
    int id;
public:
    Relay(Chanin<int> r, Chanout<int> w, int relay_id) 
        : in(r), out(w), id(relay_id) {}
    const char* name() const override { return "Relay"; }

    void run() override {
        int data;
        while (true) {
            in >> data;
            out << data;
        }
    }
};

/**
 * @brief Sink process.
 * Verifies the data integrity across the network.
 */
class CheckerReceiver : public CSProcessStatic<256> {
private:
    Chanin<int> in;
public:
    CheckerReceiver(Chanin<int> r) : in(r) {}
    const char* name() const override { return "CheckerReceiver"; }

    void run() override {
        int received;
        bool success = true;
        for (int i = 1; i <= TEST_ITERATIONS; ++i) {
            in >> received;
            if (received != i) {
                printf("[Receiver] !! DATA ERROR: Expected %d, Got %d\r\n", i, received);
                success = false;
                break;
            }
            if (i % CHECK_INTERVAL == 0) {
                printf("[Receiver] Verified up to %d...\r\n", i);
            }
        }
        if (success) {
            printf("[Receiver] SUCCESS: All %d values verified through %d relays.\r\n", 
                   TEST_ITERATIONS, NUM_RELAYS);
        }
        // Done: returning from run() ends this process's thread.
    }
};

// --- 2. Network Construction ---

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
    SleepFor(500);  // 500 ms (1000 Hz tick)
    printf("\r\n--- Launching CSP Relay Chain (SPN Principle) ---\r\n");

    /**
     * To connect N relays, we need N+1 channels:
     * Sender -> [C0] -> Relay1 -> [C1] -> Relay2 -> [C2] -> Receiver
     */
    static Channel<int> channels[NUM_RELAYS + 1];

    // Instantiate the Sender and Receiver at the chain ends
    static CountingSender sender(channels[0].writer());
    static CheckerReceiver receiver(channels[NUM_RELAYS].reader());

    // Instantiate the Relays to bridge the channels
    static Relay relays[NUM_RELAYS] = {
        Relay(channels[0].reader(), channels[1].writer(), 0),
        Relay(channels[1].reader(), channels[2].writer(), 1),
        Relay(channels[2].reader(), channels[3].writer(), 2),
        Relay(channels[3].reader(), channels[4].writer(), 3),
        Relay(channels[4].reader(), channels[5].writer(), 4)
    };

    /**
     * SPN Execution: 
     * We compose all processes in Parallel.
     * The rendezvous channels will handle the synchronization.
     */
    Run(
        InParallel(
            sender,
            relays[0],
            relays[1],
            relays[2],
            relays[3],
            relays[4],
            receiver
        ),
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
