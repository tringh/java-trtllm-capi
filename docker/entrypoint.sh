#!/bin/bash
set -e

# ==============================================================================
# 1. Determine Workspace Logic
# ==============================================================================
if [ -n "$WORKSPACE_PATH" ]; then
    # Case A: User explicitly set the variable in docker-compose/run
    TARGET_DIR="$WORKSPACE_PATH"
else
    # Case B: Auto-detect the first directory inside /code
    TARGET_DIR=$(find /code -maxdepth 1 -mindepth 1 -type d -print -quit)
fi

# Fallback if nothing detected
TARGET_DIR="${TARGET_DIR:-/code}"

echo ">>> Starting Java + TensorRT-LLM Dev Container..."
echo ">>> Detected Workspace: $TARGET_DIR"

# ==============================================================================
# 2. Permission Sync (Fixes file ownership issues on Linux hosts)
# ==============================================================================
if [ -d "$TARGET_DIR" ]; then
    HOST_UID=$(stat -c "%u" "$TARGET_DIR")
    HOST_GID=$(stat -c "%g" "$TARGET_DIR")
    CURRENT_UID=$(id -u developer)

    # Only sync if there is a mismatch AND we are not looking at root-owned folder
    if [ "$HOST_UID" != "0" ] && [ "$HOST_UID" != "$CURRENT_UID" ]; then
        echo ">>> Syncing 'developer' user UID to Host ($HOST_UID)..."
        groupmod -o -g "$HOST_GID" developer
        usermod -o -u "$HOST_UID" developer
        
        # Re-chown home directory to new UID
        chown -R developer:developer /home/developer
        
        # Ensure SSH permissions are still correct after ID change
        chmod 700 /home/developer/.ssh 2>/dev/null || true
        chmod 600 /home/developer/.ssh/* 2>/dev/null || true
    fi
else
    echo ">>> Note: Workspace directory not found or empty. Skipping permission sync."
fi

# ==============================================================================
# 3. Start SSH Server
# ==============================================================================
echo ">>> Starting SSH Daemon..."
# -D: Do not detach (run in foreground)
# -e: Write logs to stderr
exec /usr/sbin/sshd -D -e
