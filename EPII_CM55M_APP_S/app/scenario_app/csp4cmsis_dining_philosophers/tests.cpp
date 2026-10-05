#include "csp/csp4cmsis.h"
#include "cmsis_os2.h"
#include "FreeRTOS.h"  // StaticTask_t: the control block of a statically created thread
#include <cstdio>
#include <cstdlib> // Required for rand()

using namespace csp;

/**
 * @brief The Fork process acts as a shared resource.
 */
class Fork : public CSProcessStatic<256> {
    // Reordered: id first to match constructor initialization
    int id;
    Chanin<int> pick_up;
    Chanin<int> put_down;
public:
    Fork(int _id, Chanin<int> p, Chanin<int> d) 
        : id(_id), pick_up(p), put_down(d) {}
    const char* name() const override { return "Fork"; }

    void run() override {
        int phil_id;
        while (true) {
            pick_up >> phil_id; 
            put_down >> phil_id; 
        }
    }
};

/**
 * @brief The Philosopher process represents a thread of execution.
 */
class Philosopher : public CSProcessStatic<256> {
    // Reordered: id first to match constructor initialization
    int id;
    Chanout<int> left_p, left_d;
    Chanout<int> right_p, right_d;
public:
    Philosopher(int _id, Chanout<int> lp, Chanout<int> ld, Chanout<int> rp, Chanout<int> rd) 
        : id(_id), left_p(lp), left_d(ld), right_p(rp), right_d(rd) {}
    const char* name() const override { return "Philosopher"; }

    void run() override {
        // SEED UNIQUE TO THIS PHILOSOPHER
        // Use the ID and current time so each task starts with a different sequence
        std::srand(osKernelGetTickCount() + id);
        while (true) {
            // 1. RANDOM THINKING TIME
            // Generates a delay between 10ms and 110ms
            int thinking_time = 10 + (std::rand() % 100);
            printf("Phil %d: Thinking for %d ms...\r\n", id, thinking_time);
            SleepFor(thinking_time);  // ticks = ms at 1000 Hz
            
            printf("Phil %d: Hungry! Picking up LEFT fork...\r\n", id);
            left_p << id;
            SleepFor(50);
            printf("Phil %d: Picking up RIGHT fork...\r\n", id);
            right_p << id;

            printf("Phil %d: EATING!\r\n", id);
            SleepFor(50);

            printf("Phil %d: Putting down forks...\r\n", id);
            left_d << id;
            right_d << id;
        }
    }
};

/**
 * @brief Main Entry point for the Dining Philosophers Test.
 */
// Priorities keep the pre-2.0 order: MainApp (was tskIDLE_PRIORITY + 3) above the
// network (was + 2), so Run(..., StaticNetwork) creates all processes before any runs.
static constexpr osPriority_t MAIN_APP_PRIORITY = osPriorityLow3;
static constexpr osPriority_t NETWORK_PRIORITY  = osPriorityLow2;

// MainApp's stack and control block are static: creating the thread takes no heap.
// CMSIS-RTOS2 counts the stack in bytes. Provisional (was 8192 words): printf from
// full newlib needs a generous stack; to be right-sized from measurements.
alignas(8) static uint8_t mainAppStack[4096];
static StaticTask_t mainAppControlBlock;

void MainApp_Task(void* params) {    
    (void)params;
    SleepFor(500);  // 500 ms (1000 Hz tick)
    const int N = 5;
    
    static Channel<int> pick[N];
    static Channel<int> put[N];

    static Fork forks[N] = {
        Fork(0, pick[0].reader(), put[0].reader()),
        Fork(1, pick[1].reader(), put[1].reader()),
        Fork(2, pick[2].reader(), put[2].reader()),
        Fork(3, pick[3].reader(), put[3].reader()),
        Fork(4, pick[4].reader(), put[4].reader())
    };

    static Philosopher phils[N] = {
        Philosopher(0, pick[0].writer(), put[0].writer(), pick[1].writer(), put[1].writer()),
        Philosopher(1, pick[1].writer(), put[1].writer(), pick[2].writer(), put[2].writer()),
        Philosopher(2, pick[2].writer(), put[2].writer(), pick[3].writer(), put[3].writer()),
        Philosopher(3, pick[3].writer(), put[3].writer(), pick[4].writer(), put[4].writer()),
        Philosopher(4, pick[4].writer(), put[4].writer(), pick[0].writer(), put[0].writer())
    };

    printf("\n=== CSP4CMSIS Dining Philosophers Started ===\r\n");
    printf("Expected behavior: A few eat, then a total system deadlock.\r\n\n");

    Run(
        InParallel(
            forks[0], forks[1], forks[2], forks[3], forks[4],
            phils[0], phils[1], phils[2], phils[3], phils[4]
        ),
        ExecutionMode::StaticNetwork,
        NETWORK_PRIORITY
    );

    // Run() returns immediately in StaticNetwork mode; the thread must
    // end itself rather than fall off the end of the function.
    osThreadExit();
}

extern "C" void RunProcessingChainTest(void) {
    // Initial delay to allow serial terminal to connect
    printf("BOli\r\n");
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
