// --- csp_wrapper.cpp ---

#include "csp/run.h" // ThreadFuncWrapper, csp::internal::TaskCtx
#include "csp/csp4cmsis_trace.h"

// Define the function using the definition that was removed from the header.
extern "C" {
    void ThreadFuncWrapper(void* pvParameters) {
        // Use the fully qualified name to ensure proper scope resolution
        csp::internal::TaskCtx* ctx = static_cast<csp::internal::TaskCtx*>(pvParameters);

        // 1. Run the process logic
        CSP4CMSIS_TRACE_EVENT(CSP4CMSIS_EVT_PROCESS_START, osThreadGetId(), ctx->process);
        CSP4CMSIS_TRACE_STRING(CSP4CMSIS_EVT_PROCESS_NAME, ctx->process->name());
        ctx->process->run();
        CSP4CMSIS_TRACE_EVENT(CSP4CMSIS_EVT_PROCESS_END, osThreadGetId(), ctx->process);

        // 2. Signal completion
        if (ctx->completion_sem) {
            osSemaphoreRelease(ctx->completion_sem);
        }

        // 3. API 1.3: ctx is caller-owned static storage (a ParallelHelper's
        // ctx_storage[] member, or public_task.h's function-static ctx) --
        // not heap-allocated. It must NOT be deleted here; the previous
        // `delete ctx` matched the old `new TaskCtx{...}` at the spawn
        // site, which no longer exists. Deleting it now would be
        // undefined behavior (freeing memory that was never allocated
        // by operator new).

        // 4. Terminate this RTOS2 task. osThreadExit() is CMSIS-RTOS2's
        // self-termination call for the calling thread -- unlike
        // FreeRTOS's vTaskDelete(NULL), it never returns, so there's
        // nothing after this call. Safe for a statically-created task:
        // it reclaims the RTOS's internal bookkeeping for the task, but
        // never touches the caller-supplied stack/TCB buffers -- those
        // remain owned by the CSProcessStatic<N> object, which is what
        // we want (it has static storage duration anyway).
        osThreadExit();
    }
}
