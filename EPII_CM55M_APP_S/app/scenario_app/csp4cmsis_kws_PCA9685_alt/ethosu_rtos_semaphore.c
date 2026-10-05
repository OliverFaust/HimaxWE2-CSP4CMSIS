// Ethos-U driver hook: overrides the driver's weak bare-metal semaphore
// functions so that Invoke() blocks the calling thread instead of spinning in
// __WFE(). Kept as native FreeRTOS on purpose: the driver calls these hooks
// directly (ethosu_semaphore_give from the NPU interrupt, whose priority is set
// to 5 in cvapp_kws.cpp). The binary semaphore is the only object in the
// FreeRTOS heap.
#include "FreeRTOS.h"
#include "semphr.h"

volatile uint32_t g_ethosu_sem_take_count = 0;
volatile uint32_t g_ethosu_sem_give_count = 0;

void *ethosu_semaphore_create(void) {
    return xSemaphoreCreateBinary();
}
void ethosu_semaphore_destroy(void *sem) {
    vSemaphoreDelete((SemaphoreHandle_t)sem);
}
int ethosu_semaphore_take(void *sem) {
    g_ethosu_sem_take_count++;
    return (xSemaphoreTake((SemaphoreHandle_t)sem, portMAX_DELAY) == pdTRUE) ? 0 : -1;
}
int ethosu_semaphore_give(void *sem) {
    g_ethosu_sem_give_count++;
    BaseType_t higherPriorityTaskWoken = pdFALSE;
    xSemaphoreGiveFromISR((SemaphoreHandle_t)sem, &higherPriorityTaskWoken);
    portYIELD_FROM_ISR(higherPriorityTaskWoken);
    return 0;
}
