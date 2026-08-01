#!/usr/bin/env bash
# Stub mount helpers for Phase A. Fill real disk names after collecting
# `ls /dev/disk*` from the live XR ramdisk SSH session.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ART="${ROOT}/artifacts/xr-18.7.5"
MNT_SYSTEM="${MNT_SYSTEM:-/mnt1}"
MNT_DATA="${MNT_DATA:-/mnt2}"

# Placeholder device nodes — REPLACE after Phase A paste into docs/STATUS.md.
# Examples only; do not assume these exist on 18.7.5 ramdisk layouts.
SYSTEM_DEV="${SYSTEM_DEV:-}"
DATA_DEV="${DATA_DEV:-}"

usage() {
  cat <<EOF
Usage:
  SYSTEM_DEV=/dev/disk0s1s1 DATA_DEV=/dev/disk0s1s2 $0 mount
  $0 umount
  $0 status

This stub refuses to mount until SYSTEM_DEV / DATA_DEV are set from Phase A.
EOF
}

cmd="${1:-status}"

case "$cmd" in
  status)
    echo "artifacts dir: $ART"
    echo "SYSTEM_DEV=${SYSTEM_DEV:-<unset>}"
    echo "DATA_DEV=${DATA_DEV:-<unset>}"
    echo "MNT_SYSTEM=$MNT_SYSTEM"
    echo "MNT_DATA=$MNT_DATA"
    mount | grep -E "$MNT_SYSTEM|$MNT_DATA" || true
    ;;
  mount)
    if [[ -z "$SYSTEM_DEV" || -z "$DATA_DEV" ]]; then
      echo "Refusing to mount: set SYSTEM_DEV and DATA_DEV from Phase A output." >&2
      echo "Example after you know the nodes:" >&2
      echo "  SYSTEM_DEV=/dev/disk0s1s1 DATA_DEV=/dev/disk0s1s2 $0 mount" >&2
      exit 1
    fi
    mkdir -p "$MNT_SYSTEM" "$MNT_DATA"
    mount_apfs "$SYSTEM_DEV" "$MNT_SYSTEM"
    mount_apfs "$DATA_DEV" "$MNT_DATA"
    mount | grep -E "$MNT_SYSTEM|$MNT_DATA"
    echo "Mounted. Pull notes into ${ART}/ and docs/STATUS.md."
    ;;
  umount)
    umount "$MNT_DATA" 2>/dev/null || true
    umount "$MNT_SYSTEM" 2>/dev/null || true
    echo "Unmount attempted."
    ;;
  *)
    usage
    exit 1
    ;;
esac
