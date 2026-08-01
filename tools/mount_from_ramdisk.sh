#!/usr/bin/env bash
# Mount helpers informed by Phase A (2026-08-01) on XR 18.7.5 ramdisk SSH.
#
# Observed on hsbugss 15.1 restore ramdisk (19B5042h):
#   disk0s1s1 → /mnt1 System OK (on-disk OS 18.7.5 / 22H311)
#   disk0s1s2 → Data FAIL: mount_apfs: Program version wrong
#   disk0s1s5 → /mnt4 preboot-ish OK
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ART="${ROOT}/artifacts/xr-18.7.5"
MNT_SYSTEM="${MNT_SYSTEM:-/mnt1}"
MNT_DATA="${MNT_DATA:-/mnt2}"
MNT_PREBOOT="${MNT_PREBOOT:-/mnt4}"

SYSTEM_DEV="${SYSTEM_DEV:-/dev/disk0s1s1}"
DATA_DEV="${DATA_DEV:-/dev/disk0s1s2}"
PREBOOT_DEV="${PREBOOT_DEV:-/dev/disk0s1s5}"
# Data mount is known-broken on the 15.1 ramdisk mount_apfs.
ALLOW_DATA_MOUNT="${ALLOW_DATA_MOUNT:-0}"

usage() {
  cat <<EOF
Usage:
  $0 status
  $0 mount-system
  $0 mount-preboot
  $0 mount          # system (+ optional data if ALLOW_DATA_MOUNT=1)
  $0 umount

Phase A defaults:
  SYSTEM_DEV=$SYSTEM_DEV  → $MNT_SYSTEM
  DATA_DEV=$DATA_DEV      → $MNT_DATA   (FAIL on 15.1 mount_apfs)
  PREBOOT_DEV=$PREBOOT_DEV → $MNT_PREBOOT

Data mount is skipped unless ALLOW_DATA_MOUNT=1 (expected to fail today).
EOF
}

cmd="${1:-status}"

case "$cmd" in
  status)
    echo "artifacts dir: $ART"
    echo "SYSTEM_DEV=$SYSTEM_DEV → $MNT_SYSTEM"
    echo "DATA_DEV=$DATA_DEV → $MNT_DATA (ALLOW_DATA_MOUNT=$ALLOW_DATA_MOUNT)"
    echo "PREBOOT_DEV=$PREBOOT_DEV → $MNT_PREBOOT"
    echo
    echo "Note: 15.1 ramdisk mount_apfs cannot mount iOS 18 Data"
    echo "      (mount_apfs: Program version wrong)."
    mount | grep -E "$MNT_SYSTEM|$MNT_DATA|$MNT_PREBOOT|/dev/md0" || true
    ;;
  mount-system)
    mkdir -p "$MNT_SYSTEM"
    mount_apfs "$SYSTEM_DEV" "$MNT_SYSTEM"
    echo "System mounted at $MNT_SYSTEM"
    ls "$MNT_SYSTEM/System/Library/CoreServices/SystemVersion.plist" 2>/dev/null || true
    ;;
  mount-preboot)
    mkdir -p "$MNT_PREBOOT"
    mount_apfs "$PREBOOT_DEV" "$MNT_PREBOOT"
    echo "Preboot-ish mounted at $MNT_PREBOOT"
    ls "$MNT_PREBOOT/mobile/Library" 2>/dev/null || true
    ;;
  mount)
    mkdir -p "$MNT_SYSTEM"
    mount_apfs "$SYSTEM_DEV" "$MNT_SYSTEM"
    echo "System mounted at $MNT_SYSTEM"
    if [[ "$ALLOW_DATA_MOUNT" == "1" ]]; then
      mkdir -p "$MNT_DATA"
      echo "Attempting Data mount (likely to fail on 15.1 mount_apfs)..."
      mount_apfs "$DATA_DEV" "$MNT_DATA"
    else
      echo "Skipping Data mount (ALLOW_DATA_MOUNT=0)."
      echo "Blocker: 15.1 mount_apfs vs iOS 18 Data — see docs/STATUS.md"
    fi
    mount | grep -E "$MNT_SYSTEM|$MNT_DATA|$MNT_PREBOOT" || true
    ;;
  umount)
    umount "$MNT_DATA" 2>/dev/null || true
    umount "$MNT_PREBOOT" 2>/dev/null || true
    umount "$MNT_SYSTEM" 2>/dev/null || true
    echo "Unmount attempted."
    ;;
  *)
    usage
    exit 1
    ;;
esac
