#!/usr/bin/env bash
# Mac → device: push bootstrap archive and run remote_install.sh under /mnt2 only.
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
LOG="${LOGDIR}/bootstrap-push-${STAMP}.log"

SKELETON=0
BOOTSTRAP_TAR="${BOOTSTRAP_TAR:-}"

usage() {
  cat <<EOF
usage: BOOTSTRAP_TAR=/path/to/bootstrap.tar.gz $0
       $0 --skeleton
       $0 /path/to/bootstrap.tar.gz

Pushes to device ${SSH_USER}@${SSH_HOST}:${SSH_PORT} and installs under ${JBROOT}.
Requires iproxy ${SSH_PORT}→22 already running.
EOF
}

while (($#)); do
  case "$1" in
    --skeleton) SKELETON=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) BOOTSTRAP_TAR="$1"; shift ;;
  esac
done

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
  -o ConnectTimeout=10
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

# Preflight: Data writable, System sealed note
"${ssh_base[@]}" "test -d /mnt2 && touch /mnt2/tmp/.lumina_push_probe && rm /mnt2/tmp/.lumina_push_probe" \
  || { log "FAIL: /mnt2/tmp not writable — is mount_ich done?"; exit 1; }

"${ssh_base[@]}" "mkdir -p $STAGE"
"${scp_base[@]}" \
  "${ROOT}/scripts/bootstrap/env.sh" \
  "${ROOT}/scripts/bootstrap/remote_install.sh" \
  "${ROOT}/scripts/bootstrap/remote_verify.sh" \
  "${ROOT}/scripts/bootstrap/remote_uninstall.sh" \
  "${SSH_USER}@${SSH_HOST}:${STAGE}/"

# /mnt2 is effectively noexec for shebangs — always invoke with ramdisk bash/sh.
"${ssh_base[@]}" "chmod 644 $STAGE/env.sh $STAGE/remote_install.sh $STAGE/remote_verify.sh $STAGE/remote_uninstall.sh"

run_remote() {
  local script="$1"; shift
  "${ssh_base[@]}" "JBROOT=$JBROOT STAGE=$STAGE LUMINA_LDID=${LUMINA_LDID:-0} /bin/bash $STAGE/$script $*"
}

if [[ "$SKELETON" -eq 1 ]]; then
  log "### skeleton install (bash $STAGE/remote_install.sh — Data is noexec)"
  run_remote remote_install.sh --skeleton 2>&1 | tee -a "$LOG"
else
  [[ -n "$BOOTSTRAP_TAR" && -f "$BOOTSTRAP_TAR" ]] || {
    log "FAIL: set BOOTSTRAP_TAR or pass tarball path (or --skeleton)"
    usage
    exit 1
  }
  case "$BOOTSTRAP_TAR" in
    *.tar.gz|*.tgz|*.tar) ;;
    *.zst|*.tar.zst)
      log "FAIL: decompress .zst on Mac first (device has no zstd/curl)"
      exit 1
      ;;
    *) log "FAIL: need .tar or .tar.gz"; exit 1 ;;
  esac
  BASE="$(basename "$BOOTSTRAP_TAR")"
  REMOTE_TAR="$STAGE/$BASE"
  log "### scp $BOOTSTRAP_TAR -> $REMOTE_TAR"
  "${scp_base[@]}" "$BOOTSTRAP_TAR" "${SSH_USER}@${SSH_HOST}:${REMOTE_TAR}"
  log "### remote install"
  run_remote remote_install.sh "$REMOTE_TAR" 2>&1 | tee -a "$LOG"
fi

log "### verify"
set +e
run_remote remote_verify.sh 2>&1 | tee -a "$LOG"
rc=${PIPESTATUS[0]}
set -e
log "verify_rc=$rc"
log "Done. Uninstall: ./scripts/bootstrap/uninstall_bootstrap.sh"
exit "$rc"
