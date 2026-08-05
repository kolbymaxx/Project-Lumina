#!/usr/bin/env bash
# One-shot for Mac: clone Project-Lumina if needed, checkout branch, open Xcode.
# Usage (paste ONE line at a time, no comments on the same line):
#   bash <(curl -fsSL ...)   # not used — run after clone
#   ~/Projects/Project-Lumina/scripts/mac_bootstrap_lumina.sh
set -euo pipefail

REPO_URL="${LUMINA_REPO_URL:-https://github.com/kolbymaxx/Project-Lumina.git}"
BRANCH="${LUMINA_BRANCH:-cursor/a12-krw-ppl-research-f891}"
PARENT="${LUMINA_PARENT:-$HOME/Projects}"
DEST="${PARENT}/Project-Lumina"

mkdir -p "${PARENT}"

if [[ ! -d "${DEST}/.git" ]]; then
  echo "[+] Cloning ${REPO_URL} → ${DEST}"
  git clone "${REPO_URL}" "${DEST}"
else
  echo "[*] Using existing ${DEST}"
fi

cd "${DEST}"
git fetch origin
git checkout "${BRANCH}"
git pull --ff-only origin "${BRANCH}" || git pull --ff-only origin "${BRANCH}"

exec "${DEST}/scripts/mac_open_lumina.sh"
