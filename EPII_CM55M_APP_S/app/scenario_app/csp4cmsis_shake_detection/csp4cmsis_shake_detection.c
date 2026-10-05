#include "csp4cmsis_shake_detection.h"

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
#ifndef TRUSTZONE_SEC_ONLY
#include "secure_port_macros.h"
#endif
#endif

#include "xprintf.h"

// Core Driver Hardware Abstractions
#include "hx_drv_scu.h"
#include "hx_drv_iic.h"

extern void csp_app_main_init(void);

/*******************************************************************************
 * Code
 ******************************************************************************/
int app_main(void)
{
    osKernelInitialize();

    printf("Initializing System & CSP Network...\r\n");

    // 1. Configure Pinmux lines for I2C Master 0
    hx_drv_scu_set_PA2_pinmux(SCU_PA2_PINMUX_I2C_M_SCL, 1);
    hx_drv_scu_set_PA3_pinmux(SCU_PA3_PINMUX_I2C_M_SDA, 1);

    // An ISR that calls CSP4CMSIS or FreeRTOS must run at priority 5..7: at or
    // below CSP4CMSIS_MAX_SYSCALL_INTERRUPT_PRIORITY (5; 3 priority bits), so
    // that the RTOS's and the library's critical sections mask it. Neither the
    // SDK nor the driver sets a priority (the reset value 0 is the highest), so
    // set it here, before the driver is started. I2C master 0: the completion
    // callback writes to a CSP4CMSIS channel.
    NVIC_SetPriority(I2C_MST_0_intr_IRQn, CSP4CMSIS_MAX_SYSCALL_INTERRUPT_PRIORITY);

    // 2. Initialize Master interface
    int i2c_status = hx_drv_i2cm_init(USE_DW_IIC_0, HX_I2C_HOST_MST_0_BASE, DW_IIC_SPEED_FAST);
    if (i2c_status != 0)
    {
        printf("I2C Master Initialization Failed! Error: %d\r\n", i2c_status);
        while(1);
    }

    // 3. Launch the C++ CSP Processing Chain
    csp_app_main_init();

    osKernelStart();

    for (;;);
}
