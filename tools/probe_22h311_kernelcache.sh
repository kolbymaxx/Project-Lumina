#!/usr/bin/env bash
# RO inventory probes for iOS 18.7.5 (22H311) kernelcache on the research Mac.
# Docs / identity only — not a kexploit.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="${ROOT}/artifacts/xr-18.7.5/kernelcache-ro"
KC_DIR="${FIRMWARE_22H311_DIR:-/Users/kolby/Projects/firmware-22H311}"
IM4P="${KC_DIR}/kernelcache.release.iphone11b"
PAYLOAD="${KC_DIR}/kernelcache.payload"

mkdir -p "${OUT}"
STAMP="$(date -u +%Y%m%dT%H%M%SZ)"
LOG="${OUT}/probe-${STAMP}.log"

log() { printf '%s\n' "$*" | tee -a "${LOG}"; }

log "=== probe_22h311_kernelcache ${STAMP} ==="
log "repo=${ROOT}"
log "kc_dir=${KC_DIR}"

if [[ ! -f "${PAYLOAD}" ]]; then
  log "ERROR: missing payload: ${PAYLOAD}"
  log "Extract with pyimg4 from ${IM4P} first (see research/kexploit/MAC_RO_RUNBOOK.md)."
  exit 1
fi

need() {
  if ! command -v "$1" >/dev/null 2>&1; then
    log "ERROR: missing tool: $1"
    exit 1
  fi
}
need file
need otool
need strings
need shasum
need rg

run_probe() {
  local name="$1"; shift
  local dest="${OUT}/${name}.txt"
  log "--- ${name} ---"
  {
    echo "# ${name} @ ${STAMP}"
    echo "# cwd=$(pwd)"
    echo
    "$@"
  } >"${dest}" 2>&1 || true
  log "wrote ${dest} ($(wc -l <"${dest}" | tr -d ' ') lines)"
}

run_probe p1-file-otool bash -c "
file '${PAYLOAD}'
echo
otool -hv '${PAYLOAD}' | head -40
"

run_probe p2-fileset bash -c "
otool -l '${PAYLOAD}' | rg -n 'filetype|name |LC_FILESET_ENTRY|segname' | head -120
"

run_probe p3-identity bash -c "
strings '${PAYLOAD}' | rg -n 'Darwin Kernel|root:xnu-|22H311|RELEASE_ARM64|T8020|iPhone11' | sort -u | head -40
"

run_probe p4-mitigations bash -c "
strings '${PAYLOAD}' | rg -i 'amfi|ppl_|PAC|sandbox|cs_blob|library.?valid|ApplePMP|SPTM|TXM|trust.?cache' | sort -u | head -80
"

run_probe p5-sha256 bash -c "
shasum -a 256 '${IM4P}' '${PAYLOAD}' 2>/dev/null || shasum -a 256 '${PAYLOAD}'
ls -la '${IM4P}' '${PAYLOAD}' 2>/dev/null || ls -la '${PAYLOAD}'
"

run_probe p6-fork1-keywords bash -c "
strings '${PAYLOAD}' | rg -i 'IOKit|externalMethod|authorization|cred|sandbox|vnode|VFS|copyin|copyout|oob|bounds' | sort -u | head -100
"

log "=== done ==="
log "Summarize into research/kexploit/22H311_NOTES.md (hashes + identity)."
log "Do not invent offsets. Do not wire into boot/."
