#include "csp4cmsis_alt_test.h"

#define FREERTOS

#ifdef FREERTOS
/* FreeRTOS kernel includes. */
#include "FreeRTOS.h"
#include "task.h"
#include "cmsis_os2.h"
#include "queue.h"
#include "timers.h"
#endif

#ifdef TRUSTZONE_SEC
#if (__ARM_FEATURE_CMSE & 1) == 0
#error "Need ARMv8-M security extensions"
#elif (__ARM_FEATURE_CMSE & 2) == 0
#error "Compile with --cmse"
#endif
#include "arm_cmse.h"
#ifdef NSC
#include "veneer_table.h"
#endif
/* Trustzone config. */

#ifndef TRUSTZONE_SEC_ONLY
/* FreeRTOS includes. */
#include "secure_port_macros.h"
#endif
#endif

/* Task priorities. */
#define hello_task1_PRIORITY	(configMAX_PRIORITIES - 1)
#define hello_task2_PRIORITY	(configMAX_PRIORITIES - 1)

#include "xprintf.h"

extern void csp_app_main_init(void);

/*******************************************************************************
 * Definitions
 ******************************************************************************/
//static void hello_task1(void *pvParameters);
//static void hello_task2(void *pvParameters);

/*******************************************************************************
 * Prototypes
 ******************************************************************************/

/*******************************************************************************
 * Code
 ******************************************************************************/
int app_main(void)
{
    osKernelInitialize();

    printf("Task creation C++ CSP wrapper test.\r\n");

    // CALL THE C++ INITIALIZATION FUNCTION
    csp_app_main_init();

    osKernelStart();

    // Should never return
    //for (;;);
}

