#include "csp/csp4cmsis.h"
#include "cmsis_os2.h"
#include "FreeRTOS.h"  // StaticTask_t: the control block of a statically created thread
#include <cstdio>

using namespace csp;

struct Message {
    uint32_t val;
};

// --- 1. Define Channels ---
// Two buffered channels, each with 10 slots, and a rendezvous on which the
// sender reports that both bursts are written.
#define SLOTS 10
using NewestChan = SamplingBufferedChannel<Message, SLOTS, BufferPolicy::KeepNewest>;
using OldestChan = SamplingBufferedChannel<Message, SLOTS, BufferPolicy::KeepOldest>;

#define TEST_COUNT 1000000

// --- 2. Define Processes ---

class PolicySender : public CSProcessStatic<256> {
private:
    Chanout<Message> outNew;
    Chanout<Message> outOld;
    Chanout<bool> done;
public:
    PolicySender(Chanout<Message> n, Chanout<Message> o, Chanout<bool> d)
        : outNew(n), outOld(o), done(d) {}
    const char* name() const override { return "PolicySender"; }

    void run() override {
        printf("[Sender] Bursting %d messages to KeepNewest...\r\n", TEST_COUNT);
        for (uint32_t i = 0; i < TEST_COUNT; ++i) {
            outNew << Message{i};
        }

        printf("[Sender] Bursting %d messages to KeepOldest...\r\n", TEST_COUNT);
        for (uint32_t i = 0; i < TEST_COUNT; ++i) {
            outOld << Message{i};
        }

        printf("[Sender] Finished sending.\r\n");
        done << true;  // both bursts are in the buffers: the receiver may drain
        // Done: returning from run() ends this process's thread.
    }
};

class PolicyReceiver : public CSProcessStatic<256> {
private:
    Chanin<Message> inNew;
    Chanin<Message> inOld;
    Chanin<bool> done;
public:
    PolicyReceiver(Chanin<Message> n, Chanin<Message> o, Chanin<bool> d)
        : inNew(n), inOld(o), done(d) {}
    const char* name() const override { return "PolicyReceiver"; }

    void run() override {
        // Wait until the sender has finished both (non-blocking) bursts, so
        // the result does not depend on timing.
        bool finished;
        done >> finished;

        uint64_t sumNewest = 0;
        uint64_t sumOldest = 0;
        Message msg;
        // Expected: KeepNewest holds the last SLOTS values, KeepOldest the first.
        bool exact = true;

        printf("[Receiver] Draining KeepNewest buffer...\r\n");
        // Both buffers are full: SLOTS messages each
        for (int i = 0; i < SLOTS; ++i) {
            inNew >> msg;
            sumNewest += msg.val;
            printf("  Newest[%d]: %lu\r\n", i, (unsigned long)msg.val);
            if (msg.val != (uint32_t)(TEST_COUNT - SLOTS + i)) exact = false;
        }

        printf("[Receiver] Draining KeepOldest buffer...\r\n");
        for (int i = 0; i < SLOTS; ++i) {
            inOld >> msg;
            sumOldest += msg.val;
            printf("  Oldest[%d]: %lu\r\n", i, (unsigned long)msg.val);
            if (msg.val != (uint32_t)i) exact = false;
        }

        printf("\r\n--- FINAL RESULTS ---\r\n");
        printf("KeepNewest Total Accumulation: %llu\r\n", sumNewest);
        printf("KeepOldest Total Accumulation: %llu\r\n", sumOldest);
        
        if (sumNewest > sumOldest) {
            printf("HYPOTHESIS CONFIRMED: KeepNewest kept the high-sequence values.\r\n");
        }
        printf("%s (expected KeepNewest %lu..%lu, KeepOldest 0..%d)\r\n",
               exact ? "PASS" : "FAIL",
               (unsigned long)(TEST_COUNT - SLOTS), (unsigned long)(TEST_COUNT - 1), SLOTS - 1);
        // Done: returning from run() ends this process's thread.
    }
};

// --- 3. Main Test Launcher ---

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
    printf("\r\n--- Launching Policy Comparison Test ---\r\n");

    static NewestChan chan_n;
    static OldestChan chan_o;
    static Channel<bool> chan_done;

    static PolicySender  snd(chan_n.writer(), chan_o.writer(), chan_done.writer());
    static PolicyReceiver rcv(chan_n.reader(), chan_o.reader(), chan_done.reader());

    Run(
        InParallel(snd, rcv),
        ExecutionMode::StaticNetwork,
        NETWORK_PRIORITY
    );

    // Run() returns immediately in StaticNetwork mode; the thread must
    // end itself rather than fall off the end of the function.
    osThreadExit();
}

extern "C" void RunProcessingChainTest(void) {
    osThreadAttr_t attr = {};
    attr.name       = "PolicyTest";
    attr.stack_mem  = mainAppStack;
    attr.stack_size = sizeof(mainAppStack);
    attr.cb_mem     = &mainAppControlBlock;
    attr.cb_size    = sizeof(mainAppControlBlock);
    attr.priority   = MAIN_APP_PRIORITY;
    if (osThreadNew(MainApp_Task, NULL, &attr) == NULL) {
        printf("ERROR: MainApp_Task creation failed!\r\n");
    }
}

