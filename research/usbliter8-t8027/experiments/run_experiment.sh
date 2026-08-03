#!/usr/bin/env bash
# READY-gated single live experiment for t8027 research.
# No loops. No host payload send. Defaults to dry-run.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
T8027_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
CAND_DIR="${SCRIPT_DIR}/candidates"
LOG_DIR="${SCRIPT_DIR}/logs"
LIVE_SESSION="${T8027_DIR}/LIVE_SESSION.md"

usage() {
  cat <<'EOF'
Usage: run_experiment.sh <candidate-id>

  candidate-id   e.g. C001

Aborts unless the candidate Status field is exactly READY.
Supported Action values: dry-run (default), manual_pico.
Does not call usbliter8ctl demote/boot/send.
EOF
}

die() {
  echo "error: $*" >&2
  exit 1
}

# --- args -------------------------------------------------------------------
[[ $# -ge 1 ]] || { usage >&2; exit 2; }
CID_RAW="$1"
[[ "${CID_RAW}" =~ ^[Cc][0-9]{3}$ ]] || die "candidate id must look like C001 (got: ${CID_RAW})"
CID="$(printf 'C%03d' "$((10#${CID_RAW:1}))")"

# --- resolve repo root / tools ----------------------------------------------
resolve_repo_root() {
  if [[ -n "${LUMINA_REPO_ROOT:-}" ]]; then
    printf '%s' "${LUMINA_REPO_ROOT}"
    return
  fi
  local d="${SCRIPT_DIR}"
  while [[ "${d}" != "/" ]]; do
    if [[ -f "${d}/usbliter8ctl" ]]; then
      printf '%s' "${d}"
      return
    fi
    d="$(dirname "${d}")"
  done
  die "could not find repo root (usbliter8ctl); set LUMINA_REPO_ROOT"
}

REPO_ROOT="$(resolve_repo_root)"
CTL="${LUMINA_USBLITER8CTL:-${REPO_ROOT}/usbliter8ctl}"
[[ -f "${CTL}" ]] || die "usbliter8ctl not found: ${CTL}"
command -v irecovery >/dev/null || die "irecovery not on PATH"
command -v python3 >/dev/null || die "python3 not on PATH"

# --- locate candidate -------------------------------------------------------
shopt -s nullglob
matches=("${CAND_DIR}/${CID}"-*.md)
shopt -u nullglob
[[ ${#matches[@]} -eq 1 ]] || die "expected exactly one ${CID}-*.md under ${CAND_DIR} (found ${#matches[@]})"
CAND_FILE="${matches[0]}"
CAND_BASE="$(basename "${CAND_FILE}")"

# Extract a markdown ## section body (until next ## or EOF), trim edges.
md_section() {
  local file="$1" heading="$2"
  awk -v h="${heading}" '
    BEGIN { pat="^##[[:space:]]+" h "[[:space:]]*$"; grab=0 }
    $0 ~ pat { grab=1; next }
    grab && /^##[[:space:]]+/ { exit }
    grab { print }
  ' "${file}" | sed -e '1{/^[[:space:]]*$/d;}' -e '${/^[[:space:]]*$/d;}'
}

# First non-empty, non-HTML-comment line of a section → single token field.
md_field_line() {
  md_section "$1" "$2" | awk '
    /^[[:space:]]*$/ { next }
    /^[[:space:]]*<!--/ { next }
    { gsub(/^[[:space:]]+|[[:space:]]+$/, ""); print; exit }
  '
}

STATUS="$(md_field_line "${CAND_FILE}" "Status")"
ACTION="$(md_field_line "${CAND_FILE}" "Action")"
HYPOTHESIS="$(md_section "${CAND_FILE}" "Hypothesis" | awk 'NF{print; exit}')"
EXPECTED="$(md_section "${CAND_FILE}" "Expected observable" | awk 'NF && $0 !~ /^<!--/ {print; exit}')"

[[ -n "${STATUS}" ]] || die "missing ## Status in ${CAND_BASE}"
[[ "${STATUS}" == "READY" ]] || die "${CID} Status is '${STATUS}' (need READY). Refusing to run."

case "${ACTION}" in
  ""|"dry-run")
    ACTION="dry-run"
    ;;
  "manual_pico")
    ;;
  *)
    echo "warn: Action '${ACTION}' not explicitly supported; defaulting to dry-run" >&2
    ACTION="dry-run"
    ;;
esac

# --- bookkeeping ------------------------------------------------------------
mkdir -p "${LOG_DIR}"
TS_FILE="$(date +%Y%m%d-%H%M%S)"
TS_HUMAN="$(date '+%Y-%m-%d %H:%M %Z')"
HOST="$(hostname -s 2>/dev/null || hostname)"
LOG_FILE="${LOG_DIR}/${TS_FILE}-${CID}.log"
TITLE="$(sed -n '1s/^#[[:space:]]*//p' "${CAND_FILE}")"

if [[ -n "${LUMINA_CABLE_NOTES:-}" ]]; then
  CABLE_NOTES="${LUMINA_CABLE_NOTES}"
else
  if [[ -t 0 ]]; then
    read -r -p "Cable notes (path / direct-to-Mac / Pico in-path / length): " CABLE_NOTES
  else
    CABLE_NOTES="(not provided; non-interactive)"
  fi
fi
[[ -n "${CABLE_NOTES}" ]] || CABLE_NOTES="(none)"

# --- logging helpers --------------------------------------------------------
exec > >(tee -a "${LOG_FILE}") 2>&1

log_banner() {
  echo "================================================================"
  echo "$*"
  echo "================================================================"
}

run_capture() {
  # run_capture VARNAME cmd...
  local _var="$1"; shift
  local _out="" _rc=0
  set +e
  _out="$("$@" 2>&1)"
  _rc=$?
  set -e
  printf '%s\n' "${_out}"
  printf -v "${_var}" '%s' "${_out}"
  return "${_rc}"
}

extract_serial() {
  # Prefer usbliter8ctl "serial:" line; else irecovery CPID/ECID/SRTG rebuild.
  local text="$1"
  local s
  s="$(printf '%s\n' "${text}" | awk -F'serial:[[:space:]]*' '/serial:/{print $2; exit}')"
  if [[ -n "${s}" ]]; then
    printf '%s' "${s}"
    return
  fi
  # Fallback: leave empty
  printf ''
}

extract_irecovery_field() {
  local text="$1" key="$2"
  printf '%s\n' "${text}" | awk -F':[[:space:]]*' -v k="${key}" '
    $1 == k { sub(/^[^:]+:[[:space:]]*/, ""); print; exit }
  '
}

has_pwnd() {
  [[ "${1:-}" == *PWND:* ]]
}

classify_result() {
  # Sets CLASSIFICATION from pre/post capture vars + action_rc.
  local pre_info_rc="$1" post_info_rc="$2" action_rc="$3"
  local pre_serial="$4" post_serial="$5"
  local pre_mode="$6" post_mode="$7"
  local pre_prod="$8" post_prod="$9"

  if (( pre_info_rc != 0 )); then
    CLASSIFICATION="ERROR"
    CLASS_REASON="pre-check usbliter8ctl info failed (rc=${pre_info_rc})"
    return
  fi

  if (( action_rc != 0 )); then
    CLASSIFICATION="ERROR"
    CLASS_REASON="action phase failed (rc=${action_rc})"
    return
  fi

  if (( post_info_rc != 0 )) || [[ -z "${post_serial}" ]]; then
    # Device may have disappeared after a race attempt — that is an anomaly, not a tool bug,
    # unless pre also failed (handled above).
    CLASSIFICATION="USB_ANOMALY"
    CLASS_REASON="post-check: no DFU/Recovery serial (usbliter8ctl info rc=${post_info_rc})"
    return
  fi

  if has_pwnd "${post_serial}"; then
    CLASSIFICATION="PWND"
    CLASS_REASON="post serial contains PWND:"
    return
  fi

  # Identity / mode shifts without PWND
  local pre_core post_core
  pre_core="$(printf '%s' "${pre_serial}" | tr '[:lower:]' '[:upper:]')"
  post_core="$(printf '%s' "${post_serial}" | tr '[:lower:]' '[:upper:]')"

  if [[ -n "${pre_mode}" && -n "${post_mode}" && "${pre_mode}" != "${post_mode}" ]]; then
    CLASSIFICATION="USB_ANOMALY"
    CLASS_REASON="MODE ${pre_mode} → ${post_mode} without PWND"
    return
  fi

  # Compare CPID/ECID/SRTG tokens if both present
  local pre_cpid post_cpid pre_ecid post_ecid pre_srtg post_srtg
  pre_cpid="$(printf '%s' "${pre_serial}" | sed -n 's/.*CPID:\([^ ]*\).*/\1/p')"
  post_cpid="$(printf '%s' "${post_serial}" | sed -n 's/.*CPID:\([^ ]*\).*/\1/p')"
  pre_ecid="$(printf '%s' "${pre_serial}" | sed -n 's/.*ECID:\([^ ]*\).*/\1/p')"
  post_ecid="$(printf '%s' "${post_serial}" | sed -n 's/.*ECID:\([^ ]*\).*/\1/p')"
  pre_srtg="$(printf '%s' "${pre_serial}" | sed -n 's/.*SRTG:\(\[[^]]*\]\).*/\1/p')"
  post_srtg="$(printf '%s' "${post_serial}" | sed -n 's/.*SRTG:\(\[[^]]*\]\).*/\1/p')"

  if [[ -n "${pre_cpid}" && -n "${post_cpid}" && "${pre_cpid}" != "${post_cpid}" ]] \
    || [[ -n "${pre_ecid}" && -n "${post_ecid}" && "${pre_ecid}" != "${post_ecid}" ]] \
    || [[ -n "${pre_srtg}" && -n "${post_srtg}" && "${pre_srtg}" != "${post_srtg}" ]]; then
    CLASSIFICATION="USB_ANOMALY"
    CLASS_REASON="identity token change without PWND (CPID/ECID/SRTG)"
    return
  fi

  if [[ "${pre_core}" != "${post_core}" ]]; then
    CLASSIFICATION="USB_ANOMALY"
    CLASS_REASON="DFU serial string changed without PWND"
    return
  fi

  if [[ -n "${pre_prod}" && -n "${post_prod}" && "${pre_prod}" != "${post_prod}" ]]; then
    CLASSIFICATION="USB_ANOMALY"
    CLASS_REASON="PRODUCT ${pre_prod} → ${post_prod} without PWND"
    return
  fi

  CLASSIFICATION="NO_EFFECT"
  CLASS_REASON="still DFU; serial/identity unchanged; no PWND"
}

# --- header -----------------------------------------------------------------
log_banner "t8027 experiment ${CID}"
echo "timestamp:   ${TS_HUMAN}"
echo "host:        ${HOST}"
echo "repo:        ${REPO_ROOT}"
echo "candidate:   ${CAND_FILE}"
echo "title:       ${TITLE}"
echo "status:      ${STATUS} (gate passed)"
echo "action:      ${ACTION}"
echo "cable:       ${CABLE_NOTES}"
echo "hypothesis:  ${HYPOTHESIS:-"(empty)"}"
echo "expected:    ${EXPECTED:-"(empty)"}"
echo "log:         ${LOG_FILE}"
echo

# --- pre-check --------------------------------------------------------------
log_banner "PRE-CHECK"
PRE_INFO=""
PRE_IREC=""
PRE_INFO_RC=0
PRE_IREC_RC=0

echo "\$ python3 ${CTL} info"
run_capture PRE_INFO python3 "${CTL}" info || PRE_INFO_RC=$?
echo "(rc=${PRE_INFO_RC})"
echo

echo "\$ irecovery -q"
run_capture PRE_IREC irecovery -q || PRE_IREC_RC=$?
echo "(rc=${PRE_IREC_RC})"
echo

PRE_SERIAL="$(extract_serial "${PRE_INFO}")"
if [[ -z "${PRE_SERIAL}" && ${PRE_INFO_RC} -eq 0 ]]; then
  # usbliter8ctl sometimes prints serial on line 2
  PRE_SERIAL="$(printf '%s\n' "${PRE_INFO}" | awk 'NR==2{print; exit}')"
fi
PRE_MODE="$(extract_irecovery_field "${PRE_IREC}" "MODE")"
PRE_PRODUCT="$(extract_irecovery_field "${PRE_IREC}" "PRODUCT")"

echo "parsed pre serial: ${PRE_SERIAL:-"(none)"}"
echo "parsed pre MODE:   ${PRE_MODE:-"(none)"}"
echo "parsed pre PRODUCT:${PRE_PRODUCT:-"(none)"}"
echo

ACTION_RC=0

# --- action (exactly one) ---------------------------------------------------
log_banner "ACTION (${ACTION})"
case "${ACTION}" in
  dry-run)
    echo "dry-run: no Pico step, no host payload send."
    echo "pre/post checks only."
    ;;
  manual_pico)
    cat <<EOF
manual_pico: operator runs ONE prepared Pico step now.

Hard rules for this pause:
  - Use only the procedure named in the candidate Payload plan
  - Do not iterate timings/offsets in this pause
  - Do not run usbliter8ctl demote/boot/send from another terminal

When the single Pico attempt is finished (success or fail), return here.
EOF
    if [[ -t 0 ]]; then
      read -r -p "Press Enter after the single Pico step (or Ctrl-C to abort): " _
    else
      die "manual_pico requires an interactive TTY (or re-run in a terminal)"
    fi
    echo "operator confirmed Pico step complete."
    ;;
esac
echo

# --- post-check -------------------------------------------------------------
log_banner "POST-CHECK"
POST_INFO=""
POST_IREC=""
POST_INFO_RC=0
POST_IREC_RC=0

echo "\$ python3 ${CTL} info"
run_capture POST_INFO python3 "${CTL}" info || POST_INFO_RC=$?
echo "(rc=${POST_INFO_RC})"
echo

echo "\$ irecovery -q"
run_capture POST_IREC irecovery -q || POST_IREC_RC=$?
echo "(rc=${POST_IREC_RC})"
echo

POST_SERIAL="$(extract_serial "${POST_INFO}")"
if [[ -z "${POST_SERIAL}" && ${POST_INFO_RC} -eq 0 ]]; then
  POST_SERIAL="$(printf '%s\n' "${POST_INFO}" | awk 'NR==2{print; exit}')"
fi
POST_MODE="$(extract_irecovery_field "${POST_IREC}" "MODE")"
POST_PRODUCT="$(extract_irecovery_field "${POST_IREC}" "PRODUCT")"

echo "parsed post serial: ${POST_SERIAL:-"(none)"}"
echo "parsed post MODE:   ${POST_MODE:-"(none)"}"
echo "parsed post PRODUCT:${POST_PRODUCT:-"(none)"}"
echo

# --- classify ---------------------------------------------------------------
CLASSIFICATION=""
CLASS_REASON=""
classify_result \
  "${PRE_INFO_RC}" "${POST_INFO_RC}" "${ACTION_RC}" \
  "${PRE_SERIAL}" "${POST_SERIAL}" \
  "${PRE_MODE}" "${POST_MODE}" \
  "${PRE_PRODUCT}" "${POST_PRODUCT}"

log_banner "RESULT"
echo "classification: ${CLASSIFICATION}"
echo "reason:         ${CLASS_REASON}"
echo

# Delta summary
DELTA="unchanged"
if [[ "${PRE_SERIAL:-}" != "${POST_SERIAL:-}" ]]; then
  DELTA="serial changed"
fi
if [[ "${PRE_MODE:-}" != "${POST_MODE:-}" ]]; then
  DELTA="${DELTA}; MODE ${PRE_MODE:-?} → ${POST_MODE:-?}"
fi

# --- update candidate Live result + Status ----------------------------------
# Replace ## Live result section body; set Status to DONE.
tmp_cand="$(mktemp)"
awk -v cls="${CLASSIFICATION}" -v logrel="experiments/logs/$(basename "${LOG_FILE}")" \
    -v reason="${CLASS_REASON}" -v ts="${TS_HUMAN}" -v action="${ACTION}" '
  BEGIN { in_live=0; skipped_live=0; status_done=0 }
  /^##[[:space:]]+Status[[:space:]]*$/ {
    print
    getline
    # print blank lines after heading then DONE
    while ($0 ~ /^[[:space:]]*$/) { print; if (!getline) exit }
    print "DONE"
    status_done=1
    # skip original status token line only
    next
  }
  /^##[[:space:]]+Live result[[:space:]]*$/ {
    print
    print ""
    print "- Classification: " cls
    print "- Log: " logrel
    print "- Action: " action
    print "- Timestamp: " ts
    print "- Notes: " reason
    in_live=1
    skipped_live=1
    next
  }
  in_live && /^##[[:space:]]+/ { in_live=0 }
  in_live { next }
  { print }
' "${CAND_FILE}" > "${tmp_cand}"
mv "${tmp_cand}" "${CAND_FILE}"

# --- append LIVE_SESSION ----------------------------------------------------
[[ -f "${LIVE_SESSION}" ]] || die "missing ${LIVE_SESSION}"

{
  echo ""
  echo "### ${TS_HUMAN} — experiment ${CID} [${CLASSIFICATION}]"
  echo "- Host: ${HOST}, repo \`${REPO_ROOT}\`"
  echo "- Goal: ${HYPOTHESIS:-"(see candidate)"}"
  echo "- Candidate: \`${CAND_BASE}\` Action=\`${ACTION}\`"
  echo "- Cable: ${CABLE_NOTES}"
  echo "- Command(s):"
  echo "  \`\`\`"
  echo "  research/usbliter8-t8027/experiments/run_experiment.sh ${CID}"
  echo "  python3 ./usbliter8ctl info   # pre + post"
  echo "  irecovery -q                  # pre + post"
  echo "  \`\`\`"
  echo "- Observed:"
  echo "  - Pre serial: \`${PRE_SERIAL:-"(none)"}\`"
  echo "  - Post serial: \`${POST_SERIAL:-"(none)"}\`"
  echo "  - Pre MODE/PRODUCT: \`${PRE_MODE:-?}\` / \`${PRE_PRODUCT:-?}\`"
  echo "  - Post MODE/PRODUCT: \`${POST_MODE:-?}\` / \`${POST_PRODUCT:-?}\`"
  echo "  - Classification: **${CLASSIFICATION}** — ${CLASS_REASON}"
  echo "- Delta vs prior: ${DELTA}"
  echo "- Interpretation (optional, labeled): harness result only; not an A12X exploit claim"
  echo "- Next: review \`${LOG_FILE/#${REPO_ROOT}\//}\` and candidate Live result"
} >> "${LIVE_SESSION}"

log_banner "DONE"
echo "candidate → Status DONE, Live result updated"
echo "LIVE_SESSION appended: ${LIVE_SESSION}"
echo "full log: ${LOG_FILE}"
echo "classification: ${CLASSIFICATION}"

# Exit nonzero on ERROR so automation/CI-ish use notices failure; live anomalies still 0.
if [[ "${CLASSIFICATION}" == "ERROR" ]]; then
  exit 1
fi
exit 0
