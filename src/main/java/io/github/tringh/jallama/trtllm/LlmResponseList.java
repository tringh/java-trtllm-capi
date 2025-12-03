package io.github.tringh.jallama.trtllm;

import io.github.tringh.jallama.trtllm.internal.trtllm_capi_h;

import java.lang.foreign.MemorySegment;
import java.lang.foreign.ValueLayout;
import java.util.Arrays;

public class LlmResponseList extends NativeObject implements AutoCloseable {
    public LlmResponseList(MemorySegment self) {
        super(self);
    }

    public int getSize() {
        return trtllm_capi_h.trt_response_list_size(self);
    }

    public boolean hasError(int index) {
        return trtllm_capi_h.trt_response_has_error(self, index);
    }

    public String getError(int index) {
        return trtllm_capi_h.trt_response_get_error(self, index).getString(0);
    }

    public boolean isFinal(int index) {
        return trtllm_capi_h.trt_response_is_final(self, index);
    }

    public int[] getTokens(int index) {
        var tokenCount = trtllm_capi_h.trt_response_get_token_count(self, index);
        var tokenBuffer = LlmService.getInstance().getArena().allocate(ValueLayout.JAVA_INT, tokenCount);
        var result = trtllm_capi_h.trt_response_get_tokens(self, index, tokenBuffer, tokenCount);
        if (result < 0) {
            throw new RuntimeException("Failed to get tokens");
        }
        return tokenBuffer.toArray(ValueLayout.JAVA_INT);
    }

    @Override
    public void close() {
        trtllm_capi_h.trt_destroy_response_list(self);
    }
}
