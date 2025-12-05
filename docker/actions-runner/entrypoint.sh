#!/bin/bash
set -e

echo ">>> Starting GitHub Actions Runner Container..."
echo ">>> Java + TensorRT-LLM Environment"

# ==============================================================================
# 1. Configuration Variables
# ==============================================================================
GITHUB_URL="${GITHUB_URL:-https://github.com/tringh/java-trtllm-capi}"
RUNNER_NAME="${RUNNER_NAME:-$(hostname)}"
RUNNER_WORKDIR="/home/developer/actions-runner/_work"
RUNNER_LABELS="${RUNNER_LABELS:-self-hosted,Linux,X64,cuda,tensorrt,java}"

echo ">>> Configuration:"
echo "    Repository: $GITHUB_URL"
echo "    Runner Name: $RUNNER_NAME"
echo "    Work Directory: $RUNNER_WORKDIR"
echo "    Labels: $RUNNER_LABELS"

# ==============================================================================
# 2. Check if Runner is Already Configured
# ==============================================================================
cd /home/developer/actions-runner

if [ -f ".runner" ]; then
    echo ">>> Runner already configured, skipping registration..."
    echo ">>> If you need to reconfigure, delete the volume or run 'docker exec <container> ./config.sh remove --token <TOKEN>'"
else
    # ==============================================================================
    # 3. Runner Registration (Only on First Run)
    # ==============================================================================
    if [ -z "$GITHUB_TOKEN" ]; then
        echo "ERROR: GITHUB_TOKEN environment variable is required for initial setup"
        echo "Generate a token from: $GITHUB_URL/settings/actions/runners/new"
        echo ""
        echo "Run with: docker run -e GITHUB_TOKEN=<your_token> ..."
        exit 1
    fi

    echo ">>> Configuring GitHub Actions Runner (first time setup)..."
    ./config.sh \
        --url "$GITHUB_URL" \
        --token "$GITHUB_TOKEN" \
        --name "$RUNNER_NAME" \
        --work "$RUNNER_WORKDIR" \
        --labels "$RUNNER_LABELS" \
        --unattended \
        --replace

    echo ">>> Runner configured successfully!"
    echo ">>> Configuration will persist across container restarts"
fi

# ==============================================================================
# 4. Cleanup Handler
# ==============================================================================
cleanup() {
    echo ">>> Caught signal, shutting down runner gracefully..."
    # Note: We don't remove the runner config here so it persists across restarts
    # To fully remove: docker exec <container> ./config.sh remove --token <TOKEN>
}

trap 'cleanup; exit 130' INT
trap 'cleanup; exit 143' TERM

# ==============================================================================
# 5. Start Runner
# ==============================================================================
echo ">>> Starting GitHub Actions Runner..."
echo ">>> Runner is ready to accept jobs from: $GITHUB_URL"
echo ">>> Press Ctrl+C to stop (runner config will be preserved)"

# Run the runner (blocks until stopped)
./run.sh & wait $!