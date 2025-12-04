package io.github.tringh.jallama.trtllm;

import io.github.tringh.jallama.tokenizer.Tokenizer;
import io.github.tringh.jallama.tokenizer.TokenizerService;
import org.junit.jupiter.api.*;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import static org.junit.jupiter.api.Assertions.*;

public class TextGenerationTest {

    private static final Logger logger = LoggerFactory.getLogger(TextGenerationTest.class);

    private static LlmService llmService;

    private static TokenizerService tokenizerService;

    private LlmExecutor engine;

    private Tokenizer tokenizer;

    @BeforeAll
    static void globalSetup() {
        LlmService.initialize();
        llmService = LlmService.getInstance();
        tokenizerService = TokenizerService.getInstance();
    }

    @AfterAll
    static void globalTeardown() throws Exception {
        llmService.close();
        tokenizerService.close();
    }

    @BeforeEach
    void setup() {
        engine = llmService.createExecutor("/data/engines/gpt2");
        tokenizer = tokenizerService.newTokenizer("/data/gguf/gpt2-vocab.gguf");
    }

    @AfterEach
    void teardown() {
        engine.close();
    }

    @Test
    void testPromptHelloWorld() {
        var inText = "Capital of Thailand is Bangkok. Capital of France is";
        var inTokens = tokenizer.tokenize(inText);

        var request = llmService.createRequest(inTokens, 20);
        request.setTemperature(0.95f);
        request.setTopK(1);
        request.setStreaming(false);

        var task = engine.enqueue(request);
        int[] outTokens;
        try (var responses = task.fetchResponseList()) {
            assertEquals(1, responses.getSize());
            assertFalse(responses.hasError(0));
            assertTrue(responses.isFinal(0));

            outTokens = responses.getTokens(0);
            assertEquals(20 + inTokens.length, outTokens.length);
        }

        var outText = tokenizer.detokenize(outTokens);
        logger.info("Inp: {}", inText);
        logger.info("Out: {}", outText);

        assertTrue(outText.contains("Paris"));
    }
}
