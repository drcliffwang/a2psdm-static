#!/bin/bash
set -euo pipefail

# ==============================================
# Deploy with Certbot SSL (Let's Encrypt)
# ==============================================

VM_USER="${VM_USER:-a2psdm}"
VM_IP="${VM_IP:-210.71.231.207}"
VM_BASE="${VM_BASE:-/home/a2psdm/services/a2psdm-static}"
CONTAINER_NAME="a2psdm-static"
DOMAINS="a2psdm.com,www.a2psdm.com"
EMAIL="${EMAIL:-admin@a2psdm.com}"

echo "==> 1) Sanity check (local files exist)"
test -d "./webroot" || { echo "ERROR: ./webroot not found."; exit 1; }
test -f "./nginx.certbot.conf" || { echo "ERROR: ./nginx.certbot.conf not found."; exit 1; }

echo "==> 2) Ensure VM directories exist"
ssh "${VM_USER}@${VM_IP}" "mkdir -p '${VM_BASE}/html/webroot' '${VM_BASE}/conf' '${VM_BASE}/certbot'"

echo "==> 3) Syncing webroot to VM"
rsync -av --delete --compress --human-readable \
  --exclude ".DS_Store" \
  --exclude "Thumbs.db" \
  ./webroot/ \
  "${VM_USER}@${VM_IP}:${VM_BASE}/html/webroot/"

echo "==> 4) Syncing nginx config to VM"
rsync -av --compress \
  ./nginx.certbot.conf \
  "${VM_USER}@${VM_IP}:${VM_BASE}/conf/default.conf"

echo "==> 5) Stopping old container (if exists)"
ssh "${VM_USER}@${VM_IP}" "docker rm -f '${CONTAINER_NAME}' 2>/dev/null || true"

echo "==> 6) Check if Certbot certificates exist"
CERTS_EXIST=$(ssh "${VM_USER}@${VM_IP}" "test -d /etc/letsencrypt/live/a2psdm.com && echo yes || echo no")

if [[ "$CERTS_EXIST" == "no" ]]; then
  echo "==> 7a) First time: Running Certbot to get certificates..."
  
  # Start temporary HTTP-only container for ACME challenge
  ssh "${VM_USER}@${VM_IP}" "docker run -d \\
    --name '${CONTAINER_NAME}-temp' \\
    -p 80:80 \\
    -v '${VM_BASE}/html/webroot:/usr/share/nginx/html:ro' \\
    nginx:stable-alpine"
  
  # Install certbot if not present
  ssh "${VM_USER}@${VM_IP}" "which certbot || sudo apt-get update && sudo apt-get install -y certbot"
  
  # Get certificate
  ssh "${VM_USER}@${VM_IP}" "sudo certbot certonly --webroot \\
    -w '${VM_BASE}/html/webroot' \\
    -d a2psdm.com -d www.a2psdm.com \\
    --email '${EMAIL}' \\
    --agree-tos --non-interactive"
  
  # Stop temporary container
  ssh "${VM_USER}@${VM_IP}" "docker rm -f '${CONTAINER_NAME}-temp'"
  
  echo "==> 7b) Setting up auto-renewal cron job..."
  ssh "${VM_USER}@${VM_IP}" "(crontab -l 2>/dev/null | grep -v certbot; echo '0 3 * * * certbot renew --quiet --post-hook \"docker exec ${CONTAINER_NAME} nginx -s reload\"') | crontab -"
else
  echo "==> 7) Certificates already exist, skipping Certbot..."
fi

echo "==> 8) Starting nginx container with Certbot SSL"
ssh "${VM_USER}@${VM_IP}" "docker run -d \\
  --name '${CONTAINER_NAME}' \\
  --restart unless-stopped \\
  -p 80:80 \\
  -p 443:443 \\
  -v '${VM_BASE}/html/webroot:/usr/share/nginx/html:ro' \\
  -v '${VM_BASE}/conf/default.conf:/etc/nginx/conf.d/default.conf:ro' \\
  -v '/etc/letsencrypt:/etc/letsencrypt:ro' \\
  nginx:stable-alpine"

echo "==> 9) Verify container is running"
ssh "${VM_USER}@${VM_IP}" "docker ps | grep '${CONTAINER_NAME}'"

echo ""
echo "==> Deploy done ✅"
echo "    HTTP:  http://a2psdm.com (redirects to HTTPS)"
echo "    HTTPS: https://a2psdm.com"
echo "    HTTPS: https://www.a2psdm.com"
echo ""
echo "    Auto-renewal: Cron job runs daily at 3 AM"
