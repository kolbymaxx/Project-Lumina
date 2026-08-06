#!/usr/bin/env bash
# Offline RO presence probe for 22H311 kernelcache (Fork 1).
# Not an exploit. No device. No boot/ wiring. No primitive claims.
#
# Usage:
#   ./tools/probe_22h311_kernelcache.sh [KERNEL]
# Default KERNEL:
#   /Users/kolby/Projects/firmware-22H311/kernelcache.payload
set -euo pipefail
set +o pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
KERNEL="${1:-/Users/kolby/Projects/firmware-22H311/kernelcache.payload}"
OUT_DIR="${OUT_DIR:-${REPO_ROOT}/artifacts/xr-18.7.5/kernelcache-ro}"
NOTES="${REPO_ROOT}/research/kexploit/22H311_NOTES.md"
DATE_UTC="$(date -u +%Y-%m-%d)"
STAMP="$(date -u +%Y-%m-%dT%H%MZ)"

if [[ ! -f "$KERNEL" ]]; then
  echo "MISSING: $KERNEL" >&2
  exit 1
fi

mkdir -p "$OUT_DIR"
REPORT="$OUT_DIR/probe_report_${DATE_UTC}.txt"
HITMISS="$OUT_DIR/P_surface_hitmiss_${DATE_UTC}.txt"

{
  echo "=== probe_22h311_kernelcache.sh @ $STAMP ==="
  echo "KERNEL=$KERNEL"
  echo
  echo "--- file / size ---"
  file "$KERNEL"
  ls -la "$KERNEL"
  echo
  echo "--- mach-o header (otool -hv) ---"
  if command -v otool >/dev/null 2>&1; then
    otool -hv "$KERNEL" | head -20
  else
    echo "otool: not found"
  fi
  if command -v llvm-objdump >/dev/null 2>&1; then
    echo
    echo "--- llvm-objdump --macho --private-header (head) ---"
    llvm-objdump --macho --private-header "$KERNEL" 2>/dev/null | head -30 || true
  else
    echo "llvm-objdump: not found (skipped)"
  fi
  echo
  echo "--- identity strings (sample) ---"
  strings "$KERNEL" | rg -e 'Darwin Kernel Version' -e 'root:xnu-' -e 'RELEASE_ARM64_T8020' -e '22H311' -e 'iPhone11' | sort -u | head -20
} | tee "$REPORT"

# Fixed presence list — logging only. Hit ≠ CVE surface / exploitability.
# T008/T009 have no public named component yet; scan advisory title words +
# common iOS 18 surfaces for corpus inventory only.
PATTERNS=(
  'AppleImage4'
  'AppleMobileFileIntegrity'
  'AMFI'
  'amfid'
  'sandbox'
  'Seatbelt'
  'necp'
  'NECP'
  'bpf'
  'BPF'
  'IOSurface'
  'packet'
  'Packet'
  'out-of-bounds'
  'out of bounds'
  'authorization'
  'Authorization'
  'CVE-2026-28972'
  'CVE-2026-28951'
  '28972'
  '28951'
)

echo | tee -a "$REPORT"
echo "--- surface presence (hit/miss) ---" | tee -a "$REPORT"
: > "$HITMISS"
hits=0
misses=0
for pat in "${PATTERNS[@]}"; do
  # count matching distinct strings (cap work)
  n=$(strings "$KERNEL" | rg -F -c -- "$pat" 2>/dev/null || true)
  if [[ -z "$n" ]]; then n=0; fi
  if [[ "$n" -gt 0 ]]; then
    status="HIT"
    hits=$((hits + 1))
  else
    status="MISS"
    misses=$((misses + 1))
  fi
  line=$(printf '%-28s %s  (string_lines≈%s)' "$pat" "$status" "$n")
  echo "$line" | tee -a "$REPORT" | tee -a "$HITMISS"
done
echo "totals: HIT=$hits MISS=$misses (presence only)" | tee -a "$REPORT"

# Sample lines for a few high-signal hits (truncated)
{
  echo
  echo "--- sample hits (truncated) ---"
  for pat in AppleImage4 AMFI sandbox necp IOSurface 'out of bounds' authorization; do
    echo "## $pat"
    strings "$KERNEL" | rg -F -- "$pat" | sort -u | head -8 || true
    echo
  done
} | tee -a "$REPORT" | tee "$OUT_DIR/P_surface_samples_${DATE_UTC}.txt"

# Append dated section to notes
mkdir -p "$(dirname "$NOTES")"
if [[ ! -f "$NOTES" ]]; then
  printf '# 22H311 offline kernel artifact notes\n\n' > "$NOTES"
fi

# Remove prior same-day auto section if re-run
if rg -q "^## Offline probe \(auto\) — ${DATE_UTC}" "$NOTES" 2>/dev/null; then
  # strip from that heading through next ## Offline probe or EOF-safe: rewrite without that block
  python3 - "$NOTES" "$DATE_UTC" <<'PY'
import pathlib, sys
notes, day = pathlib.Path(sys.argv[1]), sys.argv[2]
text = notes.read_text()
start = f"## Offline probe (auto) — {day}"
if start not in text:
    raise SystemExit(0)
i = text.index(start)
j = text.find("\n## Offline probe (auto) — ", i + 1)
if j < 0:
    # also stop before "## Live ramdisk" if that's next major section after ours — keep rest
    # delete through end of file only if nothing else; prefer cut to next ## at column 0 after start+1
    k = text.find("\n## ", i + len(start))
    j = k if k >= 0 else len(text)
notes.write_text(text[:i].rstrip() + "\n\n" + text[j:].lstrip() if j < len(text) else text[:i].rstrip() + "\n")
PY
fi

{
  echo "## Offline probe (auto) — ${DATE_UTC}"
  echo
  echo "**Tool:** \`tools/probe_22h311_kernelcache.sh\`  "
  echo "**Kernel:** \`$KERNEL\`  "
  echo "**Artifacts:** \`artifacts/xr-18.7.5/kernelcache-ro/probe_report_${DATE_UTC}.txt\`"
  echo
  echo "### Header"
  echo '```'
  file "$KERNEL"
  ls -la "$KERNEL" | awk '{print}'
  if command -v otool >/dev/null 2>&1; then
    otool -hv "$KERNEL" | head -6
  fi
  echo '```'
  echo
  echo "### Presence scan (hit/miss)"
  echo
  echo "Fixed string list only. **HIT = substring present in \`strings\` output.**"
  echo "Not a CVE pin. T008/T009 remain watch-only (no public named surface)."
  echo
  echo '```'
  cat "$HITMISS"
  echo "totals: HIT=$hits MISS=$misses"
  echo '```'
  echo
  echo "### Explicit non-claims"
  echo
  echo "- No claim that any CVE is working on this device / build."
  echo "- No claim of a kernel primitive, PoC, or exploitability."
  echo "- Presence of AMFI/sandbox/necp/IOSurface/etc. is expected inventory noise on iOS 18."
  echo "- Advisory CVE id strings are expected **MISS** unless embedded in the binary."
  echo
} >> "$NOTES"

echo
echo "Updated notes: $NOTES"
echo "Report: $REPORT"
