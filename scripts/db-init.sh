#!/usr/bin/env bash
set -euo pipefail
echo "[*] Running DB init on active node..."
docker exec -i postgres-ha psql -U "${DB_USER:-hauser}" -d "${DB_NAME:-locationdb}" < scripts/db-init.sql
echo "[*] Done."
