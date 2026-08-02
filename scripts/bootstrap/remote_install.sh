#!/bin/bash
# Run ON DEVICE (ICH ramdisk root). Installs bootstrap under $JBROOT only.
# Args: <staging_tar_path> | --skeleton
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=env.sh
[[ -f "$SCRIPT_DIR/env.sh" ]] && source "$SCRIPT_DIR/env.sh"

# Fallback mirrors scripts/bootstrap/env.sh in case it wasn't staged.
# Default under /mnt2/root — NEW top-level dirs on Data (e.g. /mnt2/jb) allow
# mkdir but reject file creates (Operation not permitted) on this 18.7.5 volume.
JBROOT="${JBROOT:-/mnt2/root/jb}"
STAGE="${STAGE:-/mnt2/tmp/lumina-bootstrap}"
MARKER="${JBROOT}/.lumina_bootstrap"
MODE="${1:-}"

die() { echo "FAIL: $*" >&2; exit 1; }

# Refuse System volume installs
case "$JBROOT" in
  /mnt1|/*mnt1*) die "refusing JBROOT on System volume: $JBROOT" ;;
esac
[[ "$JBROOT" == /mnt2/* ]] || die "JBROOT must be under /mnt2 (got $JBROOT)"
case "$JBROOT" in
  /mnt2/tmp/*|/mnt2/root/*|/mnt2/mobile/*) ;;
  *)
    echo "WARN: JBROOT $JBROOT is not under tmp/root/mobile — file creates may fail on this Data volume"
    ;;
esac

command -v tar >/dev/null || die "tar missing"
command -v gzip >/dev/null || die "gzip missing"

mkdir -p "$STAGE" "$JBROOT"
STAMP="$(date -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date)"

write_marker() {
  # No heredocs — bash temp files fail on RO ramdisk /.
  {
    echo "lumina_bootstrap=1"
    echo "mode=$1"
    echo "jbroot=$JBROOT"
    echo "created=$STAMP"
    shift
    for line in "$@"; do
      echo "$line"
    done
  } >"$MARKER"
}

if [[ "$MODE" == "--skeleton" ]]; then
  mkdir -p "$JBROOT/usr/bin" "$JBROOT/usr/sbin" "$JBROOT/usr/lib" \
    "$JBROOT/Library" "$JBROOT/etc" "$JBROOT/var/lib/dpkg"
  write_marker skeleton "note=no package manager binaries; layout only"
  echo "OK: skeleton at $JBROOT"
  exit 0
fi

TAR="$MODE"
[[ -n "$TAR" && -f "$TAR" ]] || die "usage: remote_install.sh </mnt2/tmp/.../bootstrap.tar.gz|--skeleton>"

# Extract to a clean work dir, then merge into JBROOT (supports tar with var/jb/ prefix)
WORK="$STAGE/extract-$$"
rm -rf "$WORK"
mkdir -p "$WORK"

echo "extracting $TAR -> $WORK"
case "$TAR" in
  *.tar.gz|*.tgz) gzip -dc "$TAR" | tar -x -f - -C "$WORK" ;;
  *.tar) tar -x -f "$TAR" -C "$WORK" ;;
  *) die "unsupported archive (use .tar or .tar.gz): $TAR" ;;
esac

SRC="$WORK"
# Archive layout only — Procursus rootless tarballs ship under var/jb/; we merge into $JBROOT.
if [[ -d "$WORK/var/jb" ]]; then
  SRC="$WORK/var/jb"
  echo "note: detected var/jb/ prefix in archive (not installing to host /var/jb)"
elif [[ -d "$WORK/jb" ]]; then
  SRC="$WORK/jb"
  echo "note: detected jb/ prefix in archive"
fi

# Must look like a prefix (usr/ or bin/ or Library/)
if [[ ! -d "$SRC/usr" && ! -d "$SRC/Library" && ! -d "$SRC/bin" ]]; then
  echo "FAIL: archive contents not recognized as bootstrap prefix" >&2
  ls -la "$WORK" >&2 || true
  exit 1
fi

echo "merging $SRC -> $JBROOT"
# copy quietly; tar pipeline preserves modes
( cd "$SRC" && tar -cf - . ) | ( cd "$JBROOT" && tar -xpf - )

# Optional: ldid ad-hoc on jbroot binaries if ldid exists and LUMINA_LDID=1
if [[ "${LUMINA_LDID:-0}" == "1" ]] && command -v ldid >/dev/null 2>&1; then
  echo "ldid pass (LUMINA_LDID=1) under $JBROOT/usr/bin"
  if [[ -d "$JBROOT/usr/bin" ]]; then
    for f in "$JBROOT/usr/bin"/*; do
      [[ -f "$f" && -x "$f" ]] || continue
      ldid -S "$f" 2>/dev/null || ldid -s "$f" 2>/dev/null || true
    done
  fi
fi

if [[ -f "$JBROOT/.procursus_strapped" ]]; then
  PS=1
else
  PS=0
fi
write_marker tarball "source_tar=$(basename "$TAR")" "procursus_strapped=$PS"

# Permissions: ensure dirs traversable; don't chmod -R 777
chmod 755 "$JBROOT" 2>/dev/null || true
[[ -d "$JBROOT/usr/bin" ]] && chmod 755 "$JBROOT/usr/bin" 2>/dev/null || true

rm -rf "$WORK"
echo "OK: bootstrap installed at $JBROOT"
echo "Session PATH hint: export PATH=\"$JBROOT/usr/bin:$JBROOT/usr/sbin:\$PATH\""
echo "Session JBROOT hint: export JBROOT=$JBROOT"
