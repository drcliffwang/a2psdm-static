#!/bin/bash
set -e

IMAGE=a2psdm-site:local
NAME=a2psdm-site-local
PORT=8088

docker build -t $IMAGE .

# Stop any container using port 8088 (dev or prod)
docker rm -f a2psdm-dev >/dev/null 2>&1 || true
docker rm -f $NAME >/dev/null 2>&1 || true

docker run -d \
  --name $NAME \
  -p $PORT:80 \
  $IMAGE

echo "Prod container running:"
echo "  http://localhost:$PORT/"
