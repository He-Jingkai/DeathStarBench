#IMAGE="hejingkai/kindnetd"
IMAGE="registry.cn-hangzhou.aliyuncs.com/jkhe/thrift-microservice-deps"
TAG="xenial"
docker buildx build \
  -t "${IMAGE}:${TAG}" \
  --platform=linux/arm64,linux/amd64 \
  -f Dockerfile \
  . \
  --push
