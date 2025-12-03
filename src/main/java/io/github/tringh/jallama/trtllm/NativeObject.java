package io.github.tringh.jallama.trtllm;

import java.lang.foreign.MemorySegment;

public abstract class NativeObject {

    protected final MemorySegment self;

    protected NativeObject(MemorySegment self) {
        this.self = self;
    }

    public MemorySegment self() {
        return self;
    }
}
