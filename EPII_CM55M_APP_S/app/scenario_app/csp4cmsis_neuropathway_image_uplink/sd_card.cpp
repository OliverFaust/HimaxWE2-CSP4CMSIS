#ifdef SD_CARD
#include "sd_card.h"
#include "hx_drv_scu.h"
#include "Driver_SPI.h"
#include "mmc_we2.h"

extern ARM_DRIVER_SPI Driver_SPI0;

FRESULT sd_card_mount(FATFS* fs)
{
    hx_drv_scu_set_PB2_pinmux(SCU_PB2_PINMUX_SPI_M_DO_1, 1);
    hx_drv_scu_set_PB3_pinmux(SCU_PB3_PINMUX_SPI_M_DI_1, 1);
    hx_drv_scu_set_PB4_pinmux(SCU_PB4_PINMUX_SPI_M_SCLK_1, 1);
    hx_drv_scu_set_PB5_pinmux(SCU_PB5_PINMUX_SPI_M_CS_1, 1);
    return f_mount(fs, "", 1);
}

void sd_card_unmount(void)
{
    f_mount(nullptr, "", 0);
    mmc_disk_deinit();
}

uint32_t sd_card_spi_hz(void)
{
    return (uint32_t)Driver_SPI0.Control(ARM_SPI_GET_BUS_SPEED, 0);
}
#endif
