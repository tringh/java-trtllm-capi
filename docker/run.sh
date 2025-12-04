docker run -d \
  --gpus all \
  --ipc=host \
  --ulimit memlock=-1 \
  --ulimit stack=67108864 \
  -p 2822:22 \
  -v $SSH_AUTH_SOCK:/ssh-agent \
  -e SSH_AUTH_SOCK:=/ssh-agent \
  -v ~/.gitconfig:/home/developer/.gitconfig \
  -v .:/code/java-trtllm-capi \
  -v ../trtllm_data:/data \
  -v ~/.gradle:/home/developer/.gradle \
  --name java-trtllm-capi-dev \
  htring/java-trtllm-dev:1.0.0
