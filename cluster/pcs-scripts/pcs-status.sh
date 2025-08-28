#!/usr/bin/env bash
set -euo pipefail
echo "=== Nodes / Corosync ==="
pcs status nodes corosync || true
echo
echo "=== Quorum ==="
corosync-quorumtool -s || true
echo
echo "=== Resources ==="
pcs resource status || true
