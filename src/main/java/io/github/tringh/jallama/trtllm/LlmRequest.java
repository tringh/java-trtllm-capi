package io.github.tringh.jallama.trtllm;

import io.github.tringh.jallama.trtllm.internal.trtllm_capi_h;

import java.lang.foreign.MemorySegment;

public class LlmRequest extends NativeObject implements AutoCloseable {

    public LlmRequest(MemorySegment self) {
        super(self);
    }

    public void setTemperature(float temperature) {
        trtllm_capi_h.trt_request_set_temperature(self, temperature);
    }

    public void setTopK(int k) {
        trtllm_capi_h.trt_request_set_top_k(self, k);
    }

    public void setTopP(float p) {
        trtllm_capi_h.trt_request_set_top_p(self, p);
    }

    public void setStreaming(boolean streaming) {
        trtllm_capi_h.trt_request_set_streaming(self, streaming);
    }

    public void setEndId(int endId) {
        trtllm_capi_h.trt_request_set_end_id(self, endId);
    }

    public void setClientId(long clientId) {
        trtllm_capi_h.trt_request_set_client_id(self, clientId);
    }

    @Override
    public void close() {
        trtllm_capi_h.trt_destroy_request(self);
    }
}
