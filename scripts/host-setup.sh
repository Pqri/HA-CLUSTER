#!/usr/bin/env bash
set -euo pipefail

echo "[*] Stop system pacemaker/corosync/pcsd on host (ignore errors)"
sudo systemctl stop pacemaker corosync pcsd 2>/dev/null || true
sudo systemctl disable pacemaker corosync pcsd 2>/dev/null || true
sudo pkill -9 -f 'corosync|pacemakerd|pcsd' 2>/dev/null || true

echo "[*] Create bind-mount directories"
sudo mkdir -p /etc/corosync /etc/pacemaker /var/lib/pacemaker /var/lib/pcsd
sudo mkdir -p /var/log/cluster /var/log/cluster/supervisor /var/log/cluster/pcsd
sudo mkdir -p /mnt
sudo mount --make-rshared /mnt 2>/dev/null || true

echo "[*] Done host setup."
