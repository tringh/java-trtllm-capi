#!/bin/bash
set -e

GITHUB_TOKEN="${GITHUB_TOKEN:-RUNNER_TOKEN}"

docker run -d \
  --gpus all \
  --ipc=host \
  --ulimit memlock=-1 \
  --ulimit stack=67108864 \
  -v $SSH_AUTH_SOCK:/ssh-agent \
  -e SSH_AUTH_SOCK=/ssh-agent \
  -e GITHUB_TOKEN="${GITHUB_TOKEN}" \
  -e GIT_AUTHOR_NAME="${GIT_AUTHOR_NAME}" \
  -e GIT_AUTHOR_EMAIL="${GIT_AUTHOR_EMAIL}" \
  -e GIT_COMMITTER_NAME="${GIT_COMMITTER_NAME}" \
  -e GIT_COMMITTER_EMAIL="${GIT_COMMITTER_EMAIL}" \
  -e RUNNER_NAME="java-trtllm-runner" \
  -v ../trtllm_data:/data \
  -v ~/.gradle:/home/developer/.gradle \
  -v ~/runner-data/java-trtllm-runner:/home/developer/actions-runner/_work \
  --name java-trtllm-runner \
  htring/java-trtllm-runner:0.0.1
