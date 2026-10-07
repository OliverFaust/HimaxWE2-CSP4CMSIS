#include "csp/csp4cmsis.h"
#include <cstdio>
#include <cstdlib> // For abs()
#include "cmsis_os2.h"
#include "FreeRTOS.h"  // StaticTask_t: the control block of a statically created thread

// Bring in the Himax C drivers
extern "C" {
#include "hx_drv_scu.h"
#include "hx_drv_iic.h"
#include "xprintf.h"
}

using namespace csp;

// --- Data Structures ---
struct AccelData {
    int16_t x;
    int16_t y;
    int16_t z;
};

// --- Hardware Synchronization Setup ---
// The I2C completion interrupt signals the reader through a one-slot buffered
// channel: an interrupt cannot wait for a partner, so it writes via isrWriter(),
// and the slot keeps a completion that arrives before the reader waits for it
// (a rendezvous would lose it). The reader starts one transfer at a time, so at
// most one completion can be pending; a second one means a driver bug.
static BufferedChannel<bool, 1> i2c_isr_chan;

// Runs in the I2C interrupt (priority set in csp4cmsis_shake_detection.c).
extern "C" void i2c_callback(void) {
    if (!i2c_isr_chan.isrWriter().putFromISR(true)) {
        // A second completion before the first was read: stop here instead of
        // losing it. Polled UART output works with interrupts disabled.
        __disable_irq();
        xprintf("\r\nFATAL: I2C completion lost (the previous one was not read yet)\r\n");
        for (;;) { }
    }
}

// --- 1. ADXL345 Reader Process ---
class Adxl345Reader : public CSProcessStatic<256> {
    Chanin<bool> i2c_sync;     // Reads from the ISR
    Chanout<AccelData> out;    // Writes to the ShakeLogic
    const uint8_t slave_addr = 0x53;

    // Blocks the process until the hardware ISR fires
    void wait_for_i2c_isr() {
        bool dummy;
        i2c_sync >> dummy; // blocks this process until the interrupt has written
    }

    // Helper method to write to a single register
    void write_register(uint8_t reg, uint8_t val) {
        uint8_t data[2] = {reg, val};
        hx_drv_i2cm_interrupt_write(USE_DW_IIC_0, slave_addr, data, 2, (void *)i2c_callback);
        wait_for_i2c_isr();
    }

    // Helper method to read multiple contiguous bytes
    void read_registers(uint8_t reg, uint8_t* buffer, uint8_t len) {
        // Step 1: Write pointer
        hx_drv_i2cm_interrupt_write(USE_DW_IIC_0, slave_addr, &reg, 1, (void *)i2c_callback);
        wait_for_i2c_isr();

        // Step 2: Read sequence
        hx_drv_i2cm_interrupt_read(USE_DW_IIC_0, slave_addr, buffer, len, (void *)i2c_callback);
        wait_for_i2c_isr();
    }

public:
    // Constructor now takes the ISR synchronization channel as an input
    Adxl345Reader(Chanin<bool> sync_in, Chanout<AccelData> w) : i2c_sync(sync_in), out(w) {}
    const char* name() const override { return "Adxl345Reader"; }

    void run() override {
        printf("[Reader] Initializing ADXL345...\r\n");
        
        // 0x2D (POWER_CTL): Set Measure bit (bit 3) to 1 to wake up sensor
        write_register(0x2D, 0x08);
        
        // 0x31 (DATA_FORMAT): Set to Full Resolution, +/- 2g range
        write_register(0x31, 0x08);

        uint8_t raw_buffer[6];
        AccelData reading;

        while (true) {
            // Read 6 bytes starting at 0x32 (DATAX0). This fetches X, Y, and Z.
            read_registers(0x32, raw_buffer, 6);

            // Reconstruct the 16-bit values (Little Endian format)
            reading.x = (int16_t)((raw_buffer[1] << 8) | raw_buffer[0]);
            reading.y = (int16_t)((raw_buffer[3] << 8) | raw_buffer[2]);
            reading.z = (int16_t)((raw_buffer[5] << 8) | raw_buffer[4]);

            // Emit raw data down the channel
            out << reading;

            // Poll at ~20Hz
            SleepFor(Milliseconds(50));
        }
    }
};

// --- 2. Shake Math Logic Process ---
class ShakeLogic : public CSProcessStatic<256> {
    Chanin<AccelData> in;
    Chanout<bool> out;

public:
    ShakeLogic(Chanin<AccelData> r, Chanout<bool> w) : in(r), out(w) {}
    const char* name() const override { return "ShakeLogic"; }

    void run() override {
        AccelData current;
        AccelData previous = {0, 0, 0};
        bool is_first_reading = true;
        
        const int SHAKE_THRESHOLD = 300; 

        while (true) {
            in >> current;

            if (!is_first_reading) {
                int delta_x = abs(current.x - previous.x);
                int delta_y = abs(current.y - previous.y);
                int delta_z = abs(current.z - previous.z);
                
                int total_movement = delta_x + delta_y + delta_z;

                if (total_movement > SHAKE_THRESHOLD) {
                    out << true; 
                }
            } else {
                is_first_reading = false;
            }

            previous = current;
        }
    }
};

// --- 3. Shake Event Consumer Process ---
class ShakeEventConsumer : public CSProcessStatic<256> {
    Chanin<bool> in;

public:
    ShakeEventConsumer(Chanin<bool> r) : in(r) {}
    const char* name() const override { return "ShakeEventConsumer"; }

    void run() override {
        bool shake_flag;
        while (true) {
            in >> shake_flag;
            
            if (shake_flag) {
                printf("\r\n============================\r\n");
                printf(" !!! SHAKE DETECTED !!! \r\n");
                printf("============================\r\n");
            }
        }
    }
};

// --- 4. Main App Task ---
// Priorities keep the pre-2.0 order: MainApp (was tskIDLE_PRIORITY + 3) above the
// network (was + 2), so Run(..., StaticNetwork) creates all processes before any runs.
static constexpr osPriority_t MAIN_APP_PRIORITY = osPriorityLow3;
static constexpr osPriority_t NETWORK_PRIORITY  = osPriorityLow2;

// MainApp's stack and control block are static: creating the thread takes no heap.
// CMSIS-RTOS2 counts the stack in bytes. Provisional (was 4096 words); to be right-sized
// from measurements.
alignas(8) static uint8_t mainAppStack[4096];
static StaticTask_t mainAppControlBlock;

void MainApp_Task(void* params) {
    (void)params;
    SleepFor(Milliseconds(500));
    
    // Create the connecting channels
    static Channel<AccelData> c_accel_data;
    static Channel<bool> c_shake_events;

    // Instantiate the processes, wiring them together
    // Pass the global ISR channel's reader into the ADXL345 reader
    static Adxl345Reader      proc_reader(i2c_isr_chan.reader(), c_accel_data.writer());
    static ShakeLogic         proc_logic(c_accel_data.reader(), c_shake_events.writer());
    static ShakeEventConsumer proc_consumer(c_shake_events.reader());

    // Execute the network
    Run(
        InParallel(proc_reader, proc_logic, proc_consumer),
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
