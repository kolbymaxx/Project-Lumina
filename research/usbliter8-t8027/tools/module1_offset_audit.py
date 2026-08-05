#!/usr/bin/env python3
"""Module 1 — DFU identity gate + offset role checklist (research only).

No device writes. No exploit payloads. Parses a DFU serial string (from
`usbliter8ctl info` paste or --serial) and emits a CSV of usbliter8 *roles*
that must be filled for a T8027 port.

Usage:
  python3 module1_offset_audit.py --serial 'CPID:8027 ... SRTG:[iBoot-4172.0.0.100.14]'
  python3 module1_offset_audit.py --from-info-file /tmp/info.txt --emit-csv roles.csv
  python3 module1_offset_audit.py --diff old.csv new.csv
"""

from __future__ import annotations

import argparse
import csv
import re
import sys
from dataclasses import dataclass, fields
from pathlib import Path
from typing import Dict, Iterable, List, Optional, Tuple


# Roles mirror docs/research/usbliter8-t8027-bringup.md inventory.
# Values stay empty until evidence-backed RE fills them locally.
ROLE_CHECKLIST: List[Tuple[str, str, str]] = [
    # group, role, notes
    ("identity", "CPID", "must be 0x8027"),
    ("identity", "SRTG", "must match SecureROM image 4172.0.0.100.14"),
    ("identity", "PWND", "Module 1 exit when PWND:[usbliter8] present"),
    ("rom", "MEMCPY", "SecureROM VA"),
    ("rom", "STRLCAT", "SecureROM VA"),
    ("rom", "CALCULATE_HEAP_BLOCK_SUM", "SecureROM VA"),
    ("rom", "ROM_TRAMP", "SecureROM VA"),
    ("rom", "USB_DESC_MAKE_STR", "SecureROM VA"),
    ("rom", "HANDLE_USB_REQ", "handler offsets.h"),
    ("rom", "PLATFORM_DEMOTE", "handler offsets.h"),
    ("rom", "PLATFORM_SET_REMOTE_BOOT", "handler offsets.h"),
    ("rom", "JUMP_AWAY", "handler offsets.h"),
    ("rom", "RETURN_TO_EL0_ADDR", "shellcode offsets.h"),
    ("rom", "ROP_GADGET_SET", "all create_overwrite LRs — PAC policy required"),
    ("sram", "JUMP_STATE", "lab: 0x19C014030 confirmed on 4172 — still re-cite"),
    ("sram", "TRAMP_BASE", "candidate 0x19C018000 — validate"),
    ("sram", "NEW_SP", "heap/stack bank"),
    ("sram", "ov_start", "config blob"),
    ("sram", "shc_base", "config blob"),
    ("sram", "shc_start", "config blob"),
    ("sram", "USB_REQ_HANDLER_CB_ADDR", "BSS callback"),
    ("sram", "MAIN_TASK_STACK_LR", "CUSTOM_BOOT slot — PAC likely"),
    ("sram", "USB_SN_STR", "serial string buffer"),
    ("sram", "HEAP_BLOCKS", "blocks.S list"),
    ("mmio", "USB_DMA_DEST", "DOEPDMA / store target — do not assume 0x2391"),
    ("mmio", "USB_CONTROLLER_BASE", "cleanup.S"),
    ("timing", "crazy_delay", "RP2350 retune last"),
    ("timing", "TASK_SLEEP_US", "ROP delay value"),
    ("pac", "VICTIM_FRAME_AUTH", "retab vs plain ret vs blr callback"),
    ("pac", "HANDLER_WITH_PAC", "whether handler must PACIB JUMP_AWAY"),
]


@dataclass
class DfuIdentity:
    cpid: Optional[str] = None
    cprv: Optional[str] = None
    cpfm: Optional[str] = None
    scep: Optional[str] = None
    bdid: Optional[str] = None
    ecid: Optional[str] = None
    ibfl: Optional[str] = None
    srtg: Optional[str] = None
    pwnd: Optional[str] = None
    raw: str = ""


_FIELD_RE = re.compile(
    r"CPID:(?P<cpid>[0-9A-Fa-f]+)|"
    r"CPRV:(?P<cprv>[0-9A-Fa-f]+)|"
    r"CPFM:(?P<cpfm>[0-9A-Fa-f]+)|"
    r"SCEP:(?P<scep>[0-9A-Fa-f]+)|"
    r"BDID:(?P<bdid>[0-9A-Fa-f]+)|"
    r"ECID:(?P<ecid>[0-9A-Fa-f]+)|"
    r"IBFL:(?P<ibfl>[0-9A-Fa-f]+)|"
    r"SRTG:\[(?P<srtg>[^\]]+)\]|"
    r"PWND:\[(?P<pwnd>[^\]]+)\]"
)


def parse_serial(text: str) -> DfuIdentity:
    ident = DfuIdentity(raw=text.strip())
    for match in _FIELD_RE.finditer(text):
        for key in (
            "cpid",
            "cprv",
            "cpfm",
            "scep",
            "bdid",
            "ecid",
            "ibfl",
            "srtg",
            "pwnd",
        ):
            val = match.group(key)
            if val:
                setattr(ident, key, val)
    return ident


def gate_t8027(ident: DfuIdentity) -> List[str]:
    """Return human-readable gate failures (empty = pass for identity stage)."""
    errs: List[str] = []
    if (ident.cpid or "").upper() != "8027":
        errs.append("CPID is not 8027 (got {!r})".format(ident.cpid))
    if not ident.srtg or "4172.0.0.100.14" not in ident.srtg:
        errs.append(
            "SRTG does not contain 4172.0.0.100.14 (got {!r})".format(ident.srtg)
        )
    return errs


def emit_csv(path: Path, ident: DfuIdentity) -> None:
    with path.open("w", newline="") as fh:
        writer = csv.DictWriter(
            fh,
            fieldnames=[
                "group",
                "role",
                "t8027_va",
                "evidence",
                "pac_notes",
                "notes",
                "cpid",
                "srtg",
            ],
        )
        writer.writeheader()
        for group, role, notes in ROLE_CHECKLIST:
            writer.writerow(
                {
                    "group": group,
                    "role": role,
                    "t8027_va": "",
                    "evidence": "",
                    "pac_notes": "",
                    "notes": notes,
                    "cpid": ident.cpid or "",
                    "srtg": ident.srtg or "",
                }
            )


def load_csv(path: Path) -> Dict[str, dict]:
    with path.open(newline="") as fh:
        rows = list(csv.DictReader(fh))
    return {r["role"]: r for r in rows}


def diff_csv(old_path: Path, new_path: Path) -> int:
    old = load_csv(old_path)
    new = load_csv(new_path)
    roles = sorted(set(old) | set(new))
    changes = 0
    for role in roles:
        a = old.get(role, {})
        b = new.get(role, {})
        if a.get("t8027_va") != b.get("t8027_va") or a.get("evidence") != b.get(
            "evidence"
        ):
            changes += 1
            print(
                "ROLE {:<28} va {!r} -> {!r} | evidence {!r} -> {!r}".format(
                    role,
                    a.get("t8027_va"),
                    b.get("t8027_va"),
                    a.get("evidence"),
                    b.get("evidence"),
                )
            )
    print("changed_roles={}".format(changes))
    return 0 if changes >= 0 else 1


def extract_serial_from_info(text: str) -> str:
    for line in text.splitlines():
        line = line.strip()
        if line.lower().startswith("serial:"):
            return line.split(":", 1)[1].strip()
        if "CPID:" in line:
            return line
    return text


def main(argv: Optional[Iterable[str]] = None) -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--serial", help="raw DFU serial string")
    ap.add_argument(
        "--from-info-file",
        type=Path,
        help="paste of `usbliter8ctl info` output",
    )
    ap.add_argument("--emit-csv", type=Path, help="write empty role checklist CSV")
    ap.add_argument(
        "--diff",
        nargs=2,
        metavar=("OLD", "NEW"),
        help="diff two checklist CSVs",
    )
    ap.add_argument(
        "--require-unpwned",
        action="store_true",
        help="fail if PWND marker already present (pre-port baseline)",
    )
    args = ap.parse_args(list(argv) if argv is not None else None)

    if args.diff:
        return diff_csv(Path(args.diff[0]), Path(args.diff[1]))

    raw = args.serial or ""
    if args.from_info_file:
        raw = extract_serial_from_info(args.from_info_file.read_text())
    if not raw:
        ap.error("provide --serial or --from-info-file (or use --diff)")

    ident = parse_serial(raw)
    print("parsed:")
    for f in fields(ident):
        if f.name == "raw":
            continue
        print("  {}: {}".format(f.name, getattr(ident, f.name)))

    errs = gate_t8027(ident)
    if args.require_unpwned and ident.pwnd:
        errs.append("already PWND:[{}] — not a pre-port baseline".format(ident.pwnd))
    if errs:
        print("GATE FAIL:", file=sys.stderr)
        for e in errs:
            print("  - {}".format(e), file=sys.stderr)
        return 2

    print("GATE OK: T8027 / 4172 identity")
    if ident.pwnd:
        print("NOTE: PWND:[{}] present — Module 1 exit criterion met".format(ident.pwnd))
    else:
        print("NOTE: unpwned — expected until t8027 Pico port exists")

    if args.emit_csv:
        emit_csv(args.emit_csv, ident)
        print("wrote checklist {}".format(args.emit_csv))

    return 0


if __name__ == "__main__":
    sys.exit(main())
