#include "csp/alt.h"
#include "csp/csp_critical.h"
#include "csp/csp4cmsis_trace.h"
#include <cstdio>
// CMSIS compiler intrinsics -- typically pulled in via the device header,
// but included explicitly here since this file uses __CLZ directly: phase 4
// of AltScheduler::select() picks the winner with one __CLZ of ready_mask.
extern "C" {
    #include <cmsis_compiler.h>
}

namespace csp::internal {

// Trace: the Alternative whose internal_alt this scheduler is (every
// AltScheduler is one; Alternative is standard-layout).
#define TRACE_ALT (reinterpret_cast<const char*>(this) - offsetof(::csp::Alternative, internal_alt))

#if defined(CSP4CMSIS_TRACE)
// WaitAlt: the guards enabled in this round, bit i for guard-list index i
// (not fairness order).
static uint32_t traceEnabledMask(const size_t* order, size_t enabled) {
    uint32_t m = 0;
    for (size_t k = 0; k < enabled; ++k) m |= 1UL << order[k];
    return m;
}
#endif

// ready_mask in select() has one bit per enabled guard.
static_assert(ALT_MAX_GUARDS <= 32, "AltScheduler::select(): ready_mask holds at most 32 guards");

// =============================================================
// AltScheduler Implementation
// =============================================================

unsigned int AltScheduler::select(Guard** guardArray, size_t amount, size_t offset) {
    if (amount == 0) return 0;
    if (amount > ALT_MAX_GUARDS) fatal("CSP4CMSIS: Alternative: more than 16 guards");

    owner = osThreadGetId();
    start_tick_ = osKernelGetTickCount();     // timeout guards count from here

    uint32_t wait_mask = 0;
    for (size_t i = 0; i < amount; ++i) wait_mask |= altFlag(i);

    size_t order[ALT_MAX_GUARDS];

    for (;;) {
        // New round: drop wakeups left over from earlier rounds; the state
        // word says "enabling" (partners may claim this ALT from now on).
        (void)osThreadFlagsClear(wait_mask);
        { uint32_t s = csp_enter_critical(); state_ = ENABLING; claimed_flag_ = 0; csp_exit_critical(s); }
        wait_limit_ = NO_LIMIT;                   // set by the timeout guards enabled below

        // Phase 1: Enable, starting at 'offset' (fair ALT). Stops at the
        // first guard that is ready now (or that claimed its partner).
        size_t enabled = 0;
        bool any_ready = false;
        for (size_t i = 0; i < amount; ++i) {
            size_t idx = (i + offset) % amount;
            order[enabled++] = idx;
            if (guardArray[idx]->enable(this, altFlag(idx))) { any_ready = true; break; }
        }

        // Phase 2: Wait, unless something was ready or a partner claimed
        // this ALT while it was enabling. With timeout guards, wait at most
        // until the earliest deadline (fixed at the start of select(), so a
        // new round never postpones it); none left: no wait.
        if (!any_ready) {
            uint32_t timeout = osWaitForever;
            bool expired = false;
            if (wait_limit_ != NO_LIMIT) {
                uint32_t e = elapsed();
                if (e >= wait_limit_) expired = true; else timeout = wait_limit_ - e;
            }
            bool wait;
            { uint32_t s = csp_enter_critical(); wait = (state_ == ENABLING); if (wait) state_ = WAITING; csp_exit_critical(s); }
            if (wait && !expired) {
#if defined(CSP4CMSIS_TRACE)
                // A wait with a deadline: AltDeadline before it (tick the
                // remaining time was computed at, deadline tick), and the
                // tick at its Resume/ResumeTimeout.
                const bool trace_dl = (wait_limit_ != NO_LIMIT);
                const uint32_t trace_deadline = start_tick_ + wait_limit_;
                if (trace_dl)
                    CSP4CMSIS_TRACE_EVENT4(CSP4CMSIS_EVT_ALT_DEADLINE, CSP4CMSIS_TRACE_SELF(), TRACE_ALT,
                                           trace_deadline - timeout, trace_deadline);
#endif
                CSP4CMSIS_TRACE_EVENT4(CSP4CMSIS_EVT_WAIT_ALT, CSP4CMSIS_TRACE_SELF(), TRACE_ALT,
                                       traceEnabledMask(order, enabled), amount);
                uint32_t r = osThreadFlagsWait(wait_mask, osFlagsWaitAny, timeout);
#if defined(CSP4CMSIS_TRACE)
                if (trace_dl)
                    CSP4CMSIS_TRACE_EVENT4(r == (uint32_t)osFlagsErrorTimeout ? CSP4CMSIS_EVT_RESUME_TIMEOUT : CSP4CMSIS_EVT_RESUME,
                                           CSP4CMSIS_TRACE_SELF(), TRACE_ALT, osKernelGetTickCount(), trace_deadline);
                else
#endif
                CSP4CMSIS_TRACE_EVENT(r == (uint32_t)osFlagsErrorTimeout ? CSP4CMSIS_EVT_RESUME_TIMEOUT : CSP4CMSIS_EVT_RESUME,
                                      CSP4CMSIS_TRACE_SELF(), TRACE_ALT);
                if ((r & osFlagsError) != 0U && r != (uint32_t)osFlagsErrorTimeout) {
                    for (size_t k = 0; k < enabled; ++k) (void)guardArray[order[k]]->disable();
                    fatal("CSP4CMSIS: Alternative: osThreadFlagsWait() failed");
                }
                // No trust in the flag itself: every guard is re-verified below.
            }
        }

        // Phase 3: Disable exactly the guards enabled in this round; each
        // reports whether it can complete now (re-verification).
        //
        // Invariant: bit 31-k of ready_mask is set <=> order[k], the k-th
        // enabled guard in fairness order, was re-verified as ready by its
        // disable() in this round. __CLZ(ready_mask) is therefore the
        // smallest such k: the first ready guard in fairness order. CLZ
        // selects among re-verified guards only, never from the thread flags.
        uint32_t ready_mask = 0;
        for (size_t k = 0; k < enabled; ++k)
            if (guardArray[order[k]]->disable()) ready_mask |= 1UL << (31U - k);

        // Phase 4: A claim wins (the partner is committed to this guard);
        // otherwise the first ready guard in fairness order; else stale.
        bool claimed; uint32_t cflag;
        { uint32_t s = csp_enter_critical(); claimed = (state_ == CLAIMED); cflag = claimed_flag_; csp_exit_critical(s); }
        int selected = -1;
        if (claimed) {
            for (size_t k = 0; k < enabled; ++k)
                if (altFlag(order[k]) == cflag) { selected = (int)order[k]; break; }
            if (selected < 0) fatal("CSP4CMSIS: Alternative: claimed for a guard that was not enabled");
        } else if (ready_mask != 0U) {
            selected = (int)order[__CLZ(ready_mask)];
        }
        if (selected < 0) continue;                                   // stale wakeup: new round

        // Phase 5: Commit. false = the partner went away / a competitor
        // took the item or space (it made progress): new round.
        if (!guardArray[selected]->activate()) continue;
        { uint32_t s = csp_enter_critical(); state_ = IDLE; csp_exit_critical(s); }
        CSP4CMSIS_TRACE_EVENT4(CSP4CMSIS_EVT_ALT_SELECTED, owner, TRACE_ALT, selected, 0U);
        return (unsigned int)selected;
    }
}

void AltScheduler::wakeUp(uint32_t flag) {
    osThreadId_t t = owner;
    if (t != nullptr) (void)osThreadFlagsSet(t, flag);
}

} // namespace csp::internal

namespace csp {

// =============================================================
// Alternative Implementation
// =============================================================

#if defined(CSP4CMSIS_TRACE)
// AltGuard events: each guard's kind and object, once per guard (guards are
// only ever appended), before the select() that first uses it.
void Alternative::traceGuards() {
    for (; trace_described_ < num_guards; ++trace_described_) {
        uint32_t object = 0;
        uint32_t kind = internal_guards[trace_described_]->traceDescribe(object);
        CSP4CMSIS_TRACE_EVENT4(CSP4CMSIS_EVT_ALT_GUARD, CSP4CMSIS_TRACE_SELF(), this, object,
                               ((uint32_t)trace_described_ << 8) | kind);
    }
}
#endif

int Alternative::priSelect() {
#if defined(CSP4CMSIS_TRACE)
    traceGuards();
#endif
    retargetGuards();
    return (int)internal_alt.select(internal_guards, num_guards, 0);
}

int Alternative::fairSelect() {
    if (num_guards <= 1) return priSelect();
#if defined(CSP4CMSIS_TRACE)
    traceGuards();
#endif
    retargetGuards();

    size_t actual_index = internal_alt.select(internal_guards, num_guards, fair_select_start_index);

    // Update fairness index to ensure next guard has priority next time
    fair_select_start_index = (actual_index + 1) % num_guards;

    return (int)actual_index;
}

} // namespace csp
