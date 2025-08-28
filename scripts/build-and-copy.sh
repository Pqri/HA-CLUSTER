#!/usr/bin/env bash
set -euo pipefail

ACTION="${1:-all}"

copy_to="${SERVER_B_IP:-192.168.56.28}"
user="${REMOTE_USER:-$USER}"

if [[ "${ACTION}" == "all" || "${ACTION}" == "cluster" ]]; then
  echo "[*] Build ha-stack image locally"
  docker build -t fiqri/ha-stack:1.3 docker/ha-stack
  echo "[*] Copy ha-stack image to serverB"
  docker save fiqri/ha-stack:1.3 | ssh "${user}@${copy_to}" 'docker load'
fi

if [[ "${ACTION}" == "all" || "${ACTION}" == "flask" ]]; then
  echo "[*] Build flaskapp image locally"
  docker build -t flaskapp:latest services/flaskapp
  echo "[*] Copy flaskapp image to serverB"
  docker save flaskapp:latest | ssh "${user}@${copy_to}" 'docker load'
fi
