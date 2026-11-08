#include "sd_result.h"

static const char* const RESULT_NAMES[] = {
    "FR_OK", "FR_DISK_ERR", "FR_INT_ERR", "FR_NOT_READY", "FR_NO_FILE", "FR_NO_PATH", "FR_INVALID_NAME",
    "FR_DENIED", "FR_EXIST", "FR_INVALID_OBJECT", "FR_WRITE_PROTECTED", "FR_INVALID_DRIVE", "FR_NOT_ENABLED",
    "FR_NO_FILESYSTEM", "FR_MKFS_ABORTED", "FR_TIMEOUT", "FR_LOCKED", "FR_NOT_ENOUGH_CORE",
    "FR_TOO_MANY_OPEN_FILES", "FR_INVALID_PARAMETER",
};

const char* sd_card_result_name(int32_t res)
{
    return (res >= 0 && res < (int32_t)(sizeof(RESULT_NAMES) / sizeof(RESULT_NAMES[0]))) ? RESULT_NAMES[res] : "?";
}
