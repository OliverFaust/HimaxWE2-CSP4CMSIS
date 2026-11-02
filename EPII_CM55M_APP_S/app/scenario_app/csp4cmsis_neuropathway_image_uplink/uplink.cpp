#include "uplink.h"

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
