#!/usr/bin/env bash
set -euo pipefail

PCS_PASSWORD="${PCS_PASSWORD:-123}"
SERVER_A="${SERVER_A:-serverA}"
SERVER_B="${SERVER_B:-serverB}"
SERVER_A_IP="${SERVER_A_IP:-192.168.56.27}"
SERVER_B_IP="${SERVER_B_IP:-192.168.56.28}"

echo "[*] Ensuring pcsd directories & permissions..."
mkdir -p /var/lib/pcsd /var/log/pcsd
chown -R hacluster:haclient /var/lib/pcsd /var/log/pcsd || true
chmod -R 770 /var/lib/pcsd /var/log/pcsd || true

echo "[*] Set password for hacluster user"
echo "hacluster:${PCS_PASSWORD}" | chpasswd

echo "[*] Authenticate hosts by IP and name"
pcs host auth "${SERVER_A_IP}" "${SERVER_B_IP}" -u hacluster -p "${PCS_PASSWORD}"
pcs host auth "${SERVER_A}" "${SERVER_B}" -u hacluster -p "${PCS_PASSWORD}"

echo "[*] Setup and start cluster"
pcs cluster setup --name ha-cluster "${SERVER_A}" "${SERVER_B}"
pcs cluster start --all
pcs cluster enable --all

echo "[*] Basic properties (lab env)"
pcs property set stonith-enabled=false
pcs property set no-quorum-policy=stop

echo "[*] Done. Use 'pcs status' to verify."
