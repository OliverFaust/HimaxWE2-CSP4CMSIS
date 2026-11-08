#include "uplink.h"
#include "sensor_defaults.h"
#include "frame_buffers.h"

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

static_assert(UPLINK_WINDOW >= UPLINK_WINDOW_MIN && UPLINK_WINDOW <= UPLINK_WINDOW_MAX, "window out of range");
static_assert(UPLINK_BUFFERS == CISDP_JPEG_BUF_CNT, "UPLINK_BUFFERS must match CISDP_JPEG_BUF_CNT");
static_assert(UPLINK_K >= 1 && UPLINK_K <= UPLINK_WINDOW_MAX, "k out of range");

static const char* const SETTING_NAMES[SETTING_COUNT] = {"again", "dgain", "exposure", "framelen", "window",
                                                         "threshold", "k"};

const char* setting_name(uint8_t setting)
{
    return setting < SETTING_COUNT ? SETTING_NAMES[setting] : "?";
}

settings_t default_settings(void)
{
    settings_t s;
    s.value[SETTING_AGAIN] = SENSOR_AGAIN_SETTING;
    s.value[SETTING_DGAIN] = SENSOR_DGAIN_SETTING;
    s.value[SETTING_EXPOSURE] = SENSOR_EXPOSURE_SETTING;
    s.value[SETTING_FRAMELEN] = SENSOR_FRAMELEN_SETTING;
    s.value[SETTING_WINDOW] = UPLINK_WINDOW;
    s.value[SETTING_THRESHOLD] = (uint16_t)(int16_t)UPLINK_THRESHOLD;
    s.value[SETTING_K] = UPLINK_K;
    return s;
}

int32_t setting_value(uint8_t setting, const settings_t& s)
{
    return setting == SETTING_THRESHOLD ? (int32_t)(int16_t)s.value[setting] : (int32_t)s.value[setting];
}

int32_t setting_min(uint8_t setting, const settings_t& s)
{
    switch (setting) {
    case SETTING_AGAIN: return 0;
    case SETTING_DGAIN: return SENSOR_DGAIN_MIN;
    case SETTING_EXPOSURE: return SENSOR_EXPOSURE_MIN;
    case SETTING_FRAMELEN: {
        int32_t m = (int32_t)s.value[SETTING_EXPOSURE] + SENSOR_EXPOSURE_MARGIN;
        return m > SENSOR_FRAMELEN_MIN ? m : SENSOR_FRAMELEN_MIN;
    }
    case SETTING_WINDOW: return UPLINK_WINDOW_MIN;
    case SETTING_THRESHOLD: return -128;
    case SETTING_K: return 1;
    default: return 0;
    }
}

int32_t setting_max(uint8_t setting, const settings_t& s)
{
    switch (setting) {
    case SETTING_AGAIN: return SENSOR_AGAIN_MAX;
    case SETTING_DGAIN: return SENSOR_DGAIN_MAX;
    case SETTING_EXPOSURE: return (int32_t)s.value[SETTING_FRAMELEN] - SENSOR_EXPOSURE_MARGIN;
    case SETTING_FRAMELEN: return SENSOR_FRAMELEN_MAX;
    case SETTING_WINDOW: return UPLINK_WINDOW_MAX;
    case SETTING_THRESHOLD: return 127;
    case SETTING_K: return UPLINK_WINDOW_MAX;
    default: return 0;
    }
}
