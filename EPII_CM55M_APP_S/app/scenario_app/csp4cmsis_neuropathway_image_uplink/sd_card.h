#ifndef SD_CARD_H
#define SD_CARD_H

#include <stdint.h>
#include "ff.h"

FRESULT sd_card_mount(FATFS* fs);
void sd_card_unmount(void);
uint32_t sd_card_spi_hz(void);

#endif
