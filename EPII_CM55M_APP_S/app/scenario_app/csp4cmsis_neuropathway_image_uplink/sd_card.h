#ifndef SD_CARD_H
#define SD_CARD_H

#include <stdint.h>
#include "ff.h"

FRESULT sd_card_mount(FATFS* fs);
uint32_t sd_card_spi_hz(void);
const char* sd_card_result_name(int32_t res);

#endif
