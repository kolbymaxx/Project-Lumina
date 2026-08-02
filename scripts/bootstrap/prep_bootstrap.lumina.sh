#!/bin/bash
# Lumina JBROOT-aware prep — replaces Procursus prep_bootstrap.sh hardcodes + uialert loop.
# Run ON DEVICE: PATH=/usr/bin:/bin:/usr/sbin:/sbin /bin/bash $JBROOT/prep_bootstrap.lumina.sh
# Does not prompt for passwords (no uialert on ICH ramdisk).
set +e
export PATH="/usr/bin:/bin:/usr/sbin:/sbin"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Prefer staged env.sh next to remote scripts; else env.sh under JBROOT if present.
# shellcheck source=env.sh
if [[ -f "$SCRIPT_DIR/env.sh" ]]; then
  source "$SCRIPT_DIR/env.sh"
elif [[ -f "${JBROOT:-/mnt2/root/jb}/../tmp/lumina-bootstrap/env.sh" ]]; then
  source "/mnt2/tmp/lumina-bootstrap/env.sh"
fi

JBROOT="${JBROOT:-/mnt2/root/jb}"
PREFIX="$JBROOT"
# Optional session map created by remote_fix_exec.sh for Procursus @rpath=/var/jb/...
# Prefer that only when it already resolves; never mkdir /var/jb as a package root.
if [[ -x /var/jb/usr/bin/dpkg ]]; then
  PREFIX=/var/jb
fi

# Only add PREFIX after caller has verified full-path dpkg works.
export PATH="$PREFIX/usr/bin:$PREFIX/usr/sbin:/usr/bin:/bin:/usr/sbin:/sbin"

echo "PREFIX=$PREFIX JBROOT=$JBROOT"

[[ -x "$PREFIX/usr/libexec/firmware" ]] && "$PREFIX/usr/libexec/firmware" || true
[[ -x "$PREFIX/usr/sbin/pwd_mkdb" ]] && \
  "$PREFIX/usr/sbin/pwd_mkdb" -p "$PREFIX/etc/master.passwd" >/dev/null 2>&1 || true

for p in debianutils apt dash zsh bash vi; do
  f="$PREFIX/Library/dpkg/info/${p}.postinst"
  if [[ -x "$f" ]]; then
    echo "postinst $p"
    "$f" configure 99999 || true
  fi
done

[[ -x "$PREFIX/usr/sbin/pwd_mkdb" ]] && \
  "$PREFIX/usr/sbin/pwd_mkdb" -p "$PREFIX/etc/master.passwd" || true

echo "OK: lumina prep done (uialert/password loop skipped)"
echo "note: original $JBROOT/prep_bootstrap.sh still hardcodes /var/jb — use this wrapper"
exit 0
