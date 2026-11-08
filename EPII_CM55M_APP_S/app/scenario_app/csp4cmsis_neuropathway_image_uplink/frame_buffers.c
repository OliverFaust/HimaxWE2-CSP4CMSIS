#include "frame_buffers.h"
#include "WE2_device.h"

__attribute__((section(".bss.NoInit"))) static uint8_t jpegbuf[CISDP_JPEG_BUF_CNT][FRAME_JPEG_STRIDE] __ALIGNED(32);
__attribute__((section(".bss.NoInit"))) static uint8_t rawbuf[FRAME_RAW_SIZE] __ALIGNED(32);

uint32_t frame_raw_addr(void)
{
    return (uint32_t)rawbuf;
}

uint32_t frame_raw_size(void)
{
    return FRAME_RAW_SIZE;
}

uint32_t frame_jpeg_addr(uint8_t id)
{
    return id < CISDP_JPEG_BUF_CNT ? (uint32_t)jpegbuf[id] : 0;
}

uint32_t frame_jpeg_size(void)
{
    return FRAME_JPEG_STRIDE;
}
