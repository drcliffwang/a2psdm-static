#!/bin/bash
set -e

NAME=a2psdm-dev
PORT=8088

# Stop any container using port 8088 (dev or prod)
docker rm -f a2psdm-site-local >/dev/null 2>&1 || true
docker rm -f $NAME >/dev/null 2>&1 || true

docker run -d \
  --name $NAME \
  -p $PORT:80 \
  -v "$(pwd)/webroot:/usr/share/nginx/html:ro" \
  -v "$(pwd)/nginx.conf:/etc/nginx/conf.d/default.conf:ro" \
  nginx:stable-alpine

echo "Dev server running:"
echo "  http://localhost:$PORT/"
echo "  http://localhost:$PORT/localcrm/"
