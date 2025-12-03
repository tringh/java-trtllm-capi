package io.github.tringh.jallama.trtllm;

import io.github.tringh.jallama.trtllm.internal.trtllm_capi_h;

import java.lang.foreign.MemorySegment;

public class LlmExecutor extends NativeObject implements AutoCloseable {

    public LlmExecutor(MemorySegment self) {
        super(self);
    }

    @Override
    public void close() {
        trtllm_capi_h.trt_destroy_executor(self);
    }

    public GenerationTask enqueue(LlmRequest request) {
        var requestId = trtllm_capi_h.trt_executor_enqueue(self, request.self);
        return new GenerationTask(self, requestId);
    }
}
