#!/usr/bin/env bash
# End-to-end lab experiment after PWND (see LAB_AGENT_RULES.md).
#
# Requires env:
#   IBSS=/path/to/iBSS.raw
#   IBEC=/path/to/iBEC.raw
#
# Exit codes:
#   0  — pipeline finished (Data exit 76 is expected, not success)
#   1  — host/config error (missing IBSS/IBEC, tools, etc.)
#  10  — NEED_REPWN: device/SSH/ramdisk phase failed hard
#  76  — Data probe reported expected exit 76 (propagated; not Data success)
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=lib_ctl.sh
source "${ROOT}/scripts/lib_ctl.sh"

LOGDIR="${ROOT}/logs"
mkdir -p "$LOGDIR"
STAMP="$(date +%Y%m%d-%H%M%S)"
LOG="${LOGDIR}/05_run_experiment-${STAMP}.log"
SUMMARY="${LOGDIR}/last_run.md"
PYTHON="${PYTHON:-python3}"

RC_01=""
RC_02=""
RC_03=""
RC_04=""
PHASE="init"
NEED_REPWN=0
REPWN_WHAT=""
REPWN_EVIDENCE=""
FINAL_RC=0

log() { echo "$@" | tee -a "$LOG"; }

need_repwn() {
  # $1 what  $2 evidence
  NEED_REPWN=1
  REPWN_WHAT="$1"
  REPWN_EVIDENCE="$2"
  FINAL_RC=10
}

write_summary() {
  local status="OK"
  if [[ "$NEED_REPWN" -eq 1 ]]; then
    status="NEED_REPWN"
  elif [[ "${RC_04:-}" == "76" ]]; then
    status="OK_DATA_EXPECTED_FAIL_76"
  elif [[ "$FINAL_RC" -ne 0 ]]; then
    status="FAIL"
  fi

  cat >"$SUMMARY" <<EOF
# last_run — ${STAMP}

| Field | Value |
|-------|-------|
| Status | ${status} |
| Final rc | ${FINAL_RC} |
| Log | \`${LOG}\` |
| Phase reached | ${PHASE} |
| IBSS | \`${IBSS:-}\` |
| IBEC | \`${IBEC:-}\` |
| 01_wait_pwned rc | ${RC_01:-n/a} |
| 02_boot_chain rc | ${RC_02:-n/a} |
| 03_ramdisk_ssh rc | ${RC_03:-n/a} |
| 04_data_mount_probe rc | ${RC_04:-n/a} |

## Notes
- Data mount exit **76** on 15.1 ramdisk is **expected** (not success).
- No DYLD_LIBRARY_PATH hacks for Data.
- See \`LAB_AGENT_RULES.md\`.

EOF

  if [[ "$NEED_REPWN" -eq 1 ]]; then
    cat >>"$SUMMARY" <<EOF
## Need re-pwn
**What failed:** ${REPWN_WHAT}
**Evidence:** ${REPWN_EVIDENCE}
**Next theory after I re-pwn:** Re-enter PWND DFU, re-run \`scripts/05_run_experiment.sh\` with same IBSS/IBEC; if SSH died after bootx, verify direct Mac cable and payload paths.
**Commands you will run first after PWND:**
\`\`\`bash
cd ~/Projects/lumina
export IBSS="${IBSS:-}"
export IBEC="${IBEC:-}"
./scripts/05_run_experiment.sh
\`\`\`
EOF
  fi

  log "Summary: $SUMMARY"
}

print_need_repwn() {
  cat <<EOF

## Need re-pwn
**What failed:** ${REPWN_WHAT}
**Evidence:** ${REPWN_EVIDENCE}
**Next theory after I re-pwn:** Re-enter PWND DFU, re-run scripts/05_run_experiment.sh with same IBSS/IBEC; confirm direct Mac cable (not through Pico).
**Commands you will run first after PWND:**
\`\`\`bash
cd ~/Projects/lumina
export IBSS="${IBSS:-}"
export IBEC="${IBEC:-}"
./scripts/05_run_experiment.sh
\`\`\`
EOF
}

log "05_run_experiment — $STAMP"
log "ROOT=$ROOT"
log "platform=$(uname -s 2>/dev/null || echo unknown)"

if [[ -z "${IBSS:-}" || -z "${IBEC:-}" ]]; then
  log "FAIL: IBSS and IBEC env vars are required"
  log "Example:"
  log "  export IBSS=\"\$HOME/Projects/usbliter8-xr-ramdisk/payload/iBSS.raw\""
  log "  export IBEC=\"\$HOME/Projects/usbliter8-xr-ramdisk/payload/iBEC.raw\""
  FINAL_RC=1
  PHASE="config"
  write_summary
  exit 1
fi

if [[ ! -f "$IBSS" ]]; then
  log "FAIL: IBSS not a file: $IBSS"
  FINAL_RC=1
  PHASE="config"
  write_summary
  exit 1
fi
if [[ ! -f "$IBEC" ]]; then
  log "FAIL: IBEC not a file: $IBEC"
  FINAL_RC=1
  PHASE="config"
  write_summary
  exit 1
fi

CTL="$(find_usbliter8ctl)" || {
  FINAL_RC=1
  PHASE="config"
  write_summary
  exit 1
}
log "ctl=$CTL"
log "IBSS=$IBSS"
log "IBEC=$IBEC"

# --- 1) wait pwned ---
PHASE="01_wait_pwned"
log "### $PYTHON ${ROOT}/scripts/01_wait_pwned.py"
set +e
"$PYTHON" "${ROOT}/scripts/01_wait_pwned.py" 2>&1 | tee -a "$LOG"
RC_01=${PIPESTATUS[0]}
set -e
log "01 rc=$RC_01"
if [[ "$RC_01" -ne 0 ]]; then
  need_repwn "01_wait_pwned did not see PWND:[usbliter8] DFU" "01 rc=$RC_01 (no 05ac:1227 Pwned DFU within timeout)"
  write_summary
  print_need_repwn
  exit 10
fi

# --- 2) boot chain ---
PHASE="02_boot_chain"
log "### $PYTHON ${ROOT}/scripts/02_boot_chain.py --ibss \$IBSS --ibec \$IBEC"
set +e
"$PYTHON" "${ROOT}/scripts/02_boot_chain.py" --ibss "$IBSS" --ibec "$IBEC" 2>&1 | tee -a "$LOG"
RC_02=${PIPESTATUS[0]}
set -e
log "02 rc=$RC_02"
if [[ "$RC_02" -ne 0 ]]; then
  need_repwn "02_boot_chain failed (iBSS/Recovery/iBEC)" "02 rc=$RC_02 — check logs for missing 05ac:1281 or iBEC send failure"
  write_summary
  print_need_repwn
  exit 10
fi

# --- 3/4) ramdisk SSH + Data probe (if iproxy available) ---
if ! command -v iproxy >/dev/null 2>&1; then
  log "NOTE: iproxy not found — skipping 03/04 (Mac: brew install libimobiledevice usbmuxd)"
  PHASE="skipped_ssh"
  FINAL_RC=0
  write_summary
  exit 0
fi

PHASE="03_ramdisk_ssh"
log "### ${ROOT}/scripts/03_ramdisk_ssh.sh"
log "NOTE: 02 stops after iBEC; full ramdisk may still need ./boot/lumina-boot.sh if usbmux is empty."
set +e
bash "${ROOT}/scripts/03_ramdisk_ssh.sh" 2>&1 | tee -a "$LOG"
RC_03=${PIPESTATUS[0]}
set -e
log "03 rc=$RC_03"
if [[ "$RC_03" -ne 0 ]]; then
  # Only NEED_REPWN if the live USB/SSH device is actually gone — not if still in Recovery.
  set +e
  INFO_OUT="$("$PYTHON" "$CTL" info 2>&1)"
  INFO_RC=$?
  ID_OUT="$(idevice_id -l 2>&1)"
  set -e
  log "post-03 usbliter8ctl info rc=$INFO_RC"
  log "$INFO_OUT"
  log "idevice_id: $ID_OUT"

  if echo "$INFO_OUT" | grep -qE '05ac:1227|05ac:1281|Pwned DFU|Recovery'; then
    log "FAIL: ramdisk SSH not up, but DFU/Recovery still present — NOT asking for re-pwn"
    log "Next: finish ramdisk (e.g. ./boot/lumina-boot.sh from PWND, or continue irecovery chain), then re-run 03/04"
    FINAL_RC=1
    PHASE="03_ramdisk_not_up_device_present"
    write_summary
    exit 1
  fi

  if [[ -n "${ID_OUT//[$'\n']/}" ]]; then
    log "FAIL: usbmux device listed but SSH report failed — check iproxy/password; NOT re-pwn yet"
    FINAL_RC=1
    PHASE="03_ssh_failed_usbmux_present"
    write_summary
    exit 1
  fi

  need_repwn "03_ramdisk_ssh failed and no DFU/Recovery/usbmux" "03 rc=$RC_03; usbliter8ctl info/idevice_id empty — device likely back to iOS or unplugged"
  write_summary
  print_need_repwn
  exit 10
fi

PHASE="04_data_mount_probe"
log "### ${ROOT}/scripts/04_data_mount_probe.sh"
set +e
bash "${ROOT}/scripts/04_data_mount_probe.sh" 2>&1 | tee -a "$LOG"
RC_04=${PIPESTATUS[0]}
set -e
log "04 rc=$RC_04"

# 76 = expected Data failure on 15.1 — not NEED_REPWN, not Data success
if [[ "$RC_04" -eq 76 ]]; then
  log "NOTE: Data mount exit 76 expected on 15.1 — documented, NOT success, NOT re-pwn"
  FINAL_RC=76
  write_summary
  exit 76
fi

if [[ "$RC_04" -eq 0 ]]; then
  log "NOTE: 04 returned 0 (unexpected Data mount?) — re-verify before claiming; not treating as NEED_REPWN"
  FINAL_RC=0
  write_summary
  exit 0
fi

# Other 04 failures that look like SSH/device loss
if [[ "$RC_04" -eq 1 || "$RC_04" -eq 255 ]]; then
  need_repwn "04_data_mount_probe lost SSH / device" "04 rc=$RC_04 after successful 03 — device may have dropped"
  write_summary
  print_need_repwn
  exit 10
fi

log "04 other rc=$RC_04 — not treated as Data success"
FINAL_RC="$RC_04"
write_summary
exit "$FINAL_RC"
