// Ethos-U driver hooks (tflmtag2209_u55tag2205): CMSIS-RTOS2 semaphores in
// place of the driver's weak bare-metal ones, which busy-wait in __WFE() and
// malloc() each semaphore. With these, the thread that calls Invoke() blocks
// while the NPU runs, and the NPU interrupt (priority 5, cvapp.cpp) wakes it.
//
// The driver creates two semaphores, both in ethosu_init(): a global one
// ("a driver was released", taken only while every driver is reserved) and
// one per driver instance ("the job is done", given by ethosu_irq_handler(),
// taken by ethosu_wait()). Each is a binary signal: the bare-metal version
// sets its count to 1, not +1. So both are created with max 1, initial 0, and
// a give while the semaphore is already set is not an error. This app has one
// driver instance (ethosu_drv in cvapp.cpp), so the pool holds two control
// blocks, statically allocated: the RTOS heap is not used.
//
// The driver's ethosu_mutex_* hooks stay bare-metal (no-ops): only the
// Inference thread uses the NPU.

#include <stddef.h>
#include <stdint.h>

#include "FreeRTOS.h"
#include "cmsis_os2.h"
#include "csp/csp_fatal.h"
#include "ethosu_driver.h"

#define ETHOSU_DRIVER_INSTANCES 1
#define ETHOSU_SEMAPHORES       (1 + ETHOSU_DRIVER_INSTANCES)

static StaticSemaphore_t sem_cb[ETHOSU_SEMAPHORES];
static osSemaphoreId_t   sem_id[ETHOSU_SEMAPHORES];

void ethosu_semaphore_destroy(void *sem);

void *ethosu_semaphore_create(void)
{
    for (size_t i = 0; i < ETHOSU_SEMAPHORES; ++i) {
        if (sem_id[i] == NULL) {
            const osSemaphoreAttr_t attr = {
                .name    = "ethosu",
                .cb_mem  = &sem_cb[i],
                .cb_size = sizeof(sem_cb[i]),
            };
            sem_id[i] = osSemaphoreNew(1U, 0U, &attr);
            if (sem_id[i] == NULL) {
                csp4cmsis_fatal_error("ethosu_semaphore_create: osSemaphoreNew failed");
            }
            return sem_id[i];
        }
    }
    csp4cmsis_fatal_error("ethosu_semaphore_create: semaphore pool exhausted");
    return NULL;
}

void ethosu_semaphore_destroy(void *sem)
{
    for (size_t i = 0; i < ETHOSU_SEMAPHORES; ++i) {
        if (sem_id[i] != NULL && sem_id[i] == (osSemaphoreId_t)sem) {
            (void)osSemaphoreDelete(sem_id[i]);
            sem_id[i] = NULL;
            return;
        }
    }
}

int ethosu_semaphore_take(void *sem)
{
    return (osSemaphoreAcquire((osSemaphoreId_t)sem, osWaitForever) == osOK) ? 0 : -1;
}

int ethosu_semaphore_give(void *sem)
{
    osStatus_t status = osSemaphoreRelease((osSemaphoreId_t)sem);
    return (status == osOK || status == osErrorResource) ? 0 : -1;
}
