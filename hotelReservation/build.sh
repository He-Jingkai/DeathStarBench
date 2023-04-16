#IMAGE="hejingkai/kindnetd"
IMAGE="hejingkai/hotel-reservation"
TAG="latest"
docker buildx build \
  -t "${IMAGE}:${TAG}" \
  --platform=linux/arm64,linux/amd64 \
  -f Dockerfile \
  . \
  --push
