#!/bin/bash
set -euo pipefail

# ==============================================
# Deploy SSL-enabled site to CaaS/VM
# ==============================================

VM_USER="${VM_USER:-a2psdm}"
VM_IP="${VM_IP:-210.71.231.207}"
VM_BASE="${VM_BASE:-/home/a2psdm/services/a2psdm-static}"
CONTAINER_NAME="a2psdm-static"

echo "==> 1) Sanity check (local files exist)"
test -d "./webroot" || { echo "ERROR: ./webroot not found."; exit 1; }
test -d "./ssl" || { echo "ERROR: ./ssl not found."; exit 1; }
test -f "./nginx.prod.conf" || { echo "ERROR: ./nginx.prod.conf not found."; exit 1; }

echo "==> 2) Ensure VM directories exist"
ssh "${VM_USER}@${VM_IP}" "mkdir -p '${VM_BASE}/html/webroot' '${VM_BASE}/ssl' '${VM_BASE}/conf'"

echo "==> 3) Syncing webroot to VM"
rsync -av --delete --compress --human-readable \
  --exclude ".DS_Store" \
  --exclude "Thumbs.db" \
  ./webroot/ \
  "${VM_USER}@${VM_IP}:${VM_BASE}/html/webroot/"

echo "==> 4) Syncing SSL certificates to VM"
rsync -av --compress \
  ./ssl/fullchain.crt \
  ./ssl/private.key \
  "${VM_USER}@${VM_IP}:${VM_BASE}/ssl/"

echo "==> 5) Syncing nginx config to VM"
rsync -av --compress \
  ./nginx.prod.conf \
  "${VM_USER}@${VM_IP}:${VM_BASE}/conf/default.conf"

echo "==> 6) Stopping old container (if exists)"
ssh "${VM_USER}@${VM_IP}" "docker rm -f '${CONTAINER_NAME}' 2>/dev/null || true"

echo "==> 7) Starting new nginx container with SSL"
ssh "${VM_USER}@${VM_IP}" "docker run -d \\
  --name '${CONTAINER_NAME}' \\
  --restart unless-stopped \\
  -p 80:80 \\
  -p 443:443 \\
  -v '${VM_BASE}/html/webroot:/usr/share/nginx/html:ro' \\
  -v '${VM_BASE}/conf/default.conf:/etc/nginx/conf.d/default.conf:ro' \\
  -v '${VM_BASE}/ssl:/etc/nginx/ssl:ro' \\
  nginx:stable-alpine"

echo "==> 8) Verify container is running"
ssh "${VM_USER}@${VM_IP}" "docker ps | grep '${CONTAINER_NAME}'"

echo ""
echo "==> Deploy done ✅"
echo "    HTTP:  http://www.a2psdm.com (will redirect to HTTPS)"
echo "    HTTPS: https://www.a2psdm.com"
