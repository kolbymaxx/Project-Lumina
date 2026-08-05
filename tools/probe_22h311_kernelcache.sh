#!/usr/bin/env bash
# Offline RO probes for 22H311 kernelcache (Fork 1 mapping — not an exploit).
# Writes text under artifacts/xr-18.7.5/kernelcache-ro/
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="${ROOT}/artifacts/xr-18.7.5/kernelcache-ro"
# Defaults match research/kexploit/22H311_NOTES.md (Mac paths)
KC_DIR="${KERNELCACHE_DIR:-/Users/kolby/Projects/firmware-22H311}"
IM4P="${KC_DIR}/kernelcache.release.iphone11b"
PAYLOAD="${KC_DIR}/kernelcache.payload"
DRY_RUN=0

usage() {
  cat <<EOF
Usage: $0 [--dry-run] [--dir DIR]

  --dry-run   Print planned commands; do not require files or write probes
  --dir DIR   Directory containing kernelcache.release.iphone11b + kernelcache.payload
              (default: \$KERNELCACHE_DIR or ${KC_DIR})

Output directory: ${OUT}
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run) DRY_RUN=1; shift ;;
    --dir) KC_DIR="$2"; IM4P="${KC_DIR}/kernelcache.release.iphone11b"; PAYLOAD="${KC_DIR}/kernelcache.payload"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "error: unknown arg: $1" >&2; usage; exit 2 ;;
  esac
done

run_or_show() {
  local out="$1"; shift
  echo "+ $* > ${out}"
  if [[ "${DRY_RUN}" -eq 0 ]]; then
    # shellcheck disable=SC2086
    "$@" >"${out}" 2>&1 || true
  fi
}

echo "=== probe_22h311_kernelcache ==="
echo "ROOT=${ROOT}"
echo "KC_DIR=${KC_DIR}"
echo "IM4P=${IM4P}"
echo "PAYLOAD=${PAYLOAD}"
echo "OUT=${OUT}"
echo "DRY_RUN=${DRY_RUN}"
echo

mkdir -p "${OUT}"

MISSING=0
for f in "${IM4P}" "${PAYLOAD}"; do
  if [[ ! -f "${f}" ]]; then
    echo "MISSING: ${f}"
    MISSING=1
  else
    echo "FOUND:   ${f} ($(wc -c <"${f}" | tr -d ' ') bytes)"
  fi
done

if [[ "${DRY_RUN}" -eq 1 ]]; then
  echo
  echo "=== dry-run command plan (P1–P6) ==="
  cat <<EOF
# P1 — Mach-O / fileset header
file ${PAYLOAD} > ${OUT}/P1_file.txt
otool -hv ${PAYLOAD} | head -40 > ${OUT}/P1_otool_header.txt

# P2 — fileset / load-command names
otool -l ${PAYLOAD} | rg -n "filetype|name |LC_FILESET_ENTRY|segname" | head -80 > ${OUT}/P2_fileset.txt

# P3 — build / Darwin identity
strings ${PAYLOAD} | rg -n "Darwin Kernel|root:xnu-|22H311|RELEASE_ARM64|T8020|iPhone11" | sort -u | head -40 > ${OUT}/P3_identity.txt

# P4 — mitigation-related strings
strings ${PAYLOAD} | rg -i "amfi|ppl_|PAC|sandbox|cs_blob|library.?valid|ApplePMP|SPTM|TXM" | sort -u | head -60 > ${OUT}/P4_mitigations.txt

# P5 — SHA-256 inventory
shasum -a 256 ${IM4P} ${PAYLOAD} > ${OUT}/P5_sha256.txt
ls -la ${IM4P} ${PAYLOAD} > ${OUT}/P5_ls.txt

# P6 — watch-class string survey (OOB-write / auth→root literature watch only — not a CVE claim)
strings ${PAYLOAD} | rg -i "oob|out.of.bounds|authorization|priv(ilege)?|kernel.*(read|write)|copyin|copyout|vnode|vfs|cluster_(read|write)" | sort -u | head -80 > ${OUT}/P6_watch_classes.txt
EOF
  echo
  if [[ "${MISSING}" -eq 1 ]]; then
    echo "dry-run complete; input files MISSING on this machine."
    echo "Place files on disk (Mac), then re-run without --dry-run."
    exit 0
  fi
  echo "dry-run complete; inputs present — re-run without --dry-run to write outputs."
  exit 0
fi

if [[ "${MISSING}" -eq 1 ]]; then
  cat >"${OUT}/MISSING_PATHS.txt" <<EOF
# Generated $(date -u +%Y-%m-%dT%H:%MZ) — probe aborted; no fabricated P1–P6 content.
# Place these files, then re-run:
#   ./tools/probe_22h311_kernelcache.sh
# Or:
#   KERNELCACHE_DIR=/path/to/dir ./tools/probe_22h311_kernelcache.sh

REQUIRED:
  ${IM4P}
  ${PAYLOAD}

Also documented in research/kexploit/22H311_NOTES.md
EOF
  echo
  echo "error: required kernelcache files missing — wrote ${OUT}/MISSING_PATHS.txt"
  echo "No P1–P6 probe content invented."
  exit 1
fi

# Live probes
run_or_show "${OUT}/P1_file.txt" file "${PAYLOAD}"
run_or_show "${OUT}/P1_otool_header.txt" bash -c "otool -hv \"${PAYLOAD}\" | head -40"
run_or_show "${OUT}/P2_fileset.txt" bash -c "otool -l \"${PAYLOAD}\" | rg -n \"filetype|name |LC_FILESET_ENTRY|segname\" | head -80"
run_or_show "${OUT}/P3_identity.txt" bash -c "strings \"${PAYLOAD}\" | rg -n \"Darwin Kernel|root:xnu-|22H311|RELEASE_ARM64|T8020|iPhone11\" | sort -u | head -40"
run_or_show "${OUT}/P4_mitigations.txt" bash -c "strings \"${PAYLOAD}\" | rg -i \"amfi|ppl_|PAC|sandbox|cs_blob|library.?valid|ApplePMP|SPTM|TXM\" | sort -u | head -60"
run_or_show "${OUT}/P5_sha256.txt" shasum -a 256 "${IM4P}" "${PAYLOAD}"
run_or_show "${OUT}/P5_ls.txt" ls -la "${IM4P}" "${PAYLOAD}"
run_or_show "${OUT}/P6_watch_classes.txt" bash -c "strings \"${PAYLOAD}\" | rg -i \"oob|out.of.bounds|authorization|priv(ilege)?|kernel.*(read|write)|copyin|copyout|vnode|vfs|cluster_(read|write)\" | sort -u | head -80"

{
  echo "# probe_22h311_kernelcache run $(date -u +%Y-%m-%dT%H:%MZ)"
  echo "KC_DIR=${KC_DIR}"
  echo "IM4P=${IM4P}"
  echo "PAYLOAD=${PAYLOAD}"
  ls -la "${OUT}"/P*.txt 2>/dev/null || true
} >"${OUT}/RUN_META.txt"

echo
echo "Wrote probes under ${OUT}"
echo "Summarize into research/kexploit/22H311_NOTES.md — no CVE-working claims."
