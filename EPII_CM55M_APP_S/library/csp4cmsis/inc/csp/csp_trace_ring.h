/*
 * SPDX-License-Identifier: MIT
 * Copyright (c) 2026 Oliver Faust
 *
 * csp_trace_ring.h: RAM ring-buffer trace backend (CSP4CMSIS_TRACE with
 * CSP4CMSIS_TRACE_BACKEND_RING; csp4cmsis_trace.h includes it instead of
 * EventRecorder.h). Plain C, so that RTOS configuration headers can include
 * it for the thread hooks.
 *
 * The ring is read by the debugger and converted with
 * tools/trace/ring2log.py to an Event Recorder log (tools/trace/README.md).
 *
 * It implements the part of Event Recorder's API that csp4cmsis_trace.h
 * uses (EventID(), EventRecord2(), EventRecord4(), EventRecordData()), so a
 * project links either Event Recorder or this backend, not both.
 *
 * Record: 16 bytes, { ts, id, seq, a, b }.
 *   ts   DWT->CYCCNT (core clock cycles, 32 bits, wraps)
 *   id   component << 8 | message, as the low 16 bits of Event Recorder's
 *        EventID() (Event Recorder does not record the level either)
 *   seq  write index of the record, modulo 2^16
 * Events with more than two values use consecutive records, written in one
 * critical section, as Event Recorder splits them:
 *   EventRecord2      1 record:  id, val1, val2
 *   EventRecord4      2 records: id, val1, val2 / 0x0001, val3, val4
 *   EventRecordData   1 + k records: id, bytes 0-7 / 0xFF01 + i, 8 bytes
 *                     each; zero-padded, the length is not recorded. At most
 *                     64 bytes: longer data are cut there and followed, in
 *                     the same critical section, by a CSP_TRACE_RTOS_TRUNCATED
 *                     record
 * Every record is written with BASEPRI raised to
 * CSP4CMSIS_MAX_SYSCALL_INTERRUPT_PRIORITY (only raised, then restored), and
 * the time stamp is taken in the same critical section as the slots, so ring
 * order is time stamp order.
 *
 * What the board provides (csp_trace_ring.c contains no MPU code and places
 * nothing in a section):
 * - The ring itself, in a NOLOAD section (the debugger's load must not write
 *   it) of RAM that the core does not cache (an MPU region with a
 *   non-cacheable attribute, or memory that is not cached), so that the
 *   debugger reads what the core wrote:
 *       struct csp_trace_ring csp_trace_ring
 *           __attribute__((section(".csp_trace"), aligned(32)));
 * - A call of csp_trace_ring_init() after that region is set up and before
 *   the first event (e.g. from a constructor that runs before every other
 *   one: __attribute__((constructor(101))) with GCC).
 * - A call of csp_trace_ring_tick(tick rate) from the RTOS tick hook: the
 *   heartbeat once per second (consecutive time stamps less than one CYCCNT
 *   wrap apart) and a record when SystemCoreClock changes.
 * - The thread hooks, for the decoder's thread view (component 0x51): with
 *   FreeRTOS, in FreeRTOSConfig.h,
 *       #define traceTASK_CREATE(t)     csp_trace_task_create((t), (t)->pcTaskName, (t)->uxPriority)
 *       #define traceTASK_SWITCHED_IN()  csp_trace_task_switched_in(pxCurrentTCB)
 *       #define traceTASK_SWITCHED_OUT() csp_trace_task_switched_out(pxCurrentTCB)
 * - Optionally CSP_TRACE_RECORDS (a power of two below 65536, default 16384:
 *   256 KB) and CSP_TRACE_POLICY, defined for every file that includes this
 *   header.
 */
#ifndef CSP_TRACE_RING_H
#define CSP_TRACE_RING_H

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

#define CSP_TRACE_MAGIC          0x52505343UL   /* "CSPR" */
#define CSP_TRACE_FORMAT         1U
#ifndef CSP_TRACE_RECORDS
#define CSP_TRACE_RECORDS        16384U         /* power of two: 256 KB */
#endif
#define CSP_TRACE_POLICY_OVERWRITE 0U           /* overwrite the oldest record */
#define CSP_TRACE_POLICY_STOP    1U             /* drop new records when full */
#ifndef CSP_TRACE_POLICY
#define CSP_TRACE_POLICY         CSP_TRACE_POLICY_OVERWRITE
#endif

#define CSP_TRACE_ID_VAL4_NEXT   0x0001U
#define CSP_TRACE_ID_DATA_NEXT   0xFF01U

/* Component 0x51: RTOS thread events (the board's hooks) and the backend's own. */
#define CSP_TRACE_RTOS_COMPONENT 0x51U
#define CSP_TRACE_RTOS_HEARTBEAT 0x00U          /* a SystemCoreClock, b heartbeat count */
#define CSP_TRACE_RTOS_CLOCK     0x01U          /* a SystemCoreClock (changed), b 0 */
#define CSP_TRACE_RTOS_CREATE    0x02U          /* a TCB, b priority */
#define CSP_TRACE_RTOS_NAME      0x03U          /* data: the name of the thread just created */
#define CSP_TRACE_RTOS_IN        0x04U          /* a TCB switched in, b 0 */
#define CSP_TRACE_RTOS_OUT       0x05U          /* a TCB switched out, b 0 */
#define CSP_TRACE_RTOS_TRUNCATED 0x06U          /* a id of the data event just written, b its length (bytes, > 64) */

typedef struct {
  uint32_t ts;
  union {
    struct {
      uint16_t id;
      uint16_t seq;
    };
    uint32_t id_seq;                            /* written first: marks the slot as the new record */
  };
  uint32_t a;
  uint32_t b;
} csp_trace_record_t;

typedef struct {
  uint32_t magic;
  uint16_t format;
  uint16_t record_size;
  uint32_t capacity;                            /* records */
  uint32_t policy;
  volatile uint32_t write_count;                /* records written since init (monotonic) */
  volatile uint32_t clock_hz;                   /* SystemCoreClock: DWT->CYCCNT frequency */
  volatile uint32_t dropped;                    /* records dropped (CSP_TRACE_POLICY_STOP) */
  uint32_t dwt_ctrl;                            /* DWT->CTRL after init (diagnostics) */
} csp_trace_header_t;

struct csp_trace_ring {
  csp_trace_header_t header;
  csp_trace_record_t records[CSP_TRACE_RECORDS];
};

extern struct csp_trace_ring csp_trace_ring;    /* defined by the board (above) */

/* The part of Event Recorder's API that csp4cmsis_trace.h uses. */
#define EventLevelError         0x00000U
#define EventLevelAPI           0x10000U
#define EventLevelOp            0x20000U
#define EventLevelDetail        0x30000U

#define EventID(level, comp_no, msg_no) ((level & 0x30000U) | ((comp_no & 0xFFU) << 8) | (msg_no & 0xFFU))

uint32_t EventRecord2(uint32_t id, uint32_t val1, uint32_t val2);
uint32_t EventRecord4(uint32_t id, uint32_t val1, uint32_t val2, uint32_t val3, uint32_t val4);
uint32_t EventRecordData(uint32_t id, const void *data, uint32_t len);

/* Board entry points (above). */
void csp_trace_ring_init(void);
void csp_trace_ring_tick(uint32_t tick_rate_hz);
void csp_trace_task_create(void *tcb, const char *name, uint32_t priority);
void csp_trace_task_switched_in(void *tcb);
void csp_trace_task_switched_out(void *tcb);

#ifdef __cplusplus
}
#endif

#endif /* CSP_TRACE_RING_H */
