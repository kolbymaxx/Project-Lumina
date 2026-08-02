#!/usr/bin/env bash
# Mac wrapper: remove /mnt2/jb + staging only.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SSH_PORT="${SSH_PORT:-2222}"
SSH_USER="${SSH_USER:-root}"
SSH_PASS="${SSH_PASS:-alpine}"
SSH_HOST="${SSH_HOST:-127.0.0.1}"
JBROOT="${JBROOT:-/mnt2/root/jb}"
STAGE="/mnt2/tmp/lumina-bootstrap"

sshpass -p "$SSH_PASS" scp \
  -o StrictHostKeyChecking=no \
  -o UserKnownHostsFile=/dev/null \
  -o PreferredAuthentications=password \
  -o PubkeyAuthentication=no \
  -P "$SSH_PORT" \
  "${ROOT}/scripts/bootstrap/remote_uninstall.sh" \
  "${SSH_USER}@${SSH_HOST}:${STAGE}/remote_uninstall.sh" 2>/dev/null || true

sshpass -p "$SSH_PASS" ssh \
  -o StrictHostKeyChecking=no \
  -o UserKnownHostsFile=/dev/null \
  -o PreferredAuthentications=password \
  -o PubkeyAuthentication=no \
  -o ConnectTimeout=10 \
  -p "$SSH_PORT" \
  "${SSH_USER}@${SSH_HOST}" \
  "mkdir -p $STAGE; cat > $STAGE/remote_uninstall.sh" \
  < "${ROOT}/scripts/bootstrap/remote_uninstall.sh"

sshpass -p "$SSH_PASS" ssh \
  -o StrictHostKeyChecking=no \
  -o UserKnownHostsFile=/dev/null \
  -o PreferredAuthentications=password \
  -o PubkeyAuthentication=no \
  -o ConnectTimeout=10 \
  -p "$SSH_PORT" \
  "${SSH_USER}@${SSH_HOST}" \
  "JBROOT=$JBROOT STAGE=$STAGE /bin/bash $STAGE/remote_uninstall.sh"
