#IMAGE="hejingkai/kindnetd"
IMAGE="registry.cn-hangzhou.aliyuncs.com/jkhe/social-network-microservices"
TAG="latest"
docker buildx build \
  -t "${IMAGE}:${TAG}" \
  --platform=linux/arm64,linux/amd64 \
  -f Dockerfile \
  . \
  --push
