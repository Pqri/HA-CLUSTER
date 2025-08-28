#!/usr/bin/env bash
set -euo pipefail
echo "[*] Stopping cluster services in container on this node (simulate failure)"
docker exec -it ha-stack supervisorctl -c /etc/supervisor/supervisord.conf stop pacemaker || true
sleep 1
docker exec -it ha-stack supervisorctl -c /etc/supervisor/supervisord.conf stop corosync || true
echo "[*] Starting back..."
docker exec -it ha-stack supervisorctl -c /etc/supervisor/supervisord.conf start corosync
sleep 1
docker exec -it ha-stack supervisorctl -c /etc/supervisor/supervisord.conf start pacemaker
echo "[*] Done."
