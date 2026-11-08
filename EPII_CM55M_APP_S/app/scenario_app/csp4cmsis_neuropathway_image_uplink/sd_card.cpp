#include "sd_card.h"
#include "hx_drv_scu.h"
#include "Driver_SPI.h"
#include "mmc_we2.h"

extern ARM_DRIVER_SPI Driver_SPI0;

static const char* const RESULT_NAMES[] = {
    "FR_OK", "FR_DISK_ERR", "FR_INT_ERR", "FR_NOT_READY", "FR_NO_FILE", "FR_NO_PATH", "FR_INVALID_NAME",
    "FR_DENIED", "FR_EXIST", "FR_INVALID_OBJECT", "FR_WRITE_PROTECTED", "FR_INVALID_DRIVE", "FR_NOT_ENABLED",
    "FR_NO_FILESYSTEM", "FR_MKFS_ABORTED", "FR_TIMEOUT", "FR_LOCKED", "FR_NOT_ENOUGH_CORE",
    "FR_TOO_MANY_OPEN_FILES", "FR_INVALID_PARAMETER",
};

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

const char* sd_card_result_name(int32_t res)
{
    return (res >= 0 && res < (int32_t)(sizeof(RESULT_NAMES) / sizeof(RESULT_NAMES[0]))) ? RESULT_NAMES[res] : "?";
}
