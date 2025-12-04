#!/bin/bash
set -e

echo ">>> Starting GitHub Actions Runner Container..."
echo ">>> Java + TensorRT-LLM Environment"

# ==============================================================================
# 1. Permission Sync (Fixes file ownership issues on Linux hosts)
# ==============================================================================
# Determine workspace directory
if [ -n "$WORKSPACE_PATH" ]; then
    # Case A: User explicitly set the variable in docker-compose/run
    TARGET_DIR="$WORKSPACE_PATH"
else
    # Case B: Auto-detect the first directory inside /code
    TARGET_DIR=$(find /code -maxdepth 1 -mindepth 1 -type d -print -quit)
fi

# Fallback if nothing detected
TARGET_DIR="${TARGET_DIR:-/code}"

echo ">>> Detected Workspace: $TARGET_DIR"

if [ -d "$TARGET_DIR" ]; then
    HOST_UID=$(stat -c "%u" "$TARGET_DIR")
    HOST_GID=$(stat -c "%g" "$TARGET_DIR")
    CURRENT_UID=$(id -u developer)

    # Only sync if there is a mismatch AND we are not looking at root-owned folder
    if [ "$HOST_UID" != "0" ] && [ "$HOST_UID" != "$CURRENT_UID" ]; then
        echo ">>> Syncing 'developer' user UID to Host ($HOST_UID)..."
        sudo groupmod -o -g "$HOST_GID" developer
        sudo usermod -o -u "$HOST_UID" developer

        # Re-chown home directory to new UID
        sudo chown -R developer:developer /home/developer
    fi
else
    echo ">>> Note: Workspace directory not found or empty. Skipping permission sync."
fi

# ==============================================================================
# 2. Configuration Variables
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
# 3. Check if Runner is Already Configured
# ==============================================================================
cd /home/developer/actions-runner

if [ -f ".runner" ]; then
    echo ">>> Runner already configured, skipping registration..."
    echo ">>> If you need to reconfigure, delete the volume or run 'docker exec <container> ./config.sh remove --token <TOKEN>'"
else
    # ==============================================================================
    # 4. Runner Registration (Only on First Run)
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
# 5. Cleanup Handler
# ==============================================================================
cleanup() {
    echo ">>> Caught signal, shutting down runner gracefully..."
    # Note: We don't remove the runner config here so it persists across restarts
    # To fully remove: docker exec <container> ./config.sh remove --token <TOKEN>
}

trap 'cleanup; exit 130' INT
trap 'cleanup; exit 143' TERM

# ==============================================================================
# 6. Start Runner
# ==============================================================================
echo ">>> Starting GitHub Actions Runner..."
echo ">>> Runner is ready to accept jobs from: $GITHUB_URL"
echo ">>> Press Ctrl+C to stop (runner config will be preserved)"

# Run the runner (blocks until stopped)
./run.sh & wait $!