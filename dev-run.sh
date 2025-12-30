#!/bin/bash
set -e

NAME=a2psdm-dev
PORT=8088
ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "==> Starting A2PSDM dev server"
echo "    Project: $ROOT_DIR"
echo "    Port:    http://localhost:$PORT"

# Stop only dev container if exists
if docker ps -a --format '{{.Names}}' | grep -q "^${NAME}$"; then
  echo "==> Stopping existing dev container"
  docker rm -f $NAME
fi

# Run dev nginx
docker run -d \
  --name $NAME \
  -p $PORT:80 \
  -v "$ROOT_DIR/webroot:/usr/share/nginx/html:ro" \
  -v "$ROOT_DIR/nginx.conf:/etc/nginx/conf.d/default.conf:ro" \
  nginx:stable-alpine

echo ""
echo "==> Dev server is running:"
echo "    http://localhost:$PORT/"
echo "    http://localhost:$PORT/localcrm/"
echo ""
echo "==> To stop: docker rm -f $NAME"
