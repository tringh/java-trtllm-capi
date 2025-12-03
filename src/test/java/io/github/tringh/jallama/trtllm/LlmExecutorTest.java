package io.github.tringh.jallama.trtllm;

import org.junit.jupiter.api.*;

import static org.junit.jupiter.api.Assertions.*;

public class LlmExecutorTest {

    private static LlmService service;

    private LlmExecutor engine;

    @BeforeAll
    static void globalSetup() {
        LlmService.initialize();
        service = LlmService.getInstance();
    }

    @AfterAll
    static void globalTeardown() {
        service.close();
    }

    @BeforeEach
    void setup() {
        engine = service.createExecutor("/data/engines/gpt2");
    }

    @AfterEach
    void teardown() {
        engine.close();
    }

    @Test
    void testGenerationBatch() {
        final var maxNewToken = 20;
        final var inputTokens = new int[] {15496, 995, 13};
        var request = service.createRequest(inputTokens, maxNewToken);
        request.setTemperature(0.95f);
        request.setTopK(1);
        request.setStreaming(false);

        var task = engine.enqueue(request);

        try (var responseList = task.fetchResponseList()) {
            assertEquals(1, responseList.getSize());
            assertFalse(responseList.hasError(0));
            assertTrue(responseList.isFinal(0));
            var tokens = responseList.getTokens(0);
            assertEquals(maxNewToken + inputTokens.length, tokens.length);
        }
    }

    @Test
    void testGenerationStream() {
        final var maxNewToken = 20;
        var request = service.createRequest(new int[] {15496, 995, 13}, maxNewToken);
        request.setTemperature(0.95f);
        request.setTopK(1);
        request.setStreaming(true);

        var task = engine.enqueue(request);

        var isFinished = false;

        var responseListCount = 0;
        while (!isFinished) {
            try (var responseList = task.fetchResponseList()) {

                assertEquals(1, responseList.getSize());
                assertFalse(responseList.hasError(0));

                responseListCount++;

                if (responseList.isFinal(0)) {
                    assertEquals(maxNewToken, responseListCount);
                    isFinished = true;
                }
                var tokens = responseList.getTokens(0);
                assertEquals(1, tokens.length);
            }
        }
    }
}
