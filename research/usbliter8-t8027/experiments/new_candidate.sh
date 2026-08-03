#!/usr/bin/env bash
# Create the next numbered t8027 experiment candidate from the template.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CAND_DIR="${SCRIPT_DIR}/candidates"
TEMPLATE="${SCRIPT_DIR}/templates/candidate.md"

if [[ ! -f "${TEMPLATE}" ]]; then
  echo "error: missing template: ${TEMPLATE}" >&2
  exit 1
fi

mkdir -p "${CAND_DIR}"

title="${*:-untitled}"
# slug: lowercase, spaces→hyphens, keep alnum/hyphen only
slug="$(
  printf '%s' "${title}" \
    | tr '[:upper:]' '[:lower:]' \
    | sed -E 's/[^a-z0-9]+/-/g; s/^-+//; s/-+$//; s/-+/-/g'
)"
[[ -n "${slug}" ]] || slug="untitled"

next=1
shopt -s nullglob
for f in "${CAND_DIR}"/C[0-9][0-9][0-9]-*.md; do
  base="$(basename "${f}")"
  num="${base%%-*}"
  num="${num#C}"
  if [[ "${num}" =~ ^[0-9]+$ ]] && (( 10#${num} >= next )); then
    next=$((10#${num} + 1))
  fi
done
shopt -u nullglob

id="$(printf 'C%03d' "${next}")"
out="${CAND_DIR}/${id}-${slug}.md"

if [[ -e "${out}" ]]; then
  echo "error: already exists: ${out}" >&2
  exit 1
fi

# Replace template title with real id + title; leave Status=DRAFT.
# Escape sed replacement metacharacters in title.
title_sed="$(printf '%s' "${title}" | sed -e 's/[&|]/\\&/g')"
sed -e "s|^# CXXX — short title\$|# ${id} — ${title_sed}|" "${TEMPLATE}" > "${out}"

echo "created ${out}"
echo "edit → set Status READY when intentionally authorizing one run"
echo "then: ${SCRIPT_DIR}/run_experiment.sh ${id}"
