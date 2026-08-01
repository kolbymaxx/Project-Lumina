#!/usr/bin/env bash
# Mac: iproxy + SSH report (mount, disk0*, Data probe). Never assumes Data mounts on 15.1.
# Windows: same tools if present; missing tools → non-zero exit (no silent success).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=lib_ctl.sh
source "${ROOT}/scripts/lib_ctl.sh"

LOGDIR="${ROOT}/logs"
mkdir -p "$LOGDIR"
STAMP="$(date +%Y%m%d-%H%M%S)"
LOG="${LOGDIR}/03_ramdisk_ssh-${STAMP}.log"
REPORT="${LOGDIR}/03_ramdisk_report-${STAMP}.txt"

SSH_PORT_LOCAL="${SSH_PORT_LOCAL:-2222}"
SSH_USER="${SSH_USER:-root}"
SSH_PASS="${SSH_PASS:-alpine}"
IPROXY="${IPROXY:-iproxy}"
SSHPASS="${SSHPASS:-sshpass}"
IDEVICE_ID="${IDEVICE_ID:-idevice_id}"
DATA_DEV="${DATA_DEV:-/dev/disk0s1s2}"
DATA_MNT="${DATA_MNT:-/mnt2}"

log() { echo "$@" | tee -a "$LOG"; }

log "lumina ramdisk SSH report — $STAMP"
log "ROOT=$ROOT"
log "platform=$(uname -s 2>/dev/null || echo unknown)"
log "NOTE Mac: brew idevice_id/iproxy/sshpass. Windows: install equivs or FAIL clearly."
log "POLICY: Data mount on 15.1 is NOT assumed (expect exit 76)."
log ""

need() {
  if ! command -v "$1" >/dev/null 2>&1; then
    log "FAIL: missing command: $1"
    log "Mac: brew install libimobiledevice usbmuxd sshpass"
    log "Windows: install libimobiledevice / sshpass — aborting"
    exit 1
  fi
}

need "$IDEVICE_ID"
need "$IPROXY"
need "$SSHPASS"
need ssh
find_usbliter8ctl >/dev/null || exit 1

log "### idevice_id -l"
"$IDEVICE_ID" -l 2>&1 | tee -a "$LOG" || true
if [[ -z "$("$IDEVICE_ID" -l 2>/dev/null || true)" ]]; then
  log "FAIL: no usbmux device — is the 15.1 ramdisk booted?"
  exit 1
fi

port_open() {
  if command -v nc >/dev/null 2>&1; then
    nc -z 127.0.0.1 "$SSH_PORT_LOCAL" >/dev/null 2>&1
  else
    return 1
  fi
}

if port_open; then
  log "iproxy: port ${SSH_PORT_LOCAL} already open — reusing"
else
  log "### starting iproxy ${SSH_PORT_LOCAL} 22"
  pkill -f "iproxy .*${SSH_PORT_LOCAL}.*22" 2>/dev/null || true
  nohup "$IPROXY" "$SSH_PORT_LOCAL" 22 >>"$LOG" 2>&1 &
  echo $! > "${LOGDIR}/iproxy.pid"
  sleep 2
  if ! port_open; then
    log "FAIL: iproxy did not open 127.0.0.1:${SSH_PORT_LOCAL}"
    exit 1
  fi
  log "OK: iproxy up pid=$(cat "${LOGDIR}/iproxy.pid")"
fi

REMOTE=$(cat <<'EOS'
set +e
echo "===== uname ====="
uname -a
echo "===== sw_vers / SystemVersion (ramdisk) ====="
sw_vers 2>/dev/null || true
cat /System/Library/CoreServices/SystemVersion.plist 2>/dev/null || true
echo "===== mount ====="
mount
echo "===== /dev/disk0* ====="
ls -la /dev/disk0* 2>/dev/null || true
echo "===== /mnt1 (System) ====="
if [[ -f /mnt1/System/Library/CoreServices/SystemVersion.plist ]]; then
  cat /mnt1/System/Library/CoreServices/SystemVersion.plist
else
  echo "NOTE: /mnt1 SystemVersion not present"
fi
echo "===== Data mount attempt (15.1: expect exit 76 — NOT success) ====="
mkdir -p "$DATA_MNT"
echo "mount_apfs -o rdonly $DATA_DEV $DATA_MNT"
mount_apfs -o rdonly "$DATA_DEV" "$DATA_MNT" 2>&1
rc=$?
echo "DATA_MOUNT_RC=$rc"
echo "DATA_MOUNT_SUCCESS=0"
case "$rc" in
  76) echo "RESULT=EXPECTED_FAIL exit 76 Program version wrong — not a Data mount" ;;
  0)  echo "RESULT=UNEXPECTED_MOUNT_OK — re-verify; update PROJECT_STATUS.md; do not claim yet" ;;
  *)  echo "RESULT=OTHER_FAIL rc=$rc — still no Data claim" ;;
esac
echo "NOTE: no DYLD_LIBRARY_PATH hacks — see ramdisk/NOTES_NEXT.md"
echo "===== done ====="
EOS
)

log "### ssh mount + disk + Data probe"
set +e
"$SSHPASS" -p "$SSH_PASS" ssh \
  -o StrictHostKeyChecking=no \
  -o UserKnownHostsFile=/dev/null \
  -o PreferredAuthentications=password \
  -o PubkeyAuthentication=no \
  -o ConnectTimeout=8 \
  -p "$SSH_PORT_LOCAL" \
  "${SSH_USER}@127.0.0.1" \
  "DATA_DEV='${DATA_DEV}' DATA_MNT='${DATA_MNT}' bash -s" <<<"$REMOTE" 2>&1 | tee -a "$LOG" | tee "$REPORT"
ssh_rc=${PIPESTATUS[0]}
set -e

log ""
log "ssh_rc=$ssh_rc"
log "Log: $LOG"
log "Report: $REPORT"
if [[ "$ssh_rc" -ne 0 ]]; then
  log "FAIL: SSH failed — check iproxy / ramdisk / password alpine"
  exit "$ssh_rc"
fi
log "OK: report saved (Data mount success is NOT claimed)"
