# shellcheck shell=bash
# Resolve USBLITER8CTL relative to package root.

lab_root() {
  cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd
}

find_usbliter8ctl() {
  local root
  root="$(lab_root)"
  if [[ -n "${USBLITER8CTL:-}" && -f "${USBLITER8CTL}" ]]; then
    echo "${USBLITER8CTL}"
    return 0
  fi
  local c
  for c in \
    "${root}/host/usbliter8ctl" \
    "${root}/usbliter8ctl" \
    "${root}/../usbliter8/usbliter8ctl" \
    "${root}/../usbliter8-jailbreak/host/usbliter8ctl"; do
    if [[ -f "$c" ]]; then
      echo "$(cd "$(dirname "$c")" && pwd)/$(basename "$c")"
      return 0
    fi
  done
  echo "FAIL: usbliter8ctl not found. Set USBLITER8CTL or place at host/usbliter8ctl" >&2
  echo "Tried: host/usbliter8ctl, ./usbliter8ctl, ../usbliter8/usbliter8ctl, ../usbliter8-jailbreak/host/usbliter8ctl" >&2
  return 1
}
