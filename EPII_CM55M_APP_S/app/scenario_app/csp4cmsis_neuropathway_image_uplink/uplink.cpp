#include "uplink.h"
#include "cisdp_cfg.h"

namespace {

struct CrcTable {
    uint32_t v[256];
    constexpr CrcTable() : v() {
        for (uint32_t n = 0; n < 256; n++) {
            uint32_t c = n;
            for (int k = 0; k < 8; k++) c = (c & 1) ? 0xEDB88320u ^ (c >> 1) : c >> 1;
            v[n] = c;
        }
    }
};

constexpr CrcTable crc_table;

}

uint32_t crc32_update(uint32_t crc, const uint8_t* p, uint32_t n)
{
    uint32_t c = crc ^ 0xFFFFFFFFu;
    for (uint32_t i = 0; i < n; i++) c = crc_table.v[(c ^ p[i]) & 0xFF] ^ (c >> 8);
    return c ^ 0xFFFFFFFFu;
}

uint32_t jpeg_length(const uint8_t* p, uint32_t jpeg_sz, uint32_t buf_size)
{
    if (jpeg_sz < JPEG_SIZE_PAD + 4 || jpeg_sz > buf_size) return 0;
    for (uint32_t end = jpeg_sz - JPEG_SIZE_PAD; end + 4 > jpeg_sz - JPEG_SIZE_PAD; end--) {
        if (p[end - 2] == 0xFF && p[end - 1] == 0xD9) return end;
    }
    return 0;
}

static constexpr uint16_t AGAIN_MAX = 232;
static constexpr uint16_t DGAIN_MIN = 0x0100;
static constexpr uint16_t DGAIN_MAX = 0x0FFF;
static constexpr uint16_t EXPOSURE_MIN = 1;
static constexpr uint16_t EXPOSURE_MARGIN = 4;
static constexpr uint16_t FRAMELEN_MIN = 2464 + 32;
static constexpr uint16_t FRAMELEN_MAX = 0xFFFE;

static const char* const SETTING_NAMES[SETTING_COUNT] = {"again", "dgain", "exposure", "framelen", "window"};

const char* setting_name(uint8_t setting)
{
    return setting < SETTING_COUNT ? SETTING_NAMES[setting] : "?";
}

settings_t default_settings(void)
{
    settings_t s;
    s.value[SETTING_AGAIN] = IMX219_AGAIN_SETTING;
    s.value[SETTING_DGAIN] = IMX219_DGAIN_SETTING;
    s.value[SETTING_EXPOSURE] = IMX219_EXPOSURE_SETTING;
    s.value[SETTING_FRAMELEN] = IMX219_FRAMELEN_SETTING;
    s.value[SETTING_WINDOW] = UPLINK_WINDOW;
    return s;
}

uint16_t setting_min(uint8_t setting, const settings_t& s)
{
    switch (setting) {
    case SETTING_AGAIN: return 0;
    case SETTING_DGAIN: return DGAIN_MIN;
    case SETTING_EXPOSURE: return EXPOSURE_MIN;
    case SETTING_FRAMELEN: {
        uint32_t m = (uint32_t)s.value[SETTING_EXPOSURE] + EXPOSURE_MARGIN;
        return (uint16_t)(m > FRAMELEN_MIN ? m : FRAMELEN_MIN);
    }
    case SETTING_WINDOW: return UPLINK_WINDOW_MIN;
    default: return 0;
    }
}

uint16_t setting_max(uint8_t setting, const settings_t& s)
{
    switch (setting) {
    case SETTING_AGAIN: return AGAIN_MAX;
    case SETTING_DGAIN: return DGAIN_MAX;
    case SETTING_EXPOSURE: return (uint16_t)(s.value[SETTING_FRAMELEN] - EXPOSURE_MARGIN);
    case SETTING_FRAMELEN: return FRAMELEN_MAX;
    case SETTING_WINDOW: return UPLINK_WINDOW;
    default: return 0;
    }
}
