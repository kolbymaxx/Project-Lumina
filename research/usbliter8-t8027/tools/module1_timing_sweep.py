#!/usr/bin/env python3
"""Module 1 — timing-sweep *scaffold* for post-offset Pico experiments.

Research only. Does NOT craft USB race packets. Assumes:
  - local UF2 already built from evidence-backed t8027 offsets
  - operator attaches the race harness manually
  - `usbliter8ctl info` can observe DFU serial on the host Mac

Refuses to run if a stub offsets.h still contains '#error' or if the
worksheet CSV still has empty required ROM roles.

Usage:
  python3 module1_timing_sweep.py --config sweep.yaml --dry-run
  python3 module1_timing_sweep.py --config sweep.yaml --offsets-h path/to/offsets.h
"""

from __future__ import annotations

import argparse
import re
import subprocess
import sys
import time
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Dict, List, Optional

try:
    import yaml  # type: ignore
except ImportError:  # minimal fallback: accept JSON as YAML subset via json
    yaml = None
    import json


REQUIRED_ROLES_NONEMPTY = (
    "MEMCPY",
    "HANDLE_USB_REQ",
    "JUMP_AWAY",
    "MAIN_TASK_STACK_LR",
    "USB_DMA_DEST",
    "ov_start",
    "shc_base",
    "VICTIM_FRAME_AUTH",
)


@dataclass
class Outcome:
    label: str
    delay: Any
    classification: str
    serial: str
    detail: str = ""


def load_config(path: Path) -> Dict[str, Any]:
    text = path.read_text()
    if yaml is not None:
        return yaml.safe_load(text)
    # JSON-only fallback
    return json.loads(text)


def offsets_still_blocked(offsets_h: Path) -> List[str]:
    text = offsets_h.read_text()
    problems: List[str] = []
    if "#error" in text:
        problems.append("{} still contains #error".format(offsets_h))
    # zero-only defines are suspicious placeholders
    if re.search(r"#define\s+\w+\s+0x0+\b", text):
        problems.append("{} contains 0x0 defines — likely unfilled".format(offsets_h))
    return problems


def worksheet_incomplete(csv_path: Path) -> List[str]:
    import csv

    problems: List[str] = []
    with csv_path.open(newline="") as fh:
        rows = {r["role"]: r for r in csv.DictReader(fh)}
    for role in REQUIRED_ROLES_NONEMPTY:
        row = rows.get(role)
        if not row or not (row.get("t8027_va") or "").strip():
            problems.append("worksheet role {!r} has empty t8027_va".format(role))
        if not row or not (row.get("evidence") or "").strip():
            problems.append("worksheet role {!r} has empty evidence".format(role))
    return problems


def classify_serial(serial: str) -> str:
    if not serial or "CPID:" not in serial:
        return "no_device"
    if "CPID:8027" not in serial.upper().replace("cpid:", "CPID:"):
        # normalize
        if "8027" not in serial:
            return "wrong_cpid"
    if "PWND:[usbliter8]" in serial:
        return "pwnd"
    if "not supported" in serial.lower():
        return "unsupported"
    return "still_unpwned"


def run_info(usbliter8ctl: Path, timeout: float) -> str:
    try:
        proc = subprocess.run(
            [sys.executable, str(usbliter8ctl), "info"],
            capture_output=True,
            text=True,
            timeout=timeout,
        )
    except subprocess.TimeoutExpired:
        return ""
    out = (proc.stdout or "") + "\n" + (proc.stderr or "")
    for line in out.splitlines():
        if "CPID:" in line or line.strip().lower().startswith("serial:"):
            return line.split(":", 1)[-1].strip() if line.lower().startswith("serial") else line.strip()
    return out.strip()


def main(argv: Optional[List[str]] = None) -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--config", type=Path, required=True)
    ap.add_argument(
        "--offsets-h",
        type=Path,
        help="path to targets/t8027/offsets.h — must not contain #error",
    )
    ap.add_argument(
        "--worksheet",
        type=Path,
        help="role CSV from module1_offset_audit.py — required roles must be filled",
    )
    ap.add_argument(
        "--usbliter8ctl",
        type=Path,
        default=Path("usbliter8ctl"),
        help="host tool path (repo root)",
    )
    ap.add_argument("--dry-run", action="store_true")
    ap.add_argument("--info-timeout", type=float, default=5.0)
    args = ap.parse_args(argv)

    cfg = load_config(args.config)
    delays = cfg.get("delays") or cfg.get("crazy_delay_candidates") or []
    if not delays:
        print("config has no delays list", file=sys.stderr)
        return 2

    blockers: List[str] = []
    if args.offsets_h:
        blockers.extend(offsets_still_blocked(args.offsets_h))
    else:
        blockers.append("refusing: pass --offsets-h so unfilled stubs cannot be raced")
    if args.worksheet:
        blockers.extend(worksheet_incomplete(args.worksheet))
    else:
        blockers.append("refusing: pass --worksheet with evidence-backed roles")

    if blockers:
        print("GATE FAIL — timing sweep blocked:", file=sys.stderr)
        for b in blockers:
            print("  - {}".format(b), file=sys.stderr)
        print(
            "Fill SecureROM worksheet + stubs before any Pico delay experiments.",
            file=sys.stderr,
        )
        return 2

    print("GATE OK — {} delay candidates".format(len(delays)))
    if args.dry-run:
        for d in delays:
            print("DRY-RUN would test delay={!r}".format(d))
        print(
            "Operator steps per candidate: flash UF2 with delay baked in → "
            "attach race harness → DFU → poll usbliter8ctl info"
        )
        return 0

    # Live loop: observation only. Flashing UF2 is left to the operator /
    # external script named in config['flash_command'] if present.
    outcomes: List[Outcome] = []
    flash_cmd = cfg.get("flash_command")
    settle_s = float(cfg.get("settle_seconds", 3))

    for idx, delay in enumerate(delays):
        label = "delay_{}_{}".format(idx, delay)
        if flash_cmd:
            cmd = [c.replace("{delay}", str(delay)) for c in flash_cmd]
            print("flash:", cmd)
            subprocess.run(cmd, check=False)
        else:
            print(
                "MANUAL: flash UF2 built for crazy_delay={!r}, then press Enter".format(
                    delay
                )
            )
            try:
                input()
            except EOFError:
                print("no TTY — abort", file=sys.stderr)
                return 2

        time.sleep(settle_s)
        serial = run_info(args.usbliter8ctl, args.info_timeout)
        klass = classify_serial(serial)
        outcomes.append(Outcome(label, delay, klass, serial))
        print("{} -> {} | {}".format(label, klass, serial[:120]))
        if klass == "pwnd":
            print("Module 1 exit criterion observed — stop sweep")
            break

    pwnd = sum(1 for o in outcomes if o.classification == "pwnd")
    print("summary: trials={} pwnd={}".format(len(outcomes), pwnd))
    return 0 if pwnd else 1


if __name__ == "__main__":
    sys.exit(main())
