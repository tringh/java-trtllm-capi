#!/bin/bash
set -e

GITHUB_TOKEN="${GITHUB_TOKEN:-RUNNER_TOKEN_HERE}"

docker run -d \
  --gpus all \
  --ipc=host \
  --ulimit memlock=-1 \
  --ulimit stack=67108864 \
  -v $SSH_AUTH_SOCK:/ssh-agent \
  -e SSH_AUTH_SOCK=/ssh-agent \
  -e GITHUB_TOKEN="${GITHUB_TOKEN}" \
  -e RUNNER_NAME="java-trtllm-runner" \
  -v ~/.gitconfig:/home/developer/.gitconfig \
  -v .:/code/java-trtllm-capi \
  -v ../trtllm_data:/data \
  -v ~/.gradle:/home/developer/.gradle \
  -v runner-data:/home/developer/actions-runner \
  --name java-trtllm-runner \
  htring/java-trtllm-runner:0.0.1
