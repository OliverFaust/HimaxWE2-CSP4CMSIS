#ifndef FRAME_BUFFERS_H
#define FRAME_BUFFERS_H

#include <stdint.h>

#ifndef CISDP_JPEG_BUF_CNT
#define CISDP_JPEG_BUF_CNT 2
#endif

#define FRAME_RAW_WIDTH   640
#define FRAME_RAW_HEIGHT  480
#define FRAME_RAW_SIZE    (FRAME_RAW_WIDTH * FRAME_RAW_HEIGHT * 3 / 2)
#define FRAME_JPEG_SIZE   (((623 + (FRAME_RAW_WIDTH / 16) * (FRAME_RAW_HEIGHT / 16) * 96 + 35) >> 2) << 2)
#define FRAME_JPEG_STRIDE ((FRAME_JPEG_SIZE + 31) & ~31)

#ifdef __cplusplus
extern "C" {
#endif

uint32_t frame_raw_addr(void);
uint32_t frame_raw_size(void);
uint32_t frame_jpeg_addr(uint8_t id);
uint32_t frame_jpeg_size(void);

#ifdef __cplusplus
}
#endif

#endif
