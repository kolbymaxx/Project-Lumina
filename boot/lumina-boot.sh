#!/usr/bin/env bash
# Lumina one-shot: pwned DFU → iBSS → Recovery payloads → bootx → SSH check.
# Requires the phone already in PWND:[usbliter8] DFU on a direct Mac cable.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BOOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ -f "${BOOT_DIR}/config.env" ]]; then
  # shellcheck disable=SC1091
  source "${BOOT_DIR}/config.env"
fi

LUMINA_UDID="${LUMINA_UDID:-00008020-00117540340B002E}"
RAMDISK_ROOT="${RAMDISK_ROOT:-${HOME}/Projects/usbliter8-xr-ramdisk}"
USBLITER8CTL="${USBLITER8CTL:-${HOME}/Projects/usbliter8-jailbreak/usbliter8ctl}"
IRECOVERY="${IRECOVERY:-irecovery}"
PYTHON="${PYTHON:-python3}"
IPROXY="${IPROXY:-iproxy}"
SSHPASS="${SSHPASS:-sshpass}"
IDEVICE_ID="${IDEVICE_ID:-idevice_id}"
SSH_PORT_LOCAL="${SSH_PORT_LOCAL:-2222}"
SSH_USER="${SSH_USER:-root}"
SSH_PASS="${SSH_PASS:-alpine}"
BOOTARGS="${BOOTARGS:-rd=md0 -v debug=0x2014e serial=3 wdt=-1 amfi_get_out_of_my_way=1 pmap_cs_allow_any_signature=1}"

PAYLOAD="${RAMDISK_ROOT}/payload"
LOGDIR="${ROOT}/artifacts/xr-18.7.5/boot-logs"
mkdir -p "$LOGDIR"
STAMP="$(date +%Y%m%d-%H%M%S)"
LOG="${LOGDIR}/boot-${STAMP}.log"

run() {
  echo
  echo "### $*" | tee -a "$LOG"
  "$@" 2>&1 | tee -a "$LOG"
}

need_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "missing command: $1" >&2
    exit 1
  }
}

need_file() {
  [[ -f "$1" ]] || {
    echo "Missing: $1" >&2
    exit 1
  }
}

resolve_usbliter8ctl() {
  if [[ -x "$USBLITER8CTL" ]]; then
    return
  fi
  if [[ -x "${ROOT}/usbliter8ctl" ]]; then
    USBLITER8CTL="${ROOT}/usbliter8ctl"
    return
  fi
  if [[ -x "${RAMDISK_ROOT}/tools/usbliter8ctl" ]]; then
    USBLITER8CTL="${RAMDISK_ROOT}/tools/usbliter8ctl"
    return
  fi
  echo "usbliter8ctl not found. Set USBLITER8CTL=..." >&2
  exit 1
}

wait_recovery() {
  for _ in $(seq 1 45); do
    if "$IRECOVERY" -q 2>/dev/null | tee -a "$LOG" | grep -q 'MODE: Recovery'; then
      return 0
    fi
    sleep 1
  done
  echo "Timed out waiting for Recovery after iBSS." | tee -a "$LOG"
  return 1
}

boot_ibss() {
  local tmp="${LOGDIR}/usbliter8-ibss-${STAMP}.log"
  echo
  echo "### $PYTHON $USBLITER8CTL boot ${PAYLOAD}/iBSS.raw" | tee -a "$LOG"
  "$PYTHON" "$USBLITER8CTL" boot "${PAYLOAD}/iBSS.raw" >"$tmp" 2>&1 &
  local pid=$!

  for _ in $(seq 1 30); do
    if ! kill -0 "$pid" 2>/dev/null; then
      wait "$pid" || true
      cat "$tmp" | tee -a "$LOG"
      return 0
    fi
    if "$IRECOVERY" -q 2>/dev/null | grep -q 'MODE: Recovery'; then
      kill "$pid" 2>/dev/null || true
      wait "$pid" 2>/dev/null || true
      cat "$tmp" | tee -a "$LOG"
      echo "iBSS is in Recovery; continuing." | tee -a "$LOG"
      return 0
    fi
    sleep 1
  done

  cat "$tmp" | tee -a "$LOG"
  echo "usbliter8ctl still running; checking Recovery anyway." | tee -a "$LOG"
  kill "$pid" 2>/dev/null || true
  wait "$pid" 2>/dev/null || true
}

device_on_usbmux() {
  local ids
  ids="$("$IDEVICE_ID" -l 2>/dev/null || true)"
  if [[ -z "$ids" ]]; then
    return 1
  fi
  if [[ "${LUMINA_UDID}" == "any" ]]; then
    echo "$ids" | head -n1
    return 0
  fi
  echo "$ids" | grep -qx "$LUMINA_UDID"
}

wait_usbmux() {
  echo "Waiting for usbmux UDID ${LUMINA_UDID} (or set LUMINA_UDID=any)..." | tee -a "$LOG"
  for _ in $(seq 1 60); do
    if device_on_usbmux >/dev/null; then
      echo "usbmux device present" | tee -a "$LOG"
      "$IDEVICE_ID" -l 2>/dev/null | tee -a "$LOG" || true
      return 0
    fi
    sleep 1
  done
  echo "Timed out waiting for usbmux device ${LUMINA_UDID}." | tee -a "$LOG"
  "$IDEVICE_ID" -l 2>/dev/null | tee -a "$LOG" || true
  return 1
}

ssh_check() {
  "$SSHPASS" -p "$SSH_PASS" ssh \
    -o StrictHostKeyChecking=no \
    -o UserKnownHostsFile=/dev/null \
    -o PreferredAuthentications=password \
    -o PubkeyAuthentication=no \
    -o ConnectTimeout=8 \
    -p "$SSH_PORT_LOCAL" \
    "${SSH_USER}@127.0.0.1" \
    '/bin/uname -a; /bin/cat /System/Library/CoreServices/SystemVersion.plist 2>/dev/null || true; /sbin/mount' \
    2>&1 | tee -a "$LOG"
}

need_cmd "$IRECOVERY"
need_cmd "$PYTHON"
need_cmd "$IPROXY"
need_cmd "$IDEVICE_ID"
need_cmd "$SSHPASS"

resolve_usbliter8ctl
need_file "$USBLITER8CTL"
need_file "${PAYLOAD}/iBSS.raw"

for f in \
  adc-petra-n84.img4 \
  aopfw-iphone11baop.img4 \
  AppleAVE2FW_H11.img4 \
  armfw_g11p.img4 \
  h11_ane_fw_quin.img4 \
  SmartIOFirmware_ASCv2.img4 \
  DeviceTree.n841ap.img4 \
  ramdisk.img4 \
  trustcache.img4 \
  kernelcache.development.iphone11b.img4; do
  need_file "${PAYLOAD}/${f}"
done

echo "Lumina boot log: $LOG"
echo "UDID: $LUMINA_UDID"
echo "RAMDISK_ROOT: $RAMDISK_ROOT"
echo "USBLITER8CTL: $USBLITER8CTL"
echo
echo "Prerequisite: device must already be PWND:[usbliter8] DFU on a direct Mac cable."

run "$IRECOVERY" -q

boot_ibss
wait_recovery

run "$IRECOVERY" -q
run "$IRECOVERY" -c 'bgcolor 0 127 127'

for fw in adc-petra-n84.img4 aopfw-iphone11baop.img4 AppleAVE2FW_H11.img4 armfw_g11p.img4 h11_ane_fw_quin.img4 SmartIOFirmware_ASCv2.img4; do
  run "$IRECOVERY" -f "${PAYLOAD}/${fw}"
  run "$IRECOVERY" -c firmware
done

run "$IRECOVERY" -f "${PAYLOAD}/DeviceTree.n841ap.img4"
run "$IRECOVERY" -c devicetree
run "$IRECOVERY" -f "${PAYLOAD}/ramdisk.img4"
run "$IRECOVERY" -c ramdisk
run "$IRECOVERY" -f "${PAYLOAD}/trustcache.img4"
run "$IRECOVERY" -c firmware
run "$IRECOVERY" -f "${PAYLOAD}/kernelcache.development.iphone11b.img4"
run "$IRECOVERY" -c "setenvnp boot-args ${BOOTARGS}"
run "$IRECOVERY" -c bootx

sleep 5
"$IRECOVERY" -q 2>&1 | tee -a "$LOG" || true

wait_usbmux || true
pkill -f "iproxy .*${SSH_PORT_LOCAL}.*22" 2>/dev/null || true
nohup "$IPROXY" "$SSH_PORT_LOCAL" 22 >>"$LOG" 2>&1 &
echo $! > "${LOGDIR}/iproxy.pid"
sleep 2

echo
echo "### SSH check" | tee -a "$LOG"
ssh_check || true

echo
echo "Done. Reconnect with: ${BOOT_DIR}/lumina-ssh.sh"
echo "Log: $LOG"
echo "Paste uname/SystemVersion/mount into docs/STATUS.md Phase A."
