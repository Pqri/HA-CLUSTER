#!/usr/bin/env bash
set -euo pipefail
node="${1:-serverA}"
echo "[*] Planned switchover: standby ${node}"
docker exec -it ha-stack pcs node standby "${node}"
sleep 6
docker exec -it ha-stack pcs resource status || true
