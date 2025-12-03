#!/bin/bash

# Get project root
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
PROJECT_ROOT=$(dirname "$SCRIPT_DIR")

# output source dir
OUTPUT_DIR="${PROJECT_ROOT}/build/generated/jextract"

# package of generated classes
PACKAGE="io.github.tringh.jallama.trtllm.internal"

# llama.cpp library root
LIB="${PROJECT_ROOT}/core"

# exec jextract
jextract \
  --include-dir "${LIB}/include" \
  --output "${OUTPUT_DIR}" \
  --target-package "${PACKAGE}" \
  "${LIB}/include/trtllm_capi.h"