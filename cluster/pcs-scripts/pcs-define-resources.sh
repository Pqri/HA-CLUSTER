#!/usr/bin/env bash
set -euo pipefail

# Load from env or defaults
VIP_ADDR="${VIP_ADDR:-192.168.56.30}"
VIP_CIDR="${VIP_CIDR:-24}"
VIP_NIC="${VIP_NIC:-enp0s8}"  # set to "" to auto-pick

DB_USER="${DB_USER:-hauser}"
DB_PASS="${DB_PASS:-hapassword}"
DB_NAME="${DB_NAME:-locationdb}"
DB_PORT="${DB_PORT:-5432}"

echo "[*] Enable maintenance mode"
pcs property set maintenance-mode=true

echo "[*] Create PostgreSQL docker resource"
pcs resource create pg_docker ocf:heartbeat:docker \
  name=postgres-ha image=postgres:16 \
  run_opts="--network=host --name=postgres-ha --restart=unless-stopped \
            -e POSTGRES_USER=${DB_USER} -e POSTGRES_PASSWORD=${DB_PASS} -e POSTGRES_DB=${DB_NAME} \
            -v /var/lib/pg-ha:/var/lib/postgresql/data" \
  reuse=true force_kill=true \
  op start timeout=120s op stop timeout=120s op monitor interval=20s timeout=60s

echo "[*] Create VIP resource"
if [[ -n "${VIP_NIC}" ]]; then
  pcs resource create vip ocf:heartbeat:IPaddr2 \
    ip="${VIP_ADDR}" cidr_netmask="${VIP_CIDR}" nic="${VIP_NIC}" \
    op monitor interval=10s timeout=20s
else
  pcs resource create vip ocf:heartbeat:IPaddr2 \
    ip="${VIP_ADDR}" cidr_netmask="${VIP_CIDR}" \
    op monitor interval=10s timeout=20s
fi

echo "[*] Create Flask docker resource"
pcs resource create flask_docker ocf:heartbeat:docker \
  name=flaskapp-ha image=flaskapp:latest \
  run_opts="--network=host --name=flaskapp-ha --restart=unless-stopped \
            -e SERVER_NAME=$(hostname) \
            -e DATABASE_URL=postgresql://${DB_USER}:${DB_PASS}@127.0.0.1:${DB_PORT}/${DB_NAME}" \
  reuse=true force_kill=true \
  op start timeout=90s op stop timeout=90s op monitor interval=20s timeout=60s

echo "[*] Group resources (VIP + Flask) and set constraints with PG"
pcs resource group add app_group vip 2>/dev/null || true
pcs resource group add app_group flask_docker 2>/dev/null || true

pcs constraint order start pg_docker then start app_group kind=Mandatory symmetrical=true
pcs constraint colocation add app_group with pg_docker INFINITY

echo "[*] Defaults and properties"
pcs resource defaults update resource-stickiness=200
pcs property set stonith-enabled=false
pcs property set no-quorum-policy=stop

echo "[*] Disable maintenance mode"
pcs property set maintenance-mode=false

echo "[*] Show resource status"
pcs resource status
