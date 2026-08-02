#!/usr/bin/env bash
# Mac wrapper: run remote_verify.sh on device.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SSH_PORT="${SSH_PORT:-2222}"
SSH_USER="${SSH_USER:-root}"
SSH_PASS="${SSH_PASS:-alpine}"
SSH_HOST="${SSH_HOST:-127.0.0.1}"
JBROOT="${JBROOT:-/mnt2/root/jb}"
STAGE="/mnt2/tmp/lumina-bootstrap"

sshpass -p "$SSH_PASS" ssh \
  -o StrictHostKeyChecking=no \
  -o UserKnownHostsFile=/dev/null \
  -o PreferredAuthentications=password \
  -o PubkeyAuthentication=no \
  -o ConnectTimeout=10 \
  -p "$SSH_PORT" \
  "${SSH_USER}@${SSH_HOST}" \
  "mkdir -p $STAGE && cat > $STAGE/remote_verify.sh && JBROOT=$JBROOT /bin/bash $STAGE/remote_verify.sh" \
  < "${ROOT}/scripts/bootstrap/remote_verify.sh"
