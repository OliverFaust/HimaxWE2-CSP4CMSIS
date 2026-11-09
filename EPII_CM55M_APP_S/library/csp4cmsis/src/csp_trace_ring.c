/*
 * SPDX-License-Identifier: MIT
 * Copyright (c) 2026 Oliver Faust
 *
 * csp_trace_ring.c: RAM ring-buffer trace backend (see csp_trace_ring.h).
 * Compiled to nothing unless CSP4CMSIS_TRACE and CSP4CMSIS_TRACE_BACKEND_RING
 * are defined. No MPU code and no section placement: the board defines the
 * ring and makes it non-cacheable (csp_trace_ring.h).
 */
#if defined(CSP4CMSIS_TRACE) && defined(CSP4CMSIS_TRACE_BACKEND_RING)

#include <string.h>
/* The device header, as csp_critical.h finds it (CMSIS-Core: DWT, BASEPRI,
 * SystemCoreClock). */
#if defined(__has_include)
  #if __has_include("RTE_Components.h")
    #include "RTE_Components.h"
  #endif
#endif
#if defined(CMSIS_device_header)
  #include CMSIS_device_header
#elif defined(CSP4CMSIS_DEVICE_HEADER)
  #include CSP4CMSIS_DEVICE_HEADER
#else
  #error "CSP4CMSIS: no device header (CMSIS_device_header or CSP4CMSIS_DEVICE_HEADER)"
#endif
#include "csp/csp_trace_ring.h"

#ifndef CSP4CMSIS_MAX_SYSCALL_INTERRUPT_PRIORITY
#error "Define CSP4CMSIS_MAX_SYSCALL_INTERRUPT_PRIORITY to match your RTOS's critical-section threshold"
#endif

#define CSP_TRACE_BASEPRI (CSP4CMSIS_MAX_SYSCALL_INTERRUPT_PRIORITY << (8U - __NVIC_PRIO_BITS))
#define CSP_TRACE_MAX_DATA_RECORDS 8U
#define CSP_TRACE_NAME_MAX 256U                 /* thread names: longer ones are cut (TRUNCATED) */

_Static_assert(sizeof(csp_trace_record_t) == 16, "record size");
_Static_assert(sizeof(csp_trace_header_t) == 32, "header size");
_Static_assert((CSP_TRACE_RECORDS & (CSP_TRACE_RECORDS - 1U)) == 0U, "capacity: power of two");
_Static_assert(CSP_TRACE_RECORDS < 65536U, "seq must tell the laps of a slot apart");

#define RTOS_ID(msg) EventID(EventLevelOp, CSP_TRACE_RTOS_COMPONENT, (msg))

static void dwt_init(void)
{
  DCB->DEMCR |= DCB_DEMCR_TRCENA_Msk;
  DWT->CYCCNT = 0U;
  DWT->CTRL |= DWT_CTRL_CYCCNTENA_Msk;
}

void csp_trace_ring_init(void)
{
  csp_trace_header_t *h = &csp_trace_ring.header;

  dwt_init();
  memset(&csp_trace_ring, 0, sizeof(csp_trace_ring));
  h->format = CSP_TRACE_FORMAT;
  h->record_size = sizeof(csp_trace_record_t);
  h->capacity = CSP_TRACE_RECORDS;
  h->policy = CSP_TRACE_POLICY;
  h->clock_hz = SystemCoreClock;
  h->dwt_ctrl = DWT->CTRL;
  __DMB();
  h->magic = CSP_TRACE_MAGIC;
}

static uint16_t next_id(uint32_t first, uint32_t k)
{
  return (uint16_t)(first == CSP_TRACE_ID_VAL4_NEXT ? CSP_TRACE_ID_VAL4_NEXT : CSP_TRACE_ID_DATA_NEXT + k - 1U);
}

/* n records: id, then next_id(cont, 1..n-1); values v[0..2n-1]. The time
 * stamp and the slots are taken in one critical section, so ring order is
 * time stamp order. Safe inside and outside CSP4CMSIS's critical sections
 * and in handler mode: BASEPRI is only raised, then restored. */
static uint32_t put(uint32_t id, uint32_t cont, uint32_t n, const uint32_t *v)
{
  csp_trace_header_t *h = &csp_trace_ring.header;
  uint32_t basepri = __get_BASEPRI();
  uint32_t ts, idx, k;

  __set_BASEPRI_MAX(CSP_TRACE_BASEPRI);
  __DSB();
  __ISB();
  ts = DWT->CYCCNT;
  idx = h->write_count;
  if (h->policy == CSP_TRACE_POLICY_STOP && idx + n > CSP_TRACE_RECORDS) {
    h->dropped += n;
    __set_BASEPRI(basepri);
    return 0U;
  }
  for (k = 0U; k < n; k++) {
    csp_trace_record_t *r = &csp_trace_ring.records[(idx + k) & (CSP_TRACE_RECORDS - 1U)];
    r->id_seq = (k == 0U ? (id & 0xFFFFU) : next_id(cont, k)) | ((idx + k) << 16);
    __DMB();
    r->ts = ts;
    r->a = v[2U * k];
    r->b = v[2U * k + 1U];
  }
  __DMB();
  h->write_count = idx + n;
  __set_BASEPRI(basepri);
  return 1U;
}

uint32_t EventRecord2(uint32_t id, uint32_t val1, uint32_t val2)
{
  const uint32_t v[2] = { val1, val2 };

  return put(id, 0U, 1U, v);
}

uint32_t EventRecord4(uint32_t id, uint32_t val1, uint32_t val2, uint32_t val3, uint32_t val4)
{
  const uint32_t v[4] = { val1, val2, val3, val4 };

  return put(id, CSP_TRACE_ID_VAL4_NEXT, 2U, v);
}

/* Data longer than CSP_TRACE_MAX_DATA_RECORDS records are cut there; a
 * TRUNCATED record (the event id and the full length) follows them in the
 * same critical section (put() only raises BASEPRI, so it nests). */
uint32_t EventRecordData(uint32_t id, const void *data, uint32_t len)
{
  uint32_t v[2U * CSP_TRACE_MAX_DATA_RECORDS] = { 0 };
  uint32_t n, basepri, ok;

  if (len <= sizeof(v)) {
    memcpy(v, data, len);
    n = len == 0U ? 1U : (len + 7U) / 8U;
    return put(id, CSP_TRACE_ID_DATA_NEXT, n, v);
  }
  memcpy(v, data, sizeof(v));
  basepri = __get_BASEPRI();
  __set_BASEPRI_MAX(CSP_TRACE_BASEPRI);
  ok = put(id, CSP_TRACE_ID_DATA_NEXT, CSP_TRACE_MAX_DATA_RECORDS, v);
  if (ok) {
    const uint32_t m[2] = { id & 0xFFFFU, len };

    put(RTOS_ID(CSP_TRACE_RTOS_TRUNCATED), 0U, 1U, m);
  }
  __set_BASEPRI(basepri);
  return ok;
}

void csp_trace_task_create(void *tcb, const char *name, uint32_t priority)
{
  EventRecord2(RTOS_ID(CSP_TRACE_RTOS_CREATE), (uint32_t)tcb, priority);
  EventRecordData(RTOS_ID(CSP_TRACE_RTOS_NAME), name, strnlen(name, CSP_TRACE_NAME_MAX));
}

void csp_trace_task_switched_in(void *tcb)
{
  EventRecord2(RTOS_ID(CSP_TRACE_RTOS_IN), (uint32_t)tcb, 0U);
}

void csp_trace_task_switched_out(void *tcb)
{
  EventRecord2(RTOS_ID(CSP_TRACE_RTOS_OUT), (uint32_t)tcb, 0U);
}

/* From the RTOS tick hook: the clock when it changes, and a heartbeat once
 * per second, so that consecutive time stamps are less than one CYCCNT wrap
 * (2^32 cycles: 5.4 s at 800 MHz) apart. */
void csp_trace_ring_tick(uint32_t tick_rate_hz)
{
  static uint32_t ticks, beats, clock;

  if (SystemCoreClock != clock) {
    clock = SystemCoreClock;
    csp_trace_ring.header.clock_hz = clock;
    EventRecord2(RTOS_ID(CSP_TRACE_RTOS_CLOCK), clock, 0U);
  }
  if (++ticks >= tick_rate_hz) {
    ticks = 0U;
    EventRecord2(RTOS_ID(CSP_TRACE_RTOS_HEARTBEAT), SystemCoreClock, ++beats);
  }
}

#endif /* CSP4CMSIS_TRACE && CSP4CMSIS_TRACE_BACKEND_RING */
