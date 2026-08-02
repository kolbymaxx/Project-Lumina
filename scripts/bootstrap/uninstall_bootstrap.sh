#!/usr/bin/env bash
# Mac wrapper: remove $JBROOT (default /mnt2/root/jb) + staging only.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
# shellcheck source=env.sh
source "${ROOT}/scripts/bootstrap/env.sh"
SSH_PORT="${SSH_PORT:-2222}"
SSH_USER="${SSH_USER:-root}"
SSH_PASS="${SSH_PASS:-alpine}"
SSH_HOST="${SSH_HOST:-127.0.0.1}"

ssh_opts=(-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
  -o PreferredAuthentications=password -o PubkeyAuthentication=no \
  -o ConnectTimeout=10 -p "$SSH_PORT")
scp_opts=(-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
  -o PreferredAuthentications=password -o PubkeyAuthentication=no \
  -P "$SSH_PORT")

sshpass -p "$SSH_PASS" scp "${scp_opts[@]}" \
  "${ROOT}/scripts/bootstrap/env.sh" \
  "${ROOT}/scripts/bootstrap/remote_uninstall.sh" \
  "${SSH_USER}@${SSH_HOST}:${STAGE}/" 2>/dev/null || true

sshpass -p "$SSH_PASS" ssh "${ssh_opts[@]}" "${SSH_USER}@${SSH_HOST}" \
  "mkdir -p $STAGE; cat > $STAGE/env.sh" \
  < "${ROOT}/scripts/bootstrap/env.sh"

sshpass -p "$SSH_PASS" ssh "${ssh_opts[@]}" "${SSH_USER}@${SSH_HOST}" \
  "mkdir -p $STAGE; cat > $STAGE/remote_uninstall.sh" \
  < "${ROOT}/scripts/bootstrap/remote_uninstall.sh"

sshpass -p "$SSH_PASS" ssh "${ssh_opts[@]}" "${SSH_USER}@${SSH_HOST}" \
  "JBROOT=$JBROOT STAGE=$STAGE /bin/bash $STAGE/remote_uninstall.sh"
