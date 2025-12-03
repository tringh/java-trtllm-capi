package io.github.tringh.jallama.trtllm;

import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertNotNull;

public class LlmServiceTest {

    private static final String LIB_PATH = "/code/java-trtllm-capi/core/build/libtrtllm_capi.so";

    private LlmService service;

    @BeforeAll
    static void globalSetup() {
        LlmService.initialize(LIB_PATH);
    }

    @BeforeEach
    void setup() {
        service = LlmService.getInstance();
    }

    @AfterEach
    void teardown() {
        service.close();
    }

    @Test
    void testCreateExecutor() {
        assertNotNull(service.createExecutor("/data/engines/gpt2"));
    }
}
