#!/bin/bash
set -e

# ==============================================================================
# Configuration Defaults
# ==============================================================================
# Default to a specific tag if not provided. 
# "v0.15.0" is a common stable tag for trt-llm, but you can use "latest" if preferred.
TRT_VER="1.0.0" 

# Java Tool Versions
IDEA_VER="2025.2.4"
GRADLE_VER="9.1.0"
MAVEN_VER="3.9.11"
JEXTRACT_VER="22-6"

# Image Tagging
IMAGE_NAME="htring/java-trtllm-dev"
IMAGE_VER="0.0.1"
TAG="${IMAGE_NAME}:${IMAGE_VER}"

# ==============================================================================
# Build Execution
# ==============================================================================
echo ">>> Building Docker Image: ${TAG}"
echo "    Base Image: nvcr.io/nvidia/tensorrt-llm/devel:${TRT_VER}"
echo "    IntelliJ IDEA: ${IDEA_VER}"
echo "    Gradle: ${GRADLE_VER} | Maven: ${MAVEN_VER} | JExtract: ${JEXTRACT_VER}"
echo "------------------------------------------------------------------------"

docker build \
  --build-arg TRT_LLM_VERSION="${TRT_VER}" \
  --build-arg IDEA_VERSION="${IDEA_VER}" \
  --build-arg GRADLE_VERSION="${GRADLE_VER}" \
  --build-arg MAVEN_VERSION="${MAVEN_VER}" \
  --build-arg JEXTRACT_VERSION="${JEXTRACT_VER}" \
  -t "${TAG}" \
  .

echo ">>> Build Complete. Run using: docker run --gpus all -it ${TAG}"
