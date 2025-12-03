package io.github.tringh.jallama.trtllm;

import io.github.tringh.jallama.trtllm.internal.trtllm_capi_h;

import java.lang.foreign.MemorySegment;

public class GenerationTask {

    private final MemorySegment executor;

    private final long requestId;

    public GenerationTask(MemorySegment executor, long requestId) {
        this.executor = executor;
        this.requestId = requestId;
    }

    public void cancel() {
        trtllm_capi_h.trt_executor_cancel_request(executor, requestId);
    }

    public LlmResponseList fetchResponseList() {
        var ptr = trtllm_capi_h.trt_executor_await_responses(executor, requestId);
        return new LlmResponseList(ptr);
    }
}
