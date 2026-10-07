#include "csp/csp4cmsis.h" 
#include "cmsis_os2.h"
#include "FreeRTOS.h"  // StaticTask_t: the control block of a statically created thread
#include <cstdio>
#include <vector>

#define NUM_SENDERS 16
#define TOTAL_MESSAGES_PER_SENDER 100000
#define MAX_TOTAL_MESSAGES (TOTAL_MESSAGES_PER_SENDER * NUM_SENDERS)
#define CHECK_INTERVAL 2000

using namespace csp;

// How often to print a stack-usage report for the whole network. This is a
// *live* reading (CSProcess::stackHighWaterMarkWords()), not a one-shot
// end-of-run report -- Sender/Receiver both idle in SleepFor(Forever)
// after finishing rather than exiting (an exited thread's handle can't be queried), so the report loop below keeps
// running for the life of the task. Read the HWM columns to right-size the
// provisional CSProcessStatic<N> values on Sender/Receiver above -- the
// numbers there were picked before this test ever ran, not measured.
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
        for (int i = 0; i < TOTAL_MESSAGES_PER_SENDER; ++i) {
            out << Message{id, i}; 
        }
        while (true) SleepFor(Forever);
    }
};

// --- Receiver Extended for 16 Channels ---
// 2048 words is provisional: Receiver holds an Alternative with 16 bindings
// plus a 16-entry Message buffer and calls printf (newlib's printf can be
// stack-hungry), so it gets more headroom than Sender by default. Confirm
// against the HWM report below.
class Receiver : public CSProcessStatic<2048> {
private:
    std::vector<Chanin<Message>> inputs;
public:
    Receiver(std::vector<Chanin<Message>> in_list) : inputs(in_list) {}
    const char* name() const override { return "Receiver"; }

    void run() override {
        printf("[Receiver] Stress Test: Monitoring %d Channels.\r\n", NUM_SENDERS);
        
        Message buffer[NUM_SENDERS];
        int next_seq[NUM_SENDERS] = {0};
        int total_count = 0;

        Alternative alt;
        for(int i = 0; i < NUM_SENDERS; ++i) {
            alt.addBinding(inputs[i] | buffer[i]);
        }

        while(total_count < MAX_TOTAL_MESSAGES) {
            int selected = alt.fairSelect(); 
            //int selected = alt.priSelect(); //<= Second test

            if (selected >= 0 && selected < NUM_SENDERS) {
                // 1. Validate data integrity
                if (buffer[selected].sequence_num != next_seq[selected]) {
                    printf("!! ERROR Snd %d: Expected %d, Got %d\r\n", 
                            selected + 1, next_seq[selected], buffer[selected].sequence_num);
                }
                next_seq[selected]++;
                total_count++;
            }

            // 2. Validate Fairness
		// Validate Fairness using relative percentage tolerance
		if (total_count % CHECK_INTERVAL == 0) {
		    int min_seq = next_seq[0];
		    int max_seq = next_seq[0];
		    
		    for(int i = 1; i < NUM_SENDERS; ++i) {
			if (next_seq[i] < min_seq) min_seq = next_seq[i];
			if (next_seq[i] > max_seq) max_seq = next_seq[i];
		    }
		    
		    int spread = max_seq - min_seq;
		    float avg_per_channel = (float)total_count / NUM_SENDERS;
		    float percent_drift = ((float)spread / avg_per_channel) * 100.0f;
		    
		    printf("[Receiver] Progress: %d / %d | Spread: %d (Min: %d, Max: %d) | Drift: %.1f%%\r\n", 
			    total_count, MAX_TOTAL_MESSAGES, spread, min_seq, max_seq, percent_drift);
		    
		    // Starvation threshold: trigger only if drift exceeds 15% of average channel progress
		    if (percent_drift > 15.0f) {
			printf("!! FAIRNESS VIOLATION: Channel imbalance exceeded 15%% (Drift: %.1f%%) !!\r\n", percent_drift);
		    }
		}
        }

        printf("[Receiver] SUCCESS: All %d messages verified with fair round-robin.\r\n", total_count);
        while (true) SleepFor(Forever);
    }
};

// --- Main Application Task ---
void MainApp_Task(void* params) {
    (void)params;
    SleepFor(Milliseconds(500));
    printf("--- Launching 16-Sender CSP Network ---\r\n");

    // 1. Static storage for channels
    static AltChannel channels[NUM_SENDERS];
    
    // 2. Static storage for Sender processes
    static Sender* senders[NUM_SENDERS];
    std::vector<Chanin<Message>> reader_list;

    for(int i = 0; i < NUM_SENDERS; ++i) {
        senders[i] = new Sender(channels[i].writer(), i + 1);
        reader_list.push_back(channels[i].reader());
    }

    // 3. Static storage for Receiver
    static Receiver r1(reader_list);

    // Note: To use InParallel with an array/vector, we would typically 
    // need a variadic expander. For this test, we can manually trigger 
    // the ParallelHelper or use a simpler loop to osThreadNew if 
    // InParallel doesn't support runtime arrays.
    
    // Using the helper for the Receiver (index 0) and spawning senders
    auto network = InParallel(r1, *senders[0], *senders[1], *senders[2], *senders[3],
                             *senders[4], *senders[5], *senders[6], *senders[7],
                             *senders[8], *senders[9], *senders[10], *senders[11],
                             *senders[12], *senders[13], *senders[14], *senders[15]);

    Run(network, ExecutionMode::StaticNetwork, NETWORK_PRIORITY);

    printf("*** MainApp_Task: Run() returned, entering stack-report loop ***\r\n");

    // Sender/Receiver never return from run() (both drop into
    // SleepFor(Forever) once done), so there's no "network
    // finished" point to report stack usage at -- report periodically
    // instead, same as the KWS pipeline's report loop.
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
