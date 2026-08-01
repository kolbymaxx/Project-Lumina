#!/usr/bin/env bash
# Host tool checklist. Safe with XR unplugged.
# Mac: brew tools. Windows: same checks; missing commands FAIL (no silent success).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=lib_ctl.sh
source "${ROOT}/scripts/lib_ctl.sh"

LOGDIR="${ROOT}/logs"
mkdir -p "$LOGDIR"
STAMP="$(date +%Y%m%d-%H%M%S)"
LOG="${LOGDIR}/00_check_env-${STAMP}.log"

pass=0
fail=0

check() {
  local label="$1"
  shift
  echo "### $label" | tee -a "$LOG"
  if "$@" >>"$LOG" 2>&1; then
    echo "OK: $label" | tee -a "$LOG"
    pass=$((pass + 1))
  else
    echo "FAIL: $label" | tee -a "$LOG"
    fail=$((fail + 1))
  fi
  echo | tee -a "$LOG"
}

echo "lumina lab env check — $STAMP" | tee "$LOG"
echo "ROOT=$ROOT" | tee -a "$LOG"
echo "uname: $(uname -a 2>/dev/null || echo unknown)" | tee -a "$LOG"
echo "NOTE: Mac is authoritative for live XR." | tee -a "$LOG"
echo | tee -a "$LOG"

CTL="$(find_usbliter8ctl)" || {
  echo "FAIL: usbliter8ctl locator" | tee -a "$LOG"
  exit 1
}
echo "ctl=$CTL" | tee -a "$LOG"

if command -v brew >/dev/null 2>&1; then
  check "brew --version" brew --version
else
  echo "### brew --version" | tee -a "$LOG"
  echo "SKIP: brew not found (expected on non-Mac)" | tee -a "$LOG"
  echo | tee -a "$LOG"
fi

check "python3 --version" python3 --version
check "pyusb + libusb backend" python3 -c \
  "import usb; import usb.backend.libusb1 as b; be=b.get_backend(); assert be is not None, 'no libusb backend'; print(usb.__version__, be)"
check "idevice_id --version" idevice_id --version
check "irecovery -V" irecovery -V
check "iproxy present" bash -c 'command -v iproxy'
check "sshpass present" command -v sshpass
check "usbliter8ctl -h" python3 "$CTL" -h
check "usbliter8ctl diagnose" python3 "$CTL" diagnose
# info with no device is expected FAIL when unplugged — log only
echo "### usbliter8ctl info (expect fail if unplugged)" | tee -a "$LOG"
python3 "$CTL" info >>"$LOG" 2>&1 || echo "NOTE: info failed (OK if XR unplugged)" | tee -a "$LOG"
echo | tee -a "$LOG"

echo "pass=$pass fail=$fail" | tee -a "$LOG"
echo "Log: $LOG"
exit 0
