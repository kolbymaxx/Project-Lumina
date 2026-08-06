#!/usr/bin/env bash
# Read-only 22H311 kernelcache probes (Fork 1 offline RE prep).
# Not an exploit. No device interaction. No boot/ changes.
set -euo pipefail
# head(1) closing early must not abort the script (SIGPIPE → 141)
set +o pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
KC_DIR="${KC_DIR:-/Users/kolby/Projects/firmware-22H311}"
IM4P="${KC_DIR}/kernelcache.release.iphone11b"
PAYLOAD="${KC_DIR}/kernelcache.payload"
OUT_DIR="${OUT_DIR:-${REPO_ROOT}/artifacts/xr-18.7.5/kernelcache-ro}"
DRY_RUN="${DRY_RUN:-0}"

run() {
  if [[ "$DRY_RUN" == "1" ]]; then
    printf '+ %s\n' "$*"
    return 0
  fi
  eval "$@"
  return 0
}

echo "IM4P:    $IM4P"
echo "PAYLOAD: $PAYLOAD"
echo "OUT_DIR: $OUT_DIR"
echo "DRY_RUN: $DRY_RUN"

missing=0
for f in "$IM4P" "$PAYLOAD"; do
  if [[ ! -f "$f" ]]; then
    echo "MISSING: $f" >&2
    missing=1
  fi
done
if [[ "$missing" -ne 0 ]]; then
  echo "Place the files above on disk, then re-run." >&2
  echo "Restore recipe: research/kexploit/22H311_NOTES.md" >&2
  exit 1
fi

if [[ "$DRY_RUN" != "1" ]]; then
  mkdir -p "$OUT_DIR"
fi

# P1 — Mach-O / fileset header
run "file \"$PAYLOAD\" | tee \"$OUT_DIR/P1_file.txt\""
run "otool -hv \"$PAYLOAD\" | head -40 | tee \"$OUT_DIR/P1_otool_hv.txt\""

# P2 — Fileset load commands + extracted entry names
run "otool -l \"$PAYLOAD\" | rg -n \"LC_FILESET_ENTRY|^\s+entry |^\s+filetype |^\s+segname \" | head -120 | tee \"$OUT_DIR/P2_fileset.txt\""
# LC_FILESET_ENTRY uses entry_id (otool); LC_REQ_DYLD bit set on cmd
run "otool -l \"$PAYLOAD\" | rg 'entry_id ' | sed 's/.*entry_id //;s/ (offset.*//' | tee \"$OUT_DIR/P2_fileset_names.txt\""

# P3 — Darwin / build identity strings (tight)
run "strings \"$PAYLOAD\" | rg -e \"Darwin Kernel Version\" -e \"root:xnu-\" -e \"RELEASE_ARM64_T8020\" -e \"22H311\" -e \"iPhone11,8\" | sort -u | head -40 | tee \"$OUT_DIR/P3_identity.txt\""

# P4 — Mitigation-related string survey (names only; avoid 'packet' false hits on PAC)
run "strings \"$PAYLOAD\" | rg -e \"amfi\" -e \"AMFI\" -e \"ppl_\" -e \"__PPL\" -e \"pac_exception\" -e \"FEAT_PAC\" -e \"cs_blob\" -e \"sandbox\" -e \"library_validation\" -e \"SPTM\" -e \"TXM\" -e \"trust_cache\" -e \"trustcache\" -e \"launch_constraints\" | sort -u | head -80 | tee \"$OUT_DIR/P4_mitigations.txt\""

# P5 — SHA-256 inventory
run "{
  shasum -a 256 \"$IM4P\" \"$PAYLOAD\"
  ls -la \"$IM4P\" \"$PAYLOAD\"
} | tee \"$OUT_DIR/P5_sha256.txt\""

# P6 — Watch-class string survey (OOB-write / auth→root study surface only)
# Presence of subsystem names ≠ CVE applicability or a working exploit.
run "strings \"$PAYLOAD\" | rg -e \"copyin\" -e \"copyout\" -e \"out of bounds\" -e \"out-of-bounds\" -e \"authorization\" -e \"priv_check\" -e \"suser\" -e \"kauth\" -e \"IOUserClient\" -e \"externalMethod\" -e \"ZONE_\" -e \"zalloc\" -e \"kalloc_type\" -e \"kalloc\" | sort -u | head -80 | tee \"$OUT_DIR/P6_watch_surface.txt\""
# P6b — narrower sample for T008/T009 watch mapping (still presence-only)
run "{
  echo '=== PPL / PAC / launch_constraints / trustcache (sample) ==='
  strings \"$PAYLOAD\" | rg -e '__PPL' -e 'ppl_trampoline' -e 'pmap_ppl' -e 'pac_exception' -e 'FEAT_PAC' -e 'launch_constraints' -e 'LaunchConstraint' -e 'trust_cache_init' -e 'isCdhashInTrustCache' -e 'loadTrustCache' -e 'com.apple.private.amfi' | sort -u | head -60
  echo
  echo '=== auth / IOUserClient / copyin-copyout (sample) ==='
  strings \"$PAYLOAD\" | rg -e 'authorization' -e 'IOUserClient::' -e 'externalMethod' -e 'copyin' -e 'copyout' -e 'out-of-bounds' -e 'out of bounds' | sort -u | head -40
} | tee \"$OUT_DIR/P6b_targeted_watch.txt\""

echo "Done. Outputs under: $OUT_DIR"
ls -la "$OUT_DIR"
