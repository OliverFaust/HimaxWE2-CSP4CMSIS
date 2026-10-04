#include "csp4cmsis_allon_sensor_tflm.h"
#include "csp4cmsis_spn.h"
#include "xprintf.h"
#include "WE2_debug.h"
#include "hx_drv_scu.h"
#include "hx_drv_swreg_aon.h"
#include "driver_interface.h"
#ifdef IP_sensorctrl
#include "hx_drv_sensorctrl.h"
#endif
#ifdef IP_xdma
#include "hx_drv_xdma.h"
#include "sensor_dp_lib.h"
#endif
#ifdef IP_cdm
#include "hx_drv_cdm.h"
#endif
#ifdef IP_edm
#include "hx_drv_edm.h"
#endif
#ifdef IP_gpio
#include "hx_drv_gpio.h"
#endif
#ifdef IP_swreg_aon
#include "hx_drv_swreg_aon.h"
#endif
#include "hx_drv_pmu.h"
#include "powermode.h"
#ifdef FREERTOS
/* FreeRTOS kernel includes. */
#include "FreeRTOS.h"
#include "task.h"
#include "cmsis_os2.h"
#include "queue.h"
#include "timers.h"
#endif
#include "hx_drv_CIS_common.h"
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

#include "common_config.h"
#include "app_msg.h"
#include "app_state.h"
#include "cvapp.h"
#include "sleep_mode.h"
#include "pinmux_cfg.h"

#define CIS_XSHUT_SGPIO0
#ifdef CIS_XSHUT_SGPIO0
#define DEAULT_XHSUTDOWN_PIN    AON_GPIO2
#else
#define DEAULT_XHSUTDOWN_PIN    AON_GPIO2
#endif
/*******************************************************************************
 * Definitions
 ******************************************************************************/
/* Task priorities. */
#define dp_task_PRIORITY	(configMAX_PRIORITIES - 1)
#define comm_task_PRIORITY	(configMAX_PRIORITIES - 1)
#define main_task_PRIORITY	(configMAX_PRIORITIES - 2)
#define algo_task_PRIORITY	(configMAX_PRIORITIES - 3)

#define DP_TASK_QUEUE_LEN   		10
#define COMM_TASK_QUEUE_LEN   		10
#define MAIN_TASK_QUEUE_LEN   		10
#define ALGO_TASK_QUEUE_LEN   		10
#define VAD_BUFF_SIZE  				2048

QueueHandle_t     xMainTaskQueue;
QueueHandle_t     xDPTaskQueue;
QueueHandle_t     xCommTaskQueue;
QueueHandle_t     xAlgoTaskQueue;

uint32_t g_algo_done_frame = 0;
uint32_t g_enter_pmu_frame_cnt = 0;

extern void app_start_state(APP_STATE_E state);

/*******************************************************************************
 * Prototypes
 ******************************************************************************/
void main_task(void *pvParameters);
void pinmux_init();

void vApplicationMallocFailedHook(void)
{
    /* pvPortMalloc() has just failed. Avoid calling printf() here --
     * depending on the C library and toolchain, printf() can itself
     * trigger a heap allocation (see Section 3.6.1), which is the last
     * thing you want to do inside a hook that exists because the heap
     * is already exhausted. Halt in a way that's easy to catch with a
     * debugger instead. */
    taskDISABLE_INTERRUPTS();
    for (;;) {
        ;
    }
}

/*******************************************************************************
 * Code
 ******************************************************************************/
void pinmux_init()
{
	SCU_PINMUX_CFG_T pinmux_cfg;

	hx_drv_scu_get_all_pinmux_cfg(&pinmux_cfg);

	/* Init UART0 pin mux to PB0 and PB1 */
	uart0_pinmux_cfg(&pinmux_cfg);

	/* Init AON_GPIO1 pin mux to PA1 for OV5647 enable pin */
	aon_gpio1_pinmux_cfg(&pinmux_cfg);

	/* Init I2C slave 0 pin mux to PA2, PA3 (SCL, SDA)*/
	i2cs0_pinmux_cfg(&pinmux_cfg);

	/* Init SPI master pin mux */
	spi_m_pinmux_cfg(&pinmux_cfg);

	/* Init Arm SWD interface pin mux to PB6, PB7, PB8 (nR, CLK, DIO)*/
	//swd_pinmux_cfg(&pinmux_cfg);

	hx_drv_scu_set_all_pinmux_cfg(&pinmux_cfg, 1);
}


/*!
 * @brief Main function
 */
int app_main(void)
{
	osKernelInitialize();

	pinmux_init();

	dbg_printf(DBG_LESS_INFO, "freertos rtos_app\r\n");
	
	RunProcessingChainTest();
        osKernelStart();

        for (;;)
            ;

        return 0;

}

