#!/bin/bash

set -e

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
PROJECT_ROOT=$(dirname "$SCRIPT_DIR")

LIB_DIR="$PROJECT_ROOT/core"
cd "$LIB_DIR"
cmake -B build -G Ninja
cmake --build build