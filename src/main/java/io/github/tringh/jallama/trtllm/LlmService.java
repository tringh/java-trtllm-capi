package io.github.tringh.jallama.trtllm;

import io.github.tringh.jallama.trtllm.internal.trtllm_capi_h;

import java.io.File;
import java.io.IOException;
import java.lang.foreign.Arena;
import java.lang.foreign.ValueLayout;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.StandardCopyOption;

public class LlmService implements AutoCloseable {

    private static final String LIB_ENV_VAR = "LIB_TRTLLM_CAPI";

    private static final LlmService INSTANCE;

    static {
        INSTANCE = new LlmService(Arena.ofConfined());
    }

    public static void initialize(String libraryPath) {
        System.load(libraryPath);
    }

    public static void initialize() {
        String libPath = System.getenv(LIB_ENV_VAR);

        // Fail fast if the environment variable is not set
        if (libPath == null || libPath.isBlank()) {
            throw new RuntimeException("Native load failed: Environment variable '" + LIB_ENV_VAR + "' is not set.");
        }

        File libFile = new File(libPath);

        // Fail fast if the file path provided doesn't exist
        if (!libFile.exists()) {
            throw new RuntimeException("Native load failed: File specified by '"
                    + LIB_ENV_VAR + "' does not exist: " + libPath);
        }

        // Load the binary directly from the absolute path
        System.load(libFile.getAbsolutePath());
    }

    public static LlmService getInstance() {
        return INSTANCE;
    }

    private final Arena arena;

    private LlmService(Arena arena) {
        this.arena = arena;
        //loadLibraryFromClassPath(NATIVE_LIB, arena);
    }

    private static void loadLibraryFromPath(String path) {

    }

    private static void loadLibraryFromClassPath(String libNameWithoutExtension, Arena arena) {
        try {
            var libName = System.mapLibraryName(libNameWithoutExtension);
            Path libPath;
            try (var binaryIn = LlmService.class.getClassLoader().getResourceAsStream(libName)) {
                if (binaryIn == null) {
                    throw new IllegalArgumentException("Library not found in classpath: " + libName);
                }
                var tempFile = Files.createTempFile(
                        "_native_" + libName.replace("/", "."), null);
                Files.copy(binaryIn, tempFile, StandardCopyOption.REPLACE_EXISTING);
                tempFile.toFile().deleteOnExit();
                libPath = tempFile.toAbsolutePath();
            }
            System.load(libPath.toString());
        } catch (IOException e) {
            throw new RuntimeException(e);
        }
    }

    public void close() {
        arena.close();
    }

    public LlmExecutor createExecutor(String modelPath) {
        var executorPtr = trtllm_capi_h.trt_create_executor(arena.allocateFrom(modelPath),
                trtllm_capi_h.TRT_MODEL_TYPE_DECODER_ONLY(), 1);
        return new LlmExecutor(executorPtr);
    }

    public LlmRequest createRequest(int[] inputTokens, int maxNewTokens) {
        var ptr = trtllm_capi_h.trt_create_request(arena.allocateFrom(ValueLayout.JAVA_INT, inputTokens),
                inputTokens.length, maxNewTokens);
        return new LlmRequest(ptr);
    }

    public Arena getArena() {
        return arena;
    }
}



















