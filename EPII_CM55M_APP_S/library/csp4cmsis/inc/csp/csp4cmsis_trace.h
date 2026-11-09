#ifndef CSP4CMSIS_TRACE_H
#define CSP4CMSIS_TRACE_H

// Event tracing (opt-in), to CMSIS-View Event Recorder or a RAM ring.
//
// Without CSP4CMSIS_TRACE (the default) every hook expands to nothing: its
// arguments are not evaluated, no backend header is included, and the
// generated code is that of a build without this header.
//
// Backend: Event Recorder (the default: EventRecorder.h), or with
// CSP4CMSIS_TRACE_BACKEND_RING the RAM ring of csp_trace_ring.h and
// src/csp_trace_ring.c, which implement the same calls (EventID(),
// EventRecord2/4/Data()); the board provides the ring's memory and hooks
// (csp_trace_ring.h). Define the backend switch, like CSP4CMSIS_TRACE, for
// the whole project.
//
// With CSP4CMSIS_TRACE (define it for the whole project: channel templates
// are compiled in application files) the library records the events below
// as component 0x50. The project provides CMSIS-View:Event Recorder,
// initialises it and enables the component, e.g. after EventRecorderInitialize()
// or the RTOS's own Event Recorder set-up:
//     EventRecorderEnable(EventRecordAll, 0x50U, 0x50U);
// trace/CSP4CMSIS.scvd decodes the events (eventlist, uVision, Keil Studio).
//
//   msg   event             level   values
//   0x00  ProcessStart      Op      a context (its thread), b process object
//   0x01  ProcessEnd        Op      a context (its thread), b process object
//   0x02  ProcessName       Op      (data record: the process's name(), after ProcessStart)
//   0x10  RendezvousDone    Op      a writer thread, b reader thread, c channel,
//                                   d 1 if the reader recorded it (arrived second), else 0
//   0x20  AltSelected       Op      a context (its thread), b Alternative, c guard-list
//                                   index, d 0
//   0x21  AltGuard          Op      a context, b Alternative, c object, d guard-list
//                                   index << 8 | kind: 0 input (c channel), 1 output
//                                   (c channel), 2 timeout (c delay in ticks), 3 other
//                                   guard (c 0). Once per guard, before the
//                                   Alternative's first select() (again after a guard
//                                   was added)
//   0x22  AltDeadline       Op      a context, b Alternative, c tick count the wait's
//                                   time was computed at, d deadline tick (c + the
//                                   timeout passed to the RTOS). Recorded just before
//                                   WaitAlt when the round has an enabled timeout guard
//   0x30  BufferedPut       Op      a context, b channel, c elements after << 16 |
//                                   policy << 14 | capacity (policy: 0 Block,
//                                   1 KeepNewest, 2 KeepOldest), d ring slot written
//   0x31  BufferedGet       Op      as BufferedPut, d ring slot read
//   0x32  PutFromISR        Op      as BufferedPut (a put in handler mode)
//   0x33  DroppedNew        Op      as BufferedPut (KeepOldest, full: put rejected),
//                                   d CSP4CMSIS_TRACE_NO_SLOT
//   0x34  OverwroteOldest   Op      as BufferedPut (KeepNewest, full: oldest replaced),
//                                   d slot evicted << 16 | slot written (the same slot:
//                                   the oldest element is replaced in place)
//   0x40  SpawnFailed       Error   a context, b process object
//   0x60  WaitChannel       Detail  a context, b channel | direction (bit 0: 1 write,
//                                   0 read; rendezvous: end busy, or partner)
//   0x61  WaitBufferedFull  Detail  a context, b channel (Block, put waits for space)
//   0x62  WaitBufferedEmpty Detail  a context, b channel (get waits for an element)
//   0x63  WaitAlt           Detail  a context, b Alternative (select() waits for a guard),
//                                   c enabled guards (bit i: guard-list index i),
//                                   d number of guards
//   0x64  WaitBarrier       Detail  a context, b barrier
//   0x65  WaitJoin          Detail  a context, b completion semaphore (TerminatingNetwork)
//   0x6E  Resume            Detail  a context, b the object of the wait (as recorded
//                                   by the wait, WaitChannel's direction bit included)
//   0x6F  ResumeTimeout     Detail  as Resume: the ALT wait ended by its timeout
//                                   After an AltDeadline (ALT wait with a deadline),
//                                   Resume and ResumeTimeout have four values:
//                                   c tick count after the wait, d deadline tick
//
// No event records any part of a channel's element values: only library state
// (threads, objects, counts, ring slots, guard sets, tick counts).
//
// Context (a): the thread id (osThreadId_t) in thread mode while the kernel
// runs; 0x80000000 | IPSR (the exception number) in handler mode; 0 in thread
// mode before the kernel runs.
//
// Wait events (0x6x) are recorded before a call that can block and Resume
// after it returns, whether or not it blocked; nothing else is recorded by the
// thread in between. Message numbers: one high nibble per group (0x0x
// processes, 0x1x rendezvous, 0x2x ALT, 0x3x buffered channels, 0x4x errors,
// 0x6x waits); in the wait group the low nibble is the kind, 0xE/0xF resume.
//
// Invariants: every put to a buffered channel produces exactly one record:
// BufferedPut (PutFromISR in handler mode), DroppedNew or OverwroteOldest
// (putFromISR() on a full Block channel returns false and is no put); every
// get one BufferedGet; every rendezvous communication exactly one
// RendezvousDone, recorded inside the critical section in which the
// communication is decided.

#define CSP4CMSIS_TRACE_COMPONENT        0x50U

#define CSP4CMSIS_EVT_PROCESS_START      0x00U
#define CSP4CMSIS_EVT_PROCESS_END        0x01U
#define CSP4CMSIS_EVT_PROCESS_NAME       0x02U
#define CSP4CMSIS_EVT_RENDEZVOUS_DONE    0x10U
#define CSP4CMSIS_EVT_ALT_SELECTED       0x20U
#define CSP4CMSIS_EVT_ALT_GUARD          0x21U
#define CSP4CMSIS_EVT_ALT_DEADLINE       0x22U
#define CSP4CMSIS_EVT_BUFFERED_PUT       0x30U
#define CSP4CMSIS_EVT_BUFFERED_GET       0x31U
#define CSP4CMSIS_EVT_PUT_FROM_ISR       0x32U
#define CSP4CMSIS_EVT_DROPPED_NEW        0x33U
#define CSP4CMSIS_EVT_OVERWROTE_OLDEST   0x34U
#define CSP4CMSIS_EVT_SPAWN_FAILED       0x40U
#define CSP4CMSIS_EVT_WAIT_CHANNEL       0x60U
#define CSP4CMSIS_EVT_WAIT_BUFFERED_FULL 0x61U
#define CSP4CMSIS_EVT_WAIT_BUFFERED_EMPTY 0x62U
#define CSP4CMSIS_EVT_WAIT_ALT           0x63U
#define CSP4CMSIS_EVT_WAIT_BARRIER       0x64U
#define CSP4CMSIS_EVT_WAIT_JOIN          0x65U
#define CSP4CMSIS_EVT_RESUME             0x6EU
#define CSP4CMSIS_EVT_RESUME_TIMEOUT     0x6FU

// Ticks are osKernelGetTickCount() values (modulo 2^32).
//
// Values of the events above.
#define CSP4CMSIS_TRACE_NO_SLOT          0xFFFFFFFFUL   // DroppedNew: no ring slot used
#define CSP4CMSIS_TRACE_DIR_WRITE        1U             // WaitChannel: bit 0 of the channel value
#define CSP4CMSIS_TRACE_GUARD_INPUT      0U             // AltGuard kinds
#define CSP4CMSIS_TRACE_GUARD_OUTPUT     1U
#define CSP4CMSIS_TRACE_GUARD_TIMEOUT    2U
#define CSP4CMSIS_TRACE_GUARD_OTHER      3U
#define CSP4CMSIS_TRACE_POLICY_SHIFT     14U            // buffered events: c = count << 16 | policy << 14 | capacity
#define CSP4CMSIS_TRACE_CAPACITY_MASK    0x3FFFU

#if defined(CSP4CMSIS_TRACE)
  #include <stdint.h>
  #include <string.h>
  #include "cmsis_os2.h"
  #include "csp_critical.h"       // device header: __get_IPSR()
  #if defined(CSP4CMSIS_TRACE_BACKEND_RING)
    #include "csp_trace_ring.h"
  #else
    #include "EventRecorder.h"
  #endif

  // EventID() does not parenthesise its arguments.
  #define CSP4CMSIS_TRACE_ID(msg) \
      EventID((((msg) == CSP4CMSIS_EVT_SPAWN_FAILED) ? EventLevelError : \
               ((((msg) & 0xF0U) == 0x60U) ? EventLevelDetail : EventLevelOp)), \
              (CSP4CMSIS_TRACE_COMPONENT), (msg))

  /// One event with two values (a, b: integers or pointers).
  #define CSP4CMSIS_TRACE_EVENT(msg, a, b) \
      ((void)EventRecord2(CSP4CMSIS_TRACE_ID(msg), (uint32_t)(uintptr_t)(a), (uint32_t)(uintptr_t)(b)))

  /// One event with four values.
  #define CSP4CMSIS_TRACE_EVENT4(msg, a, b, c, d) \
      ((void)EventRecord4(CSP4CMSIS_TRACE_ID(msg), (uint32_t)(uintptr_t)(a), (uint32_t)(uintptr_t)(b), \
                          (uint32_t)(uintptr_t)(c), (uint32_t)(uintptr_t)(d)))

  /// One event carrying a NUL-terminated string (without the NUL).
  #define CSP4CMSIS_TRACE_STRING(msg, s) \
      ((void)EventRecordData(CSP4CMSIS_TRACE_ID(msg), (s), (uint32_t)strlen(s)))

  namespace csp::internal {
      /// Context value a (see above). Safe with BASEPRI raised: RTX5 and the
      /// FreeRTOS adapters answer osKernelGetState()/osThreadGetId() directly
      /// when interrupts are masked.
      inline uint32_t traceContext() {
          uint32_t ipsr = __get_IPSR();
          if (ipsr != 0U) return 0x80000000UL | ipsr;
          osKernelState_t k = osKernelGetState();
          if (k != osKernelRunning && k != osKernelLocked) return 0U;
          return (uint32_t)(uintptr_t)osThreadGetId();
      }
  }
  #define CSP4CMSIS_TRACE_SELF() (::csp::internal::traceContext())
#else
  #define CSP4CMSIS_TRACE_EVENT(msg, a, b)   ((void)0)
  #define CSP4CMSIS_TRACE_EVENT4(msg, a, b, c, d) ((void)0)
  #define CSP4CMSIS_TRACE_STRING(msg, s)     ((void)0)
#endif

#endif // CSP4CMSIS_TRACE_H
