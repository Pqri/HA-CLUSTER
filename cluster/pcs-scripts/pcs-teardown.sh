#!/usr/bin/env bash
set -euo pipefail
echo "[*] Enable maintenance mode"
pcs property set maintenance-mode=true || true

echo "[*] Delete resources & group (ignore errors)"
pcs resource ungroup app_group 2>/dev/null || true
pcs resource delete flask_docker --force 2>/dev/null || true
pcs resource delete vip --force 2>/dev/null || true
pcs resource delete pg_docker --force 2>/dev/null || true

echo "[*] Cleanup"
pcs resource cleanup || true

echo "[*] Disable maintenance mode"
pcs property set maintenance-mode=false || true

echo "[*] Done."
