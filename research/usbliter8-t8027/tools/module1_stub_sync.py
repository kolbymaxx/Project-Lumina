#!/usr/bin/env python3
"""Module 1 — stub tree sync / safety checker (research only).

Verifies that in-repo t8027 stubs still refuse silent fills, and prints
copy commands into a local (gitignored) upstream/usbliter8 clone.

Usage:
  python3 module1_stub_sync.py --repo-root ../../..
  python3 module1_stub_sync.py --repo-root ../../.. --check-upstream
"""

from __future__ import annotations

import argparse
import sys
from pathlib import Path
from typing import List, Sequence, Tuple


REQUIRED_STUBS: Sequence[str] = (
    "stubs/t8020_t8006_shellcode/targets/t8027/offsets.h",
    "stubs/t8020_t8006_shellcode/targets/t8027/blocks.S",
    "stubs/t8020_t8006_shellcode/targets/t8027/cleanup.S",
    "stubs/usb_req_handler/targets/t8027/offsets.h",
    "stubs/t8027_config.snippet.c",
    "stubs/exploit_cpid_switch.snippet.c",
)


def find_track(repo_root: Path) -> Path:
    track = repo_root / "research" / "usbliter8-t8027"
    if not track.is_dir():
        raise SystemExit("missing research/usbliter8-t8027 under {}".format(repo_root))
    return track


def check_stub_guards(track: Path) -> List[str]:
    problems: List[str] = []
    for rel in REQUIRED_STUBS:
        path = track / rel
        if not path.is_file():
            problems.append("missing {}".format(rel))
            continue
        text = path.read_text(errors="replace")
        if rel.endswith("offsets.h"):
            if "#error" not in text and "TODO" not in text:
                problems.append(
                    "{} has no #error/TODO guard — refusing silent fill".format(rel)
                )
        if rel.endswith(".snippet.c"):
            if "TODO" not in text and "#if 0" not in text:
                problems.append("{} should stay wrapped / TODO-gated".format(rel))
    # resources blobs must not appear invented in-repo
    bad_resources = list(track.glob("stubs/resources/*t8027*"))
    if bad_resources:
        problems.append(
            "unexpected resources blobs under stubs/: {}".format(
                [str(p) for p in bad_resources]
            )
        )
    return problems


def print_copy_plan(track: Path, upstream: Path) -> None:
    pairs: List[Tuple[Path, Path]] = [
        (
            track / "stubs/t8020_t8006_shellcode/targets/t8027",
            upstream / "t8020_t8006_shellcode/targets/t8027",
        ),
        (
            track / "stubs/usb_req_handler/targets/t8027",
            upstream / "usb_req_handler/targets/t8027",
        ),
    ]
    print("# copy after offsets are evidence-backed (local only):")
    for src, dst in pairs:
        print("mkdir -p {}".format(dst))
        print("cp -R {}/. {}".format(src, dst))
    print("# then merge snippets into exploit.c behind -DUSBLITER8_TARGET_T8027=1")
    print("# snippets:", track / "stubs/t8027_config.snippet.c")
    print("#          ", track / "stubs/exploit_cpid_switch.snippet.c")


def main(argv=None) -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument(
        "--repo-root",
        type=Path,
        default=Path(__file__).resolve().parents[3],
        help="Project Lumina root",
    )
    ap.add_argument(
        "--check-upstream",
        action="store_true",
        help="also require upstream/usbliter8 clone to exist",
    )
    ap.add_argument(
        "--print-copy",
        action="store_true",
        help="print cp plan into upstream clone",
    )
    args = ap.parse_args(argv)

    repo_root = args.repo_root.resolve()
    track = find_track(repo_root)
    problems = check_stub_guards(track)

    upstream = repo_root / "upstream" / "usbliter8"
    if args.check_upstream and not (upstream / "exploit.c").is_file():
        problems.append(
            "upstream/usbliter8 missing — clone per upstream/README.md (gitignored)"
        )

    if problems:
        print("STUB SYNC FAIL:", file=sys.stderr)
        for p in problems:
            print("  - {}".format(p), file=sys.stderr)
        return 2

    print("STUB SYNC OK — {} required stubs present and gated".format(len(REQUIRED_STUBS)))
    if args.print_copy:
        if not upstream.exists():
            print("upstream clone absent; copy plan is still:", file=sys.stderr)
        print_copy_plan(track, upstream)
    return 0


if __name__ == "__main__":
    sys.exit(main())
