#!/bin/bash
# Run ON DEVICE. Verify $JBROOT bootstrap. Exit 0=ok, 1=fail, 2=skeleton only.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=env.sh
[[ -f "$SCRIPT_DIR/env.sh" ]] && source "$SCRIPT_DIR/env.sh"

# Fallback mirrors scripts/bootstrap/env.sh in case it wasn't staged.
JBROOT="${JBROOT:-/mnt2/root/jb}"
MARKER="${JBROOT}/.lumina_bootstrap"
FAIL=0

echo "JBROOT=$JBROOT"
/sbin/mount | grep -E 'mnt1|mnt2|md0' || true

if [[ ! -f "$MARKER" ]]; then
  echo "FAIL: missing $MARKER"
  exit 1
fi
echo "----- marker -----"
cat "$MARKER"
echo

[[ -d "$JBROOT" ]] || { echo "FAIL: no $JBROOT"; exit 1; }

# Must not have required us to write System
if [[ -e /mnt1/jb ]]; then
  echo "WARN: /mnt1/jb exists (unexpected) — do not use"
fi

echo "----- top -----"
ls -la "$JBROOT" | head -30

mode="$(grep '^mode=' "$MARKER" | cut -d= -f2- || true)"
if [[ "$mode" == "skeleton" ]]; then
  echo "OK: skeleton present (no package manager expected)"
  exit 2
fi

echo "----- package manager probes -----"
for c in dpkg apt-get apt uicache; do
  if [[ -x "$JBROOT/usr/bin/$c" ]]; then
    echo "HAVE $JBROOT/usr/bin/$c"
  elif [[ -x "$JBROOT/bin/$c" ]]; then
    echo "HAVE $JBROOT/bin/$c"
  else
    echo "MISS $c under JBROOT"
    # dpkg miss is hard fail for full bootstrap
    if [[ "$c" == "dpkg" ]]; then FAIL=1; fi
  fi
done

if [[ -x "$JBROOT/usr/bin/dpkg" ]]; then
  echo "----- dpkg --version (full path; do not put JBROOT first on PATH) -----"
  # Keep system PATH — never put JBROOT first until a full-path binary runs.
  export PATH="/usr/bin:/bin:/usr/sbin:/sbin"
  if [[ -d "$JBROOT/var/lib/dpkg" ]]; then
    export DPKG_ADMINDIR="$JBROOT/var/lib/dpkg"
  fi
  "$JBROOT/usr/bin/dpkg" --version 2>&1 | head -5 || FAIL=1
fi

echo "----- ldid (ramdisk tool) -----"
command -v ldid || echo "MISS ldid on ramdisk PATH"

if [[ "$FAIL" -ne 0 ]]; then
  echo "FAIL: bootstrap incomplete"
  exit 1
fi
echo "OK: bootstrap looks usable under $JBROOT"
exit 0
