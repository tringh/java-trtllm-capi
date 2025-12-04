#!/bin/bash
set -e

# ==============================================================================
# Configuration Defaults
# ==============================================================================
# TensorRT-LLM base image version
TRT_VER="1.0.0"

# Java Tool Versions
GRADLE_VER="9.1.0"
MAVEN_VER="3.9.11"
JEXTRACT_VER="22-6"

# GitHub Actions Runner Version
RUNNER_VER="2.329.0"

# Image Tagging
IMAGE_NAME="htring/java-trtllm-runner"
IMAGE_TAG="0.0.1"
TAG="${IMAGE_NAME}:${IMAGE_TAG}"

docker build \
  --build-arg TRT_LLM_VERSION="${TRT_VER}" \
  --build-arg GRADLE_VERSION="${GRADLE_VER}" \
  --build-arg MAVEN_VERSION="${MAVEN_VER}" \
  --build-arg JEXTRACT_VERSION="${JEXTRACT_VER}" \
  --build-arg RUNNER_VERSION="${RUNNER_VER}" \
  -f Dockerfile \
  -t "${TAG}" \
  .