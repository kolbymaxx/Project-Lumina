#!/usr/bin/env bash
# Mac helper: clone DS-K third_party, generate Xcode project, open it.
# Safe to run from any cwd — resolves repo root from this script's path.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "${ROOT}"

if [[ ! -f "${ROOT}/Lumina/project.yml" ]]; then
  cat >&2 <<EOF
error: this does not look like Project Lumina (missing Lumina/project.yml).

You must run from a clone of https://github.com/kolbymaxx/Project-Lumina
on branch cursor/a12-krw-ppl-research-f891 (or main once merged).

Do NOT run from ~/Downloads or KDotz-Repo.

Example:
  cd ~/Projects/Project-Lumina   # or wherever you cloned it
  git fetch origin
  git checkout cursor/a12-krw-ppl-research-f891
  ./scripts/mac_open_lumina.sh
EOF
  exit 1
fi

echo "[*] Repo root: ${ROOT}"
"${ROOT}/scripts/clone_darksword_kexploit.sh"

if ! command -v xcodegen >/dev/null 2>&1; then
  echo "[*] Installing xcodegen via Homebrew…"
  brew install xcodegen
fi

cd "${ROOT}/Lumina"
xcodegen generate
echo "[+] Generated ${ROOT}/Lumina/Lumina.xcodeproj"
open "${ROOT}/Lumina/Lumina.xcodeproj"
echo "[+] Opened Xcode. Select your Team, then Product → Run on the XR."
echo "    IPA export: see scripts/export_ipa.md"
