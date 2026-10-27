/*
 * cvapp.h
 *
 *  Created on: 2018�~12��4��
 *      Author: 902452
 */

#ifndef APP_SCENARIO_ALLON_SENSOR_TFLM_CVAPP_
#define APP_SCENARIO_ALLON_SENSOR_TFLM_CVAPP_

#include "spi_protocol.h"
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

/* Returns 0, or a negative step code: -1 NPU, -2 model schema, -3 op resolver, -4 tensor
 * allocation. Does not print (the Reporter prints the result). */
int cv_init(bool security_enable, bool privilege_enable);

/* Classifies the current raw frame. Returns 0, or -1 if Invoke() failed. Does not print. */
int cv_run(int8_t* person_score, int8_t* no_person_score);

int cv_deinit();
#ifdef __cplusplus
}
#endif

#endif /* APP_SCENARIO_ALLON_SENSOR_TFLM_CVAPP_ */
