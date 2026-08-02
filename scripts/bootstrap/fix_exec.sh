#!/usr/bin/env bash
# Mac → device: map /var/jb → $JBROOT (session rpath shim), batch-ldid, test full-path dpkg.
# Keeps PATH=/usr/bin:/bin:/usr/sbin:/sbin on the device for the test.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
# shellcheck source=env.sh
source "${ROOT}/scripts/bootstrap/env.sh"
SSH_PORT="${SSH_PORT:-2222}"
SSH_USER="${SSH_USER:-root}"
SSH_PASS="${SSH_PASS:-alpine}"
SSH_HOST="${SSH_HOST:-127.0.0.1}"
LOGDIR="${ROOT}/logs"
mkdir -p "$LOGDIR"
STAMP="$(date +%Y%m%d-%H%M%S)"
LOG="${LOGDIR}/bootstrap-fix-exec-${STAMP}.log"

log() { echo "$@" | tee -a "$LOG"; }

need() { command -v "$1" >/dev/null || { log "FAIL: missing $1"; exit 1; }; }
need sshpass
need ssh
need scp

ssh_base=(sshpass -p "$SSH_PASS" ssh
  -o StrictHostKeyChecking=no
  -o UserKnownHostsFile=/dev/null
  -o PreferredAuthentications=password
  -o PubkeyAuthentication=no
  -o ServerAliveInterval=15
  -o ConnectTimeout=15
  -p "$SSH_PORT"
  "${SSH_USER}@${SSH_HOST}")

scp_base=(sshpass -p "$SSH_PASS" scp
  -o StrictHostKeyChecking=no
  -o UserKnownHostsFile=/dev/null
  -o PreferredAuthentications=password
  -o PubkeyAuthentication=no
  -P "$SSH_PORT")

log "log=$LOG"
log "target=${SSH_USER}@${SSH_HOST}:${SSH_PORT} JBROOT=$JBROOT"

# Ensure Data is mounted and staging writable (under /mnt2/tmp or /mnt2/root only)
"${ssh_base[@]}" "export PATH=/usr/bin:/bin:/usr/sbin:/sbin; command -v mount_ich >/dev/null && mount_ich >/dev/null; mkdir -p $STAGE $JBROOT; touch $STAGE/.w && rm $STAGE/.w" \
  || { log "FAIL: staging not writable — is iproxy up and mount_ich done?"; exit 1; }

log "### push env.sh + remote_fix_exec.sh + platform.plist + prep_bootstrap.lumina.sh"
"${scp_base[@]}" \
  "${ROOT}/scripts/bootstrap/env.sh" \
  "${ROOT}/scripts/bootstrap/remote_fix_exec.sh" \
  "${ROOT}/scripts/bootstrap/platform.plist" \
  "${ROOT}/scripts/bootstrap/prep_bootstrap.lumina.sh" \
  "${SSH_USER}@${SSH_HOST}:${STAGE}/"

log "### run fix (device PATH forced to system dirs only)"
set +e
"${ssh_base[@]}" \
  "export PATH=/usr/bin:/bin:/usr/sbin:/sbin; JBROOT=$JBROOT STAGE=$STAGE PLIST=$STAGE/platform.plist /bin/bash $STAGE/remote_fix_exec.sh" \
  2>&1 | tee -a "$LOG"
rc=${PIPESTATUS[0]}
set -e

log "fix_exec_rc=$rc"
if [[ "$rc" -eq 0 ]]; then
  log "OK: full-path dpkg runs. Safe to consider JBROOT on PATH for this session."
else
  log "FAIL: see $LOG"
fi
exit "$rc"
