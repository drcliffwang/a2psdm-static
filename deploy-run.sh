#!/bin/bash
set -euo pipefail

VM_USER="${VM_USER:-a2psdm}"
VM_IP="${VM_IP:-210.71.231.207}"

# VM 上 webroot 的實際路徑
VM_WEBROOT="${VM_WEBROOT:-/home/a2psdm/services/a2psdm-static/html/webroot}"

# 你 VM 上跑 Nginx 的 container 名稱（可不填，腳本會自動找）
NGINX_CONTAINER="${NGINX_CONTAINER:-}"

echo "==> 1) Sanity check (local webroot exists)"
test -d "./webroot" || { echo "ERROR: ./webroot not found. Run in the folder that contains webroot/"; exit 1; }

echo "==> 2) Ensure VM path exists"
ssh "${VM_USER}@${VM_IP}" "mkdir -p '${VM_WEBROOT}'"

echo "==> 3) Syncing webroot to VM (rsync)"
rsync -av --delete --compress --human-readable \
  --exclude ".DS_Store" \
  --exclude "Thumbs.db" \
  ./webroot/ \
  "${VM_USER}@${VM_IP}:${VM_WEBROOT}/"

echo "==> 4) Find nginx container on VM (if not specified)"
if [[ -z "${NGINX_CONTAINER}" ]]; then
  NGINX_CONTAINER="$(ssh "${VM_USER}@${VM_IP}" \
    "docker ps --format '{{.Names}} {{.Image}}' | egrep -i 'nginx' | head -n 1 | awk '{print \$1}'" || true)"
fi

if [[ -z "${NGINX_CONTAINER}" ]]; then
  echo "ERROR: No running nginx container found on VM. Deploy aborted."
  echo "       On VM run: docker ps"
  exit 1
fi

echo "==> 5) Reload nginx in container: ${NGINX_CONTAINER}"
ssh "${VM_USER}@${VM_IP}" "docker exec '${NGINX_CONTAINER}' nginx -t && docker exec '${NGINX_CONTAINER}' nginx -s reload"

echo "==> Deploy done ✅"
