#ifndef UPLINK_H
#define UPLINK_H

#include <stdint.h>
#include "common_types.h"

static constexpr uint32_t UPLINK_WINDOW = 20;
static constexpr uint32_t UPLINK_WINDOW_MIN = 2;
static constexpr uint8_t UPLINK_BUFFERS = 4;
static constexpr uint32_t JPEG_SIZE_PAD = 32;

uint32_t crc32_update(uint32_t crc, const uint8_t* p, uint32_t n);
uint32_t jpeg_length(const uint8_t* p, uint32_t jpeg_sz, uint32_t buf_size);

const char* setting_name(uint8_t setting);
settings_t default_settings(void);
uint16_t setting_min(uint8_t setting, const settings_t& s);
uint16_t setting_max(uint8_t setting, const settings_t& s);

#endif
