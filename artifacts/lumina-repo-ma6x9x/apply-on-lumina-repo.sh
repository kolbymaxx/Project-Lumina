#!/usr/bin/env bash
# Apply the ma6x9x username fix onto lumina-repo PR #55 branch.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"
WORKDIR="$(mktemp -d)"
trap 'rm -rf "$WORKDIR"' EXIT

git clone --depth 1 -b cursor/sileo-dopamine-repo-harden-d520 \
  https://github.com/ma6x9x/lumina-repo.git "$WORKDIR/lumina-repo"
cd "$WORKDIR/lumina-repo"
git apply "$ROOT/ma6x9x-username-on-pr55.patch"
git checkout -b cursor/ma6x9x-username-tweaks-44a3
git add -A
git status --short
git commit -m "chore: point Lumina Repo URLs and maintainers at ma6x9x"
echo
echo "Committed locally in: $WORKDIR/lumina-repo"
echo "Push with:"
echo "  cd $WORKDIR/lumina-repo && git push -u origin HEAD"
# Keep tree if requested
if [[ "${KEEP:-0}" == "1" ]]; then
  trap - EXIT
  echo "WORKDIR=$WORKDIR"
fi
