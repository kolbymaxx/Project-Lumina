#!/usr/bin/env bash
# Mac wrapper: run remote_verify.sh on device.
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

# Stage the shared env.sh alongside remote_verify.sh so it can source the
# same JBROOT/STAGE source of truth on-device.
sshpass -p "$SSH_PASS" ssh "${ssh_opts[@]}" "${SSH_USER}@${SSH_HOST}" \
  "mkdir -p $STAGE && cat > $STAGE/env.sh" \
  < "${ROOT}/scripts/bootstrap/env.sh"

sshpass -p "$SSH_PASS" ssh "${ssh_opts[@]}" "${SSH_USER}@${SSH_HOST}" \
  "mkdir -p $STAGE && cat > $STAGE/remote_verify.sh && JBROOT=$JBROOT /bin/bash $STAGE/remote_verify.sh" \
  < "${ROOT}/scripts/bootstrap/remote_verify.sh"
