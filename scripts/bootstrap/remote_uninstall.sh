#!/bin/bash
# Run ON DEVICE. Remove Lumina bootstrap from Data only.
set -euo pipefail

JBROOT="${JBROOT:-/mnt2/root/jb}"
STAGE="${STAGE:-/mnt2/tmp/lumina-bootstrap}"

die() { echo "FAIL: $*" >&2; exit 1; }

[[ "$JBROOT" == /mnt2/* ]] || die "refusing to delete JBROOT outside /mnt2: $JBROOT"
[[ "$STAGE" == /mnt2/* ]] || die "refusing to delete STAGE outside /mnt2: $STAGE"
case "$JBROOT" in
  /mnt2/tmp/*|/mnt2/root/*|/mnt2/mobile/*) ;;
  *) die "refusing uninstall of unexpected JBROOT: $JBROOT" ;;
esac

# Never touch System
if [[ -e /mnt1/jb ]]; then
  echo "NOTE: leaving /mnt1/jb alone (should not exist)"
fi

if [[ -d "$JBROOT" ]]; then
  echo "removing $JBROOT"
  rm -rf "$JBROOT"
else
  echo "absent $JBROOT"
fi

if [[ -d "$STAGE" ]]; then
  echo "removing $STAGE"
  rm -rf "$STAGE"
else
  echo "absent $STAGE"
fi

# Cleanup probe files if any
rm -f /mnt2/tmp/.lumina_wprobe_* 2>/dev/null || true

echo "OK: uninstall complete (Data only; sealed System untouched)"
