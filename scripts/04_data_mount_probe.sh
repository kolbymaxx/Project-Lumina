#!/usr/bin/env bash
# Probe Data on 15.1 ramdisk. Exit 76 is EXPECTED — do NOT treat as Data success.
# HARD RULE: no DYLD_LIBRARY_PATH hacks. Closed: _malloc_type_malloc on newer mount_apfs.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LOGDIR="${ROOT}/logs"
mkdir -p "$LOGDIR"
STAMP="$(date +%Y%m%d-%H%M%S)"
LOG="${LOGDIR}/04_data_mount_probe-${STAMP}.log"

SSH_PORT_LOCAL="${SSH_PORT_LOCAL:-2222}"
SSH_USER="${SSH_USER:-root}"
SSH_PASS="${SSH_PASS:-alpine}"
SSHPASS="${SSHPASS:-sshpass}"
IPROXY="${IPROXY:-iproxy}"
DATA_DEV="${DATA_DEV:-/dev/disk0s1s2}"
DATA_MNT="${DATA_MNT:-/mnt2}"
ALSO_S8="${ALSO_S8:-/dev/disk0s1s8}"

log() { echo "$@" | tee -a "$LOG"; }

log "lumina Data mount probe — $STAMP"
log "EXPECTED: mount_apfs Data -> exit 76 (Program version wrong)"
log "NOT SUCCESS: exit 76 means Data did not mount"
log "CLOSED: DYLD / drop-in newer mount_apfs (_malloc_type_malloc on 15.1 libSystem)"
log "Mac: iproxy + sshpass. Windows: same if tools exist; else FAIL."
log ""

if ! command -v "$SSHPASS" >/dev/null 2>&1; then
  log "FAIL: missing sshpass"
  exit 1
fi

port_open() {
  command -v nc >/dev/null 2>&1 && nc -z 127.0.0.1 "$SSH_PORT_LOCAL" >/dev/null 2>&1
}

if ! port_open; then
  if ! command -v "$IPROXY" >/dev/null 2>&1; then
    log "FAIL: port ${SSH_PORT_LOCAL} closed and iproxy missing"
    exit 1
  fi
  log "### starting iproxy ${SSH_PORT_LOCAL} 22"
  pkill -f "iproxy .*${SSH_PORT_LOCAL}.*22" 2>/dev/null || true
  nohup "$IPROXY" "$SSH_PORT_LOCAL" 22 >>"$LOG" 2>&1 &
  sleep 2
fi

REMOTE=$(cat <<EOS
set +e
echo "===== POLICY ====="
echo "15.1 ramdisk cannot mount iOS 18 Data. Exit 76 = expected failure (not success)."
echo "Do not DYLD-hack mount_apfs. Next: newer ramdisk (ramdisk/NOTES_NEXT.md)."
echo "===== probe ${DATA_DEV} -> ${DATA_MNT} ====="
mkdir -p "${DATA_MNT}"
mount_apfs -o rdonly "${DATA_DEV}" "${DATA_MNT}" 2>&1
rc=\$?
echo "DATA_MOUNT_RC=\$rc"
echo "DATA_MOUNT_SUCCESS=0"
echo "===== probe ${ALSO_S8} -> /mnt8 ====="
mkdir -p /mnt8
mount_apfs -o rdonly "${ALSO_S8}" /mnt8 2>&1
echo "S8_MOUNT_RC=\$?"
echo "===== tools ====="
ls -l /sbin/mount_apfs 2>/dev/null || true
sw_vers 2>/dev/null || true
# Exit code for host script: 76 if Data got 76; 0 only if unexpected mount; 2 otherwise
if [[ \$rc -eq 76 ]]; then
  echo "RESULT=EXPECTED_FAIL exit 76 — documented; NOT a Data mount success"
  exit 76
elif [[ \$rc -eq 0 ]]; then
  echo "RESULT=UNEXPECTED_MOUNT — re-verify before any claim"
  exit 0
else
  echo "RESULT=OTHER_FAIL rc=\$rc — still no Data claim"
  exit 2
fi
EOS
)

set +e
"$SSHPASS" -p "$SSH_PASS" ssh \
  -o StrictHostKeyChecking=no \
  -o UserKnownHostsFile=/dev/null \
  -o PreferredAuthentications=password \
  -o PubkeyAuthentication=no \
  -o ConnectTimeout=8 \
  -p "$SSH_PORT_LOCAL" \
  "${SSH_USER}@127.0.0.1" \
  "bash -s" <<<"$REMOTE" 2>&1 | tee -a "$LOG"
ssh_rc=${PIPESTATUS[0]}
set -e

log ""
log "ssh_remote_rc=$ssh_rc"
log "Log: $LOG"

if [[ "$ssh_rc" -eq 76 ]]; then
  log "PROBE_OK_EXPECTED_FAIL: exit 76 documented — Data did NOT mount (not success)"
  # Non-zero so automation never treats this as Data success
  exit 76
fi

if [[ "$ssh_rc" -eq 0 ]]; then
  log "UNEXPECTED: remote reported Data mount rc=0 — update PROJECT_STATUS.md after re-verify"
  exit 0
fi

if [[ "$ssh_rc" -eq 255 || "$ssh_rc" -eq 1 ]]; then
  # ssh connection failures often 255
  log "FAIL: SSH/probe infrastructure error rc=$ssh_rc"
  exit 1
fi

log "PROBE_OTHER: rc=$ssh_rc — not treated as Data success"
exit "$ssh_rc"
