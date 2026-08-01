#!/usr/bin/env bash
# Run over an open ramdisk SSH session to gather Phase A notes.
# Usage: ./boot/lumina-ssh.sh 'bash -s' < boot/collect-ground-truth.sh
# Or:    ./boot/lumina-ssh.sh < boot/collect-ground-truth.sh
set -euo pipefail

echo "===== A1 uname ====="
uname -a || true

echo "===== A1 SystemVersion ====="
cat /System/Library/CoreServices/SystemVersion.plist 2>/dev/null || true

echo "===== A2 mount ====="
mount || true

echo "===== A2 disks ====="
ls -la /dev/disk* 2>/dev/null || true
ls -la /dev/disk0s* 2>/dev/null || true

echo "===== A4 likely kernel / firmware paths ====="
ls -la /System/Library/Caches/com.apple.kernelcaches 2>/dev/null || true
ls -la /System/Library/Caches 2>/dev/null || true
ls -la /private/preboot 2>/dev/null || true
ls -la /usr/standalone 2>/dev/null || true

echo "===== A5 writable probes ====="
touch /tmp/lumina_write_probe 2>/dev/null && echo "tmp writable" || echo "tmp not writable"
rm -f /tmp/lumina_write_probe 2>/dev/null || true
touch /var/tmp/lumina_write_probe 2>/dev/null && echo "var/tmp writable" || echo "var/tmp not writable"
rm -f /var/tmp/lumina_write_probe 2>/dev/null || true

echo "===== done — paste into docs/STATUS.md ====="
