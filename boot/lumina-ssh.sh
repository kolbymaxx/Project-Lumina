#!/usr/bin/env bash
# Reconnect to an already-booted Lumina ramdisk over usbmux SSH.
set -euo pipefail

BOOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ -f "${BOOT_DIR}/config.env" ]]; then
  # shellcheck disable=SC1091
  source "${BOOT_DIR}/config.env"
fi

LUMINA_UDID="${LUMINA_UDID:-00008020-00117540340B002E}"
IPROXY="${IPROXY:-iproxy}"
SSHPASS="${SSHPASS:-sshpass}"
IDEVICE_ID="${IDEVICE_ID:-idevice_id}"
SSH_PORT_LOCAL="${SSH_PORT_LOCAL:-2222}"
SSH_USER="${SSH_USER:-root}"
SSH_PASS="${SSH_PASS:-alpine}"

if ! command -v "$IDEVICE_ID" >/dev/null 2>&1; then
  echo "missing idevice_id" >&2
  exit 1
fi

echo "Looking for usbmux device ${LUMINA_UDID}..."
if [[ "${LUMINA_UDID}" != "any" ]]; then
  if ! "$IDEVICE_ID" -l 2>/dev/null | grep -qx "$LUMINA_UDID"; then
    echo "UDID not present. Connected devices:" >&2
    "$IDEVICE_ID" -l 2>/dev/null || true
    echo "If the ramdisk is up under another id, rerun with LUMINA_UDID=any" >&2
    exit 1
  fi
fi

pkill -f "iproxy .*${SSH_PORT_LOCAL}.*22" 2>/dev/null || true
"$IPROXY" "$SSH_PORT_LOCAL" 22 >/tmp/lumina-iproxy.log 2>&1 &
sleep 1

exec "$SSHPASS" -p "$SSH_PASS" ssh \
  -o StrictHostKeyChecking=no \
  -o UserKnownHostsFile=/dev/null \
  -o PreferredAuthentications=password \
  -o PubkeyAuthentication=no \
  -p "$SSH_PORT_LOCAL" \
  "${SSH_USER}@127.0.0.1" \
  "$@"
