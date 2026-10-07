#include "csp/csp4cmsis.h" 
#include "cmsis_os2.h"
#include "FreeRTOS.h"  // StaticTask_t: the control block of a statically created thread
#include <cstdio>

// --- Configuration ---
#define TOTAL_MESSAGES_PER_SENDER 10000 // Reduced for clarity in terminal output
#define CHECK_INTERVAL 1000           
#define MAX_TOTAL_MESSAGES (TOTAL_MESSAGES_PER_SENDER * 2)

using namespace csp;

// How often to print a stack-usage report for the whole network. This is a
// *live* reading (CSProcess::stackHighWaterMarkWords()), not a one-shot
// end-of-run report -- Sender/Receiver both idle in SleepFor(Forever)
// after finishing rather than exiting (an exited thread's handle can't be queried), so the report loop below keeps
// running for the life of the task. Read the HWM columns to right-size the
// provisional CSProcessStatic<N> values on Sender/Receiver below -- those
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

struct Message {
    int source_id; 
    int sequence_num;
};

// --- 1. Define Channels ---
// 'Channel' is a rendezvous (capacity 0) sync point.
using AltChannel = Channel<Message>;

// CSProcess is abstract: stackWords()/stackBuffer()/taskBuffer() are pure
// virtual, so each process needs its own static stack + StaticTask_t
// storage. CSProcessStatic<N> is the library helper that supplies that
// storage -- inherit from it instead of CSProcess directly, with N as the
// stack size in words. 512 is a provisional starting point for Sender
// (a tight loop with no deep call stack); confirm/right-size it against
// the HWM report added to MainApp_Task below.
class Sender : public CSProcessStatic<512> {
private:
    Chanout<Message> out;
    int id; 
public:
    Sender(Chanout<Message> w, int sender_id) : out(w), id(sender_id) {}
    const char* name() const override {
        static char buf[12];
        snprintf(buf, sizeof(buf), "Snd%d", id);
        return buf;
    }

    void run() override {
        printf("[Sender %d] Starting sequence.\r\n", id);
        for (int i = 0; i < TOTAL_MESSAGES_PER_SENDER; ++i) {
            Message msg = {id, i};
            out << msg; 
        }
        printf("[Sender %d] Finished.\r\n", id);
        while (true) {
            SleepFor(Forever);
        }
    }
};

// 1024 words is provisional: Receiver holds a 2-guard Alternative on the
// stack plus calls printf (newlib's printf can be stack-hungry). Confirm
// against the HWM report below.
class Receiver : public CSProcessStatic<1024> {
private:
    Chanin<Message> inA;
    Chanin<Message> inB;
public:
    Receiver(Chanin<Message> rA, Chanin<Message> rB) : inA(rA), inB(rB) {}
    const char* name() const override { return "Receiver"; }

    void run() override {
        SleepFor(Milliseconds(10));
        printf("[Receiver] Task running. Using Resident-Guard ALT.\r\n");

        Message msgA, msgB; 
        int count = 0;
        int next_seqA = 0;
        int next_seqB = 0;
        bool error_found = false;

        // The Alternative object is on the stack.
        // It borrows pointers to guards that live inside chan_A and chan_B.
        Alternative alt(inA | msgA, inB | msgB);

        while(count < MAX_TOTAL_MESSAGES) {
            // fairSelect is now heap-free.
            int selected = alt.fairSelect();
            
            if (selected == 0) {
                if (msgA.source_id != 1 || msgA.sequence_num != next_seqA) {
                    printf("!! DATA ERROR Chan A: Expected ID 1 Seq %d, Got ID %d Seq %d\r\n", 
                            next_seqA, msgA.source_id, msgA.sequence_num);
                    error_found = true;
                }
                next_seqA++;
            } 
            else if (selected == 1) {
                if (msgB.source_id != 2 || msgB.sequence_num != next_seqB) {
                    printf("!! DATA ERROR Chan B: Expected ID 2 Seq %d, Got ID %d Seq %d\r\n", 
                            next_seqB, msgB.source_id, msgB.sequence_num);
                    error_found = true;
                }
                next_seqB++;
            }

            count++;
            if (count % CHECK_INTERVAL == 0) {
                printf("[Receiver] Verified %d messages...\r\n", count);
                if (error_found) break;
            }
        }

        if (!error_found) {
            printf("[Receiver] SUCCESS: %d messages verified heap-free.\r\n", count);
        }
        while (true) {
            SleepFor(Forever);
        }
    }
};

// --- 3. The Main Application Task ---
void MainApp_Task(void* params) {
    (void)params;
    SleepFor(Milliseconds(500));

    printf("\r\n--- BOli2 Launching CSP Static Network (Zero-Heap) ---\r\n");
    
    // NEW: No constructor arguments needed for Rendezvous.
    // These are placed in static memory (.data segment).
    static AltChannel chan_A; 
    static AltChannel chan_B; 

    static Sender sA(chan_A.writer(), 1);
    static Sender sB(chan_B.writer(), 2);
    static Receiver r1(chan_A.reader(), chan_B.reader());

    // Run parallel processes using static execution
    auto network = InParallel(sA, sB, r1);
    Run(network, ExecutionMode::StaticNetwork, NETWORK_PRIORITY);

    printf("*** MainApp_Task: Run() returned, entering stack-report loop ***\r\n");

    // Sender/Receiver never return from run() (both drop into
    // SleepFor(Forever) once done), so there's no "network
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
