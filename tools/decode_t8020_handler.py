#!/usr/bin/env python3
"""Decode CUSTOM_BOOT constants from the published t8020 USB handler blob."""

from __future__ import annotations

import argparse
import struct
import sys


# Published resources/handler_t8020.h from prdgmshift/usbliter8.
HANDLER_T8020 = bytes(
    [
        0xFD,
        0x7B,
        0xBF,
        0xA9,
        0xFD,
        0x03,
        0x00,
        0x91,
        0x08,
        0x00,
        0xC0,
        0x39,
        0x48,
        0x01,
        0xF8,
        0x37,
        0x08,
        0x04,
        0x40,
        0x39,
        0x1F,
        0x21,
        0x00,
        0x71,
        0x60,
        0x01,
        0x00,
        0x54,
        0x1F,
        0x1D,
        0x00,
        0x71,
        0xA1,
        0x00,
        0x00,
        0x54,
        0x08,
        0x9F,
        0x8F,
        0xD2,
        0x28,
        0x00,
        0xC0,
        0xF2,
        0x00,
        0x01,
        0x3F,
        0xD6,
        0x0E,
        0x00,
        0x00,
        0x14,
        0x82,
        0x7D,
        0x9C,
        0xD2,
        0x22,
        0x00,
        0xC0,
        0xF2,
        0xFD,
        0x7B,
        0xC1,
        0xA8,
        0x40,
        0x00,
        0x1F,
        0xD6,
        0x08,
        0x0A,
        0x8D,
        0xD2,
        0x28,
        0x00,
        0xC0,
        0xF2,
        0x00,
        0x01,
        0x3F,
        0xD6,
        0x08,
        0xE1,
        0x9B,
        0xD2,
        0x28,
        0x80,
        0xB3,
        0xF2,
        0x28,
        0x00,
        0xC0,
        0xF2,
        0x89,
        0x91,
        0x83,
        0xD2,
        0x29,
        0x00,
        0xC0,
        0xF2,
        0x09,
        0x01,
        0x00,
        0xF9,
        0x00,
        0x00,
        0x80,
        0x52,
        0xFD,
        0x7B,
        0xC1,
        0xA8,
        0xC0,
        0x03,
        0x5F,
        0xD6,
    ]
)

EXPECTED = {
    "PLATFORM_DEMOTE": 0x100007CF8,
    "HANDLE_USB_REQ": 0x10000E3EC,
    "PLATFORM_SET_REMOTE_BOOT": 0x100006850,
    "MAIN_TASK_STACK_LR": 0x19C01DF08,
    "JUMP_AWAY": 0x100001C8C,
}


def decode_mov(insn: int):
    opc = (insn >> 29) & 0x3
    hw = (insn >> 21) & 0x3
    imm16 = (insn >> 5) & 0xFFFF
    rd = insn & 0x1F
    shift = hw * 16
    kind = {2: "MOVZ", 3: "MOVK"}.get(opc)
    return kind, rd, imm16, shift


def decode_handler(blob: bytes):
    regs = {}
    found = {}
    events = []

    for offset in range(0, len(blob), 4):
        insn = struct.unpack_from("<I", blob, offset)[0]
        if (insn & 0x1F800000) == 0x12800000:
            kind, rd, imm16, shift = decode_mov(insn)
            if kind == "MOVZ":
                regs[rd] = imm16 << shift
            elif kind == "MOVK":
                mask = 0xFFFF << shift
                regs[rd] = (regs.get(rd, 0) & ~mask) | (imm16 << shift)
            continue

        if insn == 0xD63F0100:  # BLR X8
            target = regs.get(8)
            events.append(("BLR_X8", target))
            if target == EXPECTED["PLATFORM_DEMOTE"]:
                found["PLATFORM_DEMOTE"] = target
            elif target == EXPECTED["PLATFORM_SET_REMOTE_BOOT"]:
                found["PLATFORM_SET_REMOTE_BOOT"] = target
        elif insn == 0xF9000109:  # STR X9, [X8]
            found["MAIN_TASK_STACK_LR"] = regs.get(8)
            found["JUMP_AWAY"] = regs.get(9)
            events.append(("STR_JUMP", regs.get(8), regs.get(9)))
        elif insn == 0xD61F0040:  # BR X2 in the fallback path
            found["HANDLE_USB_REQ"] = regs.get(2)
            events.append(("BR_X2", regs.get(2)))

    return found, events


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "blob",
        nargs="?",
        help="optional raw handler binary; defaults to published handler_t8020",
    )
    args = parser.parse_args(argv)

    if args.blob:
        with open(args.blob, "rb") as handle:
            blob = handle.read()
    else:
        blob = HANDLER_T8020

    found, events = decode_handler(blob)
    print("decoded events:")
    for event in events:
        print(" ", event)

    print("\nconstants:")
    ok = True
    for name, expected in EXPECTED.items():
        actual = found.get(name)
        status = "OK" if actual == expected else "MISMATCH"
        if actual != expected:
            ok = False
        print(
            "  {:24} expected=0x{:X} actual={} [{}]".format(
                name,
                expected,
                "None" if actual is None else "0x{:X}".format(actual),
                status,
            )
        )

    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
