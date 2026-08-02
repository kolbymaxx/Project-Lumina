#!/usr/bin/env bash
# Lumina one-shot host helper (Mac): check tools, start iproxy, print SSH.
#
# Does NOT DFU/pwn or boot the ramdisk. After PWND DFU, boot with ICH
# ~/Projects/ICH_A12_plus_Ramdisk/boot.sh (preferred) or ./boot/lumina-boot.sh.
# Full sequence: scripts/user/from_dfu_to_ssh.md
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

SSH_PORT_LOCAL="${SSH_PORT_LOCAL:-2222}"
SSH_USER="${SSH_USER:-root}"
SSH_PASS="${SSH_PASS:-alpine}"
SSHPASS="${SSHPASS:-sshpass}"
IDEVICE_ID="${IDEVICE_ID:-idevice_id}"
IRECOVERY="${IRECOVERY:-irecovery}"
PYTHON="${PYTHON:-python3}"
ICH_ROOT="${ICH_ROOT:-${HOME}/Projects/ICH_A12_plus_Ramdisk}"
ICH_IPROXY="${ICH_ROOT}/tools/darwin/iproxy"
IPROXY_LOG="${IPROXY_LOG:-/tmp/lumina-one-shot-iproxy.log}"

pass=0
fail=0

ok()   { echo "  OK:   $*"; pass=$((pass + 1)); }
bad()  { echo "  FAIL: $*"; fail=$((fail + 1)); }
note() { echo "  NOTE: $*"; }

need_cmd() {
  local label="$1" cmd="$2"
  if command -v "$cmd" >/dev/null 2>&1; then
    ok "$label ($cmd)"
  else
    bad "$label ($cmd) — not found"
  fi
}

resolve_iproxy() {
  # Prefer ICH vendored iproxy (brew iproxy can drop mid-session).
  if [[ -n "${IPROXY:-}" ]]; then
    echo "$IPROXY"
    return
  fi
  if [[ -x "$ICH_IPROXY" ]]; then
    echo "$ICH_IPROXY"
    return
  fi
  if command -v iproxy >/dev/null 2>&1; then
    command -v iproxy
    return
  fi
  echo ""
}

echo "Lumina one-shot Mac helper"
echo "root: $ROOT"
echo

if [[ "$(uname -s)" != "Darwin" ]]; then
  note "not running on macOS (uname=$(uname -s)) — this helper targets the Mac path"
fi

echo "### Host tool check"
need_cmd "irecovery" "$IRECOVERY"
need_cmd "idevice_id" "$IDEVICE_ID"
need_cmd "sshpass" "$SSHPASS"
need_cmd "python3" "$PYTHON"

IPROXY_BIN="$(resolve_iproxy)"
if [[ -n "$IPROXY_BIN" ]]; then
  if [[ "$IPROXY_BIN" == "$ICH_IPROXY" ]]; then
    ok "iproxy (ICH vendored: $IPROXY_BIN)"
  else
    ok "iproxy ($IPROXY_BIN)"
    if [[ ! -x "$ICH_IPROXY" ]]; then
      note "ICH vendored iproxy missing at $ICH_IPROXY — brew iproxy can drop; install ICH tree for preferred path"
    fi
  fi
else
  bad "iproxy — not found (expected $ICH_IPROXY or brew iproxy)"
fi

if "$PYTHON" -c "import usb, usb.backend.libusb1 as b; assert b.get_backend() is not None" >/dev/null 2>&1; then
  ok "pyusb + libusb backend"
else
  bad "pyusb + libusb backend — run: python3 -m pip install pyusb && brew install libusb"
fi

USBLITER8CTL=""
for c in "${ROOT}/usbliter8ctl" "${ROOT}/host/usbliter8ctl"; do
  if [[ -f "$c" ]]; then
    USBLITER8CTL="$c"
    break
  fi
done
if [[ -n "$USBLITER8CTL" ]]; then
  ok "usbliter8ctl found at $USBLITER8CTL"
else
  bad "usbliter8ctl not found (looked in ${ROOT}/usbliter8ctl, ${ROOT}/host/usbliter8ctl)"
fi

if [[ -d "$ICH_ROOT" ]]; then
  ok "ICH ramdisk tree present ($ICH_ROOT)"
  if [[ -x "${ICH_ROOT}/boot.sh" ]]; then
    ok "ICH boot.sh present"
  else
    note "ICH boot.sh missing — clone/build ICH_A12_plus_Ramdisk before ramdisk boot"
  fi
else
  note "ICH ramdisk tree not found at $ICH_ROOT (preferred boot path)"
fi

echo
echo "### Device check (safe if unplugged / not pwned yet)"
DFU_STATE="$("$IRECOVERY" -q 2>/dev/null || true)"
if [[ -z "$DFU_STATE" ]]; then
  note "no DFU/Recovery device via irecovery (DFU + Pico pwn + direct Mac cable first)"
elif echo "$DFU_STATE" | grep -q 'PWND:\[usbliter8\]'; then
  ok "device is in Pwned DFU (PWND:[usbliter8])"
elif echo "$DFU_STATE" | grep -q 'MODE: DFU'; then
  note "device is in plain DFU (not yet pwned) — run the Pico pwn step"
elif echo "$DFU_STATE" | grep -q 'MODE: Recovery'; then
  note "device is in Recovery — ramdisk boot likely in progress/done"
else
  note "unrecognized irecovery output:"
  echo "$DFU_STATE" | sed 's/^/    /'
fi

echo
echo "### usbmux check (meaningful once the ramdisk has booted)"
USBMUX_IDS="$("$IDEVICE_ID" -l 2>/dev/null || true)"
if [[ -n "$USBMUX_IDS" ]]; then
  ok "usbmux device(s) present:"
  echo "$USBMUX_IDS" | sed 's/^/    /'
else
  note "no usbmux device yet — normal until the ramdisk finishes booting"
fi

echo
echo "### iproxy"
# Avoid killing unrelated processes: match only iproxy with our local port → 22.
if pgrep -f "[i]proxy[[:space:]]+${SSH_PORT_LOCAL}[[:space:]]+22" >/dev/null 2>&1; then
  pkill -f "[i]proxy[[:space:]]+${SSH_PORT_LOCAL}[[:space:]]+22" 2>/dev/null || true
  sleep 0.3
fi

if [[ -n "$IPROXY_BIN" && -x "$IPROXY_BIN" ]] || command -v "$IPROXY_BIN" >/dev/null 2>&1; then
  nohup "$IPROXY_BIN" "$SSH_PORT_LOCAL" 22 >"$IPROXY_LOG" 2>&1 &
  IPROXY_PID=$!
  sleep 1
  if kill -0 "$IPROXY_PID" 2>/dev/null; then
    ok "iproxy running (pid $IPROXY_PID, log $IPROXY_LOG)"
  else
    bad "iproxy exited immediately — see $IPROXY_LOG"
  fi
else
  bad "iproxy not available — cannot forward SSH port"
fi

echo
echo "=================================================================="
echo "Summary: $pass OK, $fail FAIL"
echo
if [[ "$fail" -gt 0 ]]; then
  echo "Fix the FAIL items above before continuing."
  echo "See scripts/user/from_dfu_to_ssh.md for the full DFU -> SSH sequence."
fi
echo "SSH command (once the ramdisk is booted and iproxy is up):"
echo
echo "  sshpass -p ${SSH_PASS} ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o PreferredAuthentications=password -o PubkeyAuthentication=no -p ${SSH_PORT_LOCAL} ${SSH_USER}@127.0.0.1"
echo
echo "Or via the repo wrapper:"
echo
echo "  ${ROOT}/boot/lumina-ssh.sh"
echo
echo "On device after SSH (ICH):     mount_ich"
echo "Not booted yet? Full sequence: scripts/user/from_dfu_to_ssh.md"
echo "Preferred boot (after PWND):   ${ICH_ROOT}/boot.sh"
echo "Alternate Lumina boot:         ${ROOT}/boot/lumina-boot.sh"

# Always exit 0 after printing the SSH line so the helper stays useful as a
# "print me the command" tool even when some optional checks failed.
# Non-zero only if iproxy itself could not start and caller needs a hard stop:
if [[ "$fail" -gt 0 ]] && ! kill -0 "${IPROXY_PID:-0}" 2>/dev/null; then
  exit 1
fi
exit 0
