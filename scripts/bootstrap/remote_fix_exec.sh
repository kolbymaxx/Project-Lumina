#!/bin/bash
# Run ON DEVICE (ICH ramdisk). Map /var/jb → $JBROOT (session rpath shim), resign, test dpkg.
# Invoked with: PATH=/usr/bin:/bin:/usr/sbin:/sbin /bin/bash this_script
# /var/jb here is ONLY a Procursus @rpath compatibility symlink — not a package install root.
set +e
export PATH="/usr/bin:/bin:/usr/sbin:/sbin"

# dirname(1) may be absent on ramdisk PATH — prefer STAGE-provided env.
STAGE="${STAGE:-/mnt2/tmp/lumina-bootstrap}"
# shellcheck source=env.sh
[[ -f "$STAGE/env.sh" ]] && source "$STAGE/env.sh"

JBROOT="${JBROOT:-/mnt2/root/jb}"
PLIST="${PLIST:-$STAGE/platform.plist}"
DPKG="$JBROOT/usr/bin/dpkg"
FAIL=0

echo "JBROOT=$JBROOT"
echo "PATH=$PATH"

if [[ ! -x "$DPKG" ]]; then
  echo "FAIL: missing $DPKG"
  exit 1
fi

# Remount Data if needed
if command -v mount_ich >/dev/null 2>&1; then
  if ! /sbin/mount | grep -q ' on /mnt2 '; then
    mount_ich >/dev/null 2>&1
  fi
fi

# --- /var/jb → JBROOT (session mapping; root is APFS RO) ---
# Forbidden as a package root; used only so LC_RPATH=/var/jb/usr/lib resolves.
# New directory entries under /private/var fail on RO root; mount_tmpfs works.
map_var_jb() {
  if [[ -L /var/jb ]] || [[ -L /private/var/jb ]]; then
    local tgt
    tgt="$(readlink /var/jb 2>/dev/null || readlink /private/var/jb 2>/dev/null || true)"
    if [[ "$tgt" == "$JBROOT" ]]; then
      echo "OK: /var/jb already -> $JBROOT"
      return 0
    fi
  fi
  if [[ -e /var/jb/usr/bin/dpkg ]]; then
    echo "OK: /var/jb already resolves to bootstrap"
    return 0
  fi

  if ! /sbin/mount | grep -q 'tmpfs on /private/var'; then
    if [[ -x /sbin/mount_tmpfs ]]; then
      /sbin/mount_tmpfs -s 8M /private/var
      echo "mount_tmpfs /private/var rc=$?"
    else
      /sbin/mount -t tmpfs tmpfs /private/var
      echo "mount -t tmpfs /private/var rc=$?"
    fi
  fi

  if ! /sbin/mount | grep -q 'tmpfs on /private/var'; then
    echo "WARN: could not tmpfs-mount /private/var — /var/jb map skipped"
    return 1
  fi

  # CRITICAL: tmpfs hides ramdisk /private/var — recreate dropbear/SSH dirs
  # immediately or subsequent SSH sessions return empty/broken.
  mkdir -p /private/var/empty /private/var/tmp /private/var/root \
    /private/var/run /private/var/log /private/var/db
  chmod 755 /private/var/empty /private/var/tmp /private/var/root \
    /private/var/run /private/var/log 2>/dev/null || true

  # Do NOT mkdir jb first — ln into an existing dir nests the link.
  rm -rf /private/var/jb
  ln -s "$JBROOT" /private/var/jb
  echo "ln /private/var/jb -> $JBROOT rc=$?"
  ls -la /var/jb/usr/bin/dpkg 2>&1 | head -3
  return 0
}

map_var_jb

# --- entitlements plist ---
if [[ ! -f "$PLIST" ]]; then
  PLIST=/mnt2/tmp/lumina-platform.plist
  {
    echo '<?xml version="1.0" encoding="UTF-8"?>'
    echo '<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">'
    echo '<plist version="1.0">'
    echo '<dict>'
    echo '	<key>platform-application</key>'
    echo '	<true/>'
    echo '	<key>com.apple.private.security.container-required</key>'
    echo '	<false/>'
    echo '	<key>com.apple.private.security.no-container</key>'
    echo '	<true/>'
    echo '	<key>com.apple.private.security.storage-exempt.heritable</key>'
    echo '	<true/>'
    echo '	<key>get-task-allow</key>'
    echo '	<true/>'
    echo '	<key>task_for_pid-allow</key>'
    echo '	<true/>'
    echo '</dict>'
    echo '</plist>'
  } >"$PLIST"
  echo "wrote $PLIST"
fi

if ! command -v ldid >/dev/null 2>&1; then
  echo "FAIL: ldid missing on ramdisk PATH"
  exit 1
fi

sign_one() {
  local f="$1"
  [[ -f "$f" ]] || return 0
  # Prefer platform binary + adhoc + ents; fall back progressively.
  if ldid -S"$PLIST" -P -Cadhoc "$f" >/dev/null 2>&1; then
    return 0
  fi
  if ldid -S"$PLIST" -Cadhoc "$f" >/dev/null 2>&1; then
    return 0
  fi
  if ldid -S"$PLIST" "$f" >/dev/null 2>&1; then
    return 0
  fi
  ldid -S "$f" >/dev/null 2>&1 || return 1
  return 0
}

echo "----- batch ldid under $JBROOT -----"
# Ramdisk PATH has no od/tr — sign by path pattern (skip symlinks/scripts).
count=0
sign_tree() {
  local dir="$1"
  local f
  [[ -d "$dir" ]] || return 0
  for f in "$dir"/*; do
    [[ -f "$f" ]] || continue
    [[ -L "$f" ]] && continue
    # skip obvious text scripts
    case "$f" in
      *.sh|*.py|*.pl|*.bash) continue ;;
    esac
    if sign_one "$f"; then
      count=$((count + 1))
    else
      echo "WARN: ldid failed: $f"
    fi
  done
}

sign_tree "$JBROOT/usr/bin"
sign_tree "$JBROOT/usr/sbin"
sign_tree "$JBROOT/bin"
sign_tree "$JBROOT/sbin"
sign_tree "$JBROOT/usr/libexec"
sign_tree "$JBROOT/usr/lib"
# Nested dylib dirs (engines-3, bash, …)
for dir in "$JBROOT"/usr/lib/*/; do
  [[ -d "$dir" ]] || continue
  sign_tree "$dir"
done
echo "signed_count=$count"

# --- adapt prep_bootstrap (no /var/jb as package root) ---
PREP="$JBROOT/prep_bootstrap.sh"
PREP_WRAP="$JBROOT/prep_bootstrap.lumina.sh"
PREP_SRC="$STAGE/prep_bootstrap.lumina.sh"
if [[ -f "$PREP_SRC" ]]; then
  cp "$PREP_SRC" "$PREP_WRAP"
  chmod 755 "$PREP_WRAP" 2>/dev/null || true
  echo "installed $PREP_WRAP from staging"
elif [[ -f "$PREP" ]]; then
  {
    echo '#!/bin/bash'
    echo '# Lumina wrapper: JBROOT-aware prep (skips uialert password loop on ramdisk)'
    echo "export PATH=\"/usr/bin:/bin:/usr/sbin:/sbin\""
    echo "JBROOT=\"\${JBROOT:-$JBROOT}\""
    echo '# Prefer session /var/jb map if present; else run postinsts via JBROOT'
    echo 'PREFIX="$JBROOT"'
    echo 'if [ -x /var/jb/usr/bin/dpkg ]; then PREFIX=/var/jb; fi'
    echo 'export PATH="$PREFIX/usr/bin:$PREFIX/usr/sbin:/usr/bin:/bin:/usr/sbin:/sbin"'
    echo '[ -x "$PREFIX/usr/libexec/firmware" ] && "$PREFIX/usr/libexec/firmware" || true'
    echo '[ -x "$PREFIX/usr/sbin/pwd_mkdb" ] && "$PREFIX/usr/sbin/pwd_mkdb" -p "$PREFIX/etc/master.passwd" >/dev/null 2>&1 || true'
    echo 'for p in debianutils apt dash zsh bash vi; do'
    echo '  f="$PREFIX/Library/dpkg/info/${p}.postinst"'
    echo '  [ -x "$f" ] && "$f" configure 99999 || true'
    echo 'done'
    echo 'echo "OK: lumina prep via PREFIX=$PREFIX (password/uialert skipped)"'
  } >"$PREP_WRAP"
  chmod 755 "$PREP_WRAP" 2>/dev/null || true
  echo "wrote $PREP_WRAP (original left at $PREP)"
fi

echo "----- full-path dpkg --version -----"
# Never put JBROOT first on PATH for this test
export PATH="/usr/bin:/bin:/usr/sbin:/sbin"
out="$("$DPKG" --version 2>&1)"
rc=$?
echo "$out" | head -5
echo "dpkg_exit=$rc"

if [[ "$rc" -eq 0 ]] && echo "$out" | grep -qi 'dpkg'; then
  echo "OK: dpkg runs at $DPKG"
  exit 0
fi

echo "FAIL: dpkg did not run (rc=$rc) — likely AMFI still killing or /var/jb map incomplete"
ls -la /var/jb/usr/lib 2>&1 | head -10
ldid -e "$DPKG" 2>&1 | head -20
ldid -h "$DPKG" 2>&1 | head -15
exit 1
