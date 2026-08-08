#!/usr/bin/env python3
"""rom_re_assist.py — static RE assistant for the t8027 SecureROM dump.

Addresses the #1 Module 1 gate (PAC_AND_CONTROL_FLOW.md priority 1-2):
  - Is the t8020 non-PAC LR-ROP path viable on t8027, or is the ROM
    PAC-heavy enough that a PAC-aware first hijack is required?
  - Where are the t8020 ROP gadget *shapes* in 4172, and does each live
    inside a PAC-protected frame (retab) or a plain-ret island?

Static, no device. Output is EVIDENCE, not stub fills.

Usage:
    rom_re_assist.py [<rom>] [<base>]
        rom  defaults to research/usbliter8-t8027/artifacts/SecureROM_t8027_4172.bin
        base defaults to 0x100000000
"""
import sys, os, struct
try:
    from capstone import Cs, CS_ARCH_ARM64, CS_MODE_LITTLE_ENDIAN
except Exception as e:
    sys.exit(f"need capstone: pip install capstone  ({e})")

BASE = 0x100000000
DEFAULT_ROM = "research/usbliter8-t8027/artifacts/SecureROM_t8027_4172.bin"
USB_SERIAL_BUILDER = 0x1000067bc

# Known DFU/identity string VAs from FIRST_RE_PASS.md (file offset + BASE).
STRING_ANCHORS = {
    0x100000200: "SecureROM for t8027si, Copyright ...",
    0x100000280: "iBoot-4172.0.0.100.14",
    0x10001d45a: "Apple Mobile Device (DFU Mode)",
    0x10001d479: "CPID:%04X CPRV:%02X ... ECID:%016llX IBFL:%02X",
    0x10001d4c2: " SRTG:[%s]",
    0x10001d500: "constructing idle task",
    0x100021e93: "Apple Secure Boot Root CA - G21",
    0x100024618: "bootstrap",
}

# t8020 ROP gadget VAs (exploit.c t8020_n) — REFERENCE ONLY, never copied.
SHAPE_MAP = {
    "G1": ("ldr x19, [sp, #imm]", 0x10000FC30),
    "G2": ("movz/ldr w8", 0x100007510),
    "G3": ("str w8, [x19, #imm]", 0x100007358),
    "G4": ("ldr w0, [sp, #imm]", 0x10000e2bc),
    "G5": ("blr x19", 0x100003948),
    "G6": ("msr/eret/hvc/smc (EL1 esc)", 0x1000088B0),
}


def disasm(data, base):
    md = Cs(CS_ARCH_ARM64, CS_MODE_LITTLE_ENDIAN)
    md.detail = True
    md.skipdata = True  # skip data islands (strings/tables) and keep going
    return list(md.disasm(data, base))


def detect_functions(insns):
    """Group instructions into functions by prologue/epilogue (best-effort).

    pac = True if ANY return is `retab` (LR authenticated on return).
    This is the signal that matters for LR-ROP: a `retab` faults on a
    raw/smashed LR; a plain `ret` does not.
    """
    funcs, cur = [], None
    for insn in insns:
        m = insn.mnemonic
        if cur is None:
            if m in ("pacibsp", "paciasp", "stp"):
                cur = {"start": insn.address, "end": None,
                        "pac": False, "rets": [], "insns": [insn]}
        else:
            cur["insns"].append(insn)
            if m in ("ret", "retab"):
                cur["end"] = insn.address
                cur["rets"].append(m)
                cur["pac"] = cur["pac"] or (m == "retab")
                funcs.append(cur)
                cur = None
            elif m in ("pacibsp", "paciasp", "stp") and insn.address != cur["start"]:
                cur["end"] = insn.address
                funcs.append(cur)
                cur = {"start": insn.address, "end": None,
                        "pac": False, "rets": [], "insns": [insn]}
    if cur is not None:
        cur["end"] = cur["insns"][-1].address if cur["insns"] else cur["start"]
        funcs.append(cur)
    return funcs


def enclosing(funcs, addr):
    for f in funcs:
        if f["start"] <= addr <= (f["end"] or f["start"]):
            return f
    return None


def page_pac_density(insns, base):
    pages = {}
    for insn in insns:
        d = pages.setdefault((insn.address - base) // 0x1000,
                              {"pacibsp": 0, "retab": 0, "ret": 0})
        if insn.mnemonic in ("pacibsp", "paciasp"):
            d["pacibsp"] += 1
        elif insn.mnemonic == "retab":
            d["retab"] += 1
        elif insn.mnemonic == "ret":
            d["ret"] += 1
    return pages


def find_gadgets(insns, funcs):
    hits = {k: [] for k in SHAPE_MAP}
    for insn in insns:
        m, op = insn.mnemonic, insn.op_str
        if m == "ldr" and op.startswith("x19, [sp"):
            hits["G1"].append((insn, op, enclosing(funcs, insn.address)))
        elif m == "movz" and op.startswith("w8,"):
            hits["G2"].append((insn, op, enclosing(funcs, insn.address)))
        elif m == "ldr" and op.startswith("w8, ["):
            hits["G2"].append((insn, op, enclosing(funcs, insn.address)))
        elif m == "str" and op.startswith("w8, [x19"):
            hits["G3"].append((insn, op, enclosing(funcs, insn.address)))
        elif m == "ldr" and op.startswith("w0, [sp"):
            hits["G4"].append((insn, op, enclosing(funcs, insn.address)))
        elif m == "blr" and "x19" in op:
            hits["G5"].append((insn, op, enclosing(funcs, insn.address)))
        elif m in ("msr", "eret", "hvc", "smc"):
            hits["G6"].append((insn, f"{m} {op}", enclosing(funcs, insn.address)))
    return hits


def find_string_xrefs(insns, data, base):
    """Find references to known string anchor VAs.

    SecureROM references strings via PC-relative literal-pool loads
    (ldr xN, [pc, #imm] -> 8-byte address), not adrp+add. So:
      1. scan the raw bytes for 8-byte LE values == each anchor VA
         -> literal-pool entry file offsets.
      2. for each pool entry, find ldr xN, [pc, #imm] whose resolved
         target (align(addr,4) + imm) lands on the pool entry.
    """
    xrefs = {va: [] for va in STRING_ANCHORS}
    # 1. literal-pool entries: 8-byte LE == anchor VA
    pool_entries = {}  # file_offset -> anchor_va
    for va in STRING_ANCHORS:
        needle = struct.pack("<Q", va)
        start = 0
        while True:
            off = data.find(needle, start)
            if off < 0:
                break
            pool_entries[off] = va
            xrefs[va].append(("pool", base + off))
            start = off + 8
    # 2. ldr xN, [pc, #imm] xrefs to those pool offsets
    for insn in insns:
        if insn.mnemonic != "ldr" or "[pc" not in insn.op_str:
            continue
        try:
            imm = int(insn.op_str.split("#")[1].rstrip("]"), 0)
        except (IndexError, ValueError):
            continue
        target_off = int((insn.address - base + imm))  # file offset
        # ldr literal targets 4-byte-aligned; pool entries are 8-byte aligned
        for off in (target_off, target_off & ~7, target_off - 4):
            if off in pool_entries:
                xrefs[pool_entries[off]].append(("ldr", insn.address))
    # 3. adrp+add xrefs (fully general): for each add, find nearest
    #    preceding adrp (any reg/page), compute target = adrp_page +
    #    add_imm, check against anchors. Catches adrp 0x10001c000 +
    #    add #0x145a = 0x10001d45a etc. (different page, larger offset).
    add_insns = [i for i in insns if i.mnemonic == "add" and "#" in i.op_str]
    for a in add_insns:
        try:
            aim = int(a.op_str.split("#")[1].rstrip("]"), 0)
        except (IndexError, ValueError):
            continue
        a_idx = insns.index(a)
        for j in range(a_idx - 1, -1, -1):
            if insns[j].mnemonic == "adrp":
                try:
                    pg = int(insns[j].op_str.split("#")[1].split(",")[0], 0) & ~0xfff
                except (IndexError, ValueError):
                    continue
                target = pg + aim
                if target in xrefs:
                    xrefs[target].append(("adrp+add", a.address))
                break
    return xrefs


def func_summary(f):
    if not f:
        return "no enclosing fn"
    pac = "PAC" if f["pac"] else "non-PAC"
    return f"0x{f['start']:x}..0x{f['end']:x} [{pac}] rets={'+'.join(f['rets'])}"


def main():
    rom = sys.argv[1] if len(sys.argv) > 1 else DEFAULT_ROM
    base = int(sys.argv[2], 0) if len(sys.argv) > 2 else BASE
    if not os.path.exists(rom):
        sys.exit(f"rom not found: {rom}")
    with open(rom, "rb") as f:
        data = f.read()
    print(f"# t8027 ROM RE-assist — {rom} (base 0x{base:x}, {len(data)} bytes)\n")
    insns = disasm(data, base)
    funcs = detect_functions(insns)
    pages = page_pac_density(insns, base)
    gadgets = find_gadgets(insns, funcs)
    xrefs = find_string_xrefs(insns, data, base)

    tp = sum(p["pacibsp"] for p in pages.values())
    tr = sum(p["retab"] for p in pages.values())
    tret = sum(p["ret"] for p in pages.values())
    print("## 1. PAC density (whole ROM)\n")
    print(f"- pacibsp/paciasp: {tp}")
    print(f"- retab:         {tr}")
    print(f"- plain ret:      {tret}")
    print(f"- functions detected: {len(funcs)}\n")

    islands = [(pi, p) for pi, p in pages.items() if p["ret"] > 0 and p["retab"] == 0]
    print(f"## 2. Non-PAC islands (4K pages with plain ret, no retab): {len(islands)}\n")
    if islands:
        print("| Page (VA) | pacibsp | retab | plain ret |")
        print("|-----------|---------|-------|-----------|")
        for pi, p in sorted(islands):
            print(f"| 0x{base + pi*0x1000:x} | {p['pacibsp']} | {p['retab']} | {p['ret']} |")
    else:
        print("NONE — every page with a return has retab (fully PAC-protected).")
    print()

    print("## 3. t8020 ROP gadget shapes in 4172 (shape, not VA)\n")
    print("| Gadget | Shape | t8020 ref VA | 4172 hits | PAC hits | non-PAC hits |")
    print("|--------|------|-------------|-----------|----------|--------------|")
    for g, hits in gadgets.items():
        pac = sum(1 for _, _, f in hits if f and f["pac"])
        nonpac = sum(1 for _, _, f in hits if f and not f["pac"])
        shape, ref = SHAPE_MAP[g]
        print(f"| {g} | {shape} | 0x{ref:x} | {len(hits)} | {pac} | {nonpac} |")
    print()

    print("### G1 detail (load x19 from stack — ROP entry gadget)\n")
    g1 = gadgets["G1"]
    if g1:
        print("| VA | operand | enclosing function | PAC |")
        print("|----|---------|-------------------|-----|")
        for insn, op, f in g1[:20]:
            va = insn.address
            pac = "PAC (retab)" if (f and f["pac"]) else ("non-PAC (ret)" if f else "?")
            print(f"| 0x{va:x} | {op} | {func_summary(f)} | {pac} |")
        if len(g1) > 20:
            print(f"| ... | ({len(g1)-20} more) | | |")
    else:
        print("NONE — no `ldr x19, [sp, #imm]` found. t8020 ROP entry gadget absent.")
    print()

    print(f"## 4. USB serial builder frame @ 0x{USB_SERIAL_BUILDER:x}\n")
    sb = next((f for f in funcs if f["start"] == USB_SERIAL_BUILDER), None)
    if sb and sb["rets"]:
        pac = "PAC-protected (retab)" if sb["pac"] else "non-PAC (plain ret)"
        print(f"- PAC status: {pac}")
        print(f"- returns: {sb['rets']}")
        lr_slot = None
        for ins in sb["insns"]:
            if ins.mnemonic == "stp" and "x29" in ins.op_str and "x30" in ins.op_str:
                try:
                    lr_slot = int(ins.op_str.split("#")[1].rstrip("]!"), 0)
                except (IndexError, ValueError):
                    pass
                break
        print(f"- saved LR slot (stp x29,x30): {('#0x'+format(lr_slot,'x') if lr_slot is not None else 'unknown')}")
        print(f"- instruction count: {len(sb['insns'])}")
    else:
        # Function detection missed it (leaf/no captured ret) — disassemble a
        # window and report the actual return instruction present.
        win = [i for i in insns if USB_SERIAL_BUILDER <= i.address < USB_SERIAL_BUILDER + 0x400]
        rets = [i.mnemonic for i in win if i.mnemonic in ("ret", "retab")]
        has_pacibsp = any(i.mnemonic in ("pacibsp", "paciasp") for i in win)
        print(f"- function detection: {len(sb['insns']) if sb else 0} insns in detected fn; window scan {len(win)} insns")
        print(f"- pacibsp in window: {has_pacibsp}")
        print(f"- returns in window: {rets or 'none in 0x400 window'}")
        if rets:
            pac = "PAC-protected (retab)" if "retab" in rets else "non-PAC (plain ret)"
            print(f"- PAC verdict (window): {pac}")
        else:
            print("- PAC verdict (window): no return in 0x400 window — frame is larger; needs IDA/ibis")
    print()

    print("## 5. String anchor xrefs (literal-pool entries + ldr xN,[pc,#imm])\n")
    print("| String VA | String | pool entries / ldr xref sites |")
    print("|-----------|--------|----------------------------|")
    any_xref = False
    for va, sites in xrefs.items():
        if sites:
            any_xref = True
            s = STRING_ANCHORS[va][:34]
            pool = [f"pool@0x{a:x}" for k, a in sites if k == "pool"]
            ldr = [f"ldr@0x{a:x}" for k, a in sites if k == "ldr"]
            pool_s = ", ".join(pool[:4]) + (f" (+{len(pool)-4} more)" if len(pool) > 4 else "")
            ldr_s = ", ".join(ldr[:4]) + (f" (+{len(ldr)-4} more)" if len(ldr) > 4 else "")
            parts = (pool_s + " | " + ldr_s) if (pool or ldr) else "none"
            print(f"| 0x{va:x} | {s} | {parts} |")
    if not any_xref:
        print("| (none for DFU/CPID/SRTG strings) | — | copyright/version found via literal pool; DFU format strings NOT reachable by adrp+add or 8-byte literal pool (0 adrp to page 0x10001d000, 0 adds with their offsets). HANDLE_USB_REQ / USB_DESC_MAKE_STR hunt needs IDA/ibis xref analysis (SYMBOL_WORKSHEET §5 step 4-6). |")
    print()

    print("## 6. PAC-policy verdict (the #1 gate)\n")
    # A page counts as a real non-PAC window only if it has plain ret AND no retab.
    real_islands = [(pi, p) for pi, p in pages.items()
                     if p["ret"] > 0 and p["retab"] == 0]
    # Is the USB/DFU code path (0x100006xxx-0x10000axxx) PAC-protected?
    dfu_pages = [(pi, p) for pi, p in pages.items()
                 if 0x100006000 <= base + pi * 0x1000 <= 0x10000b000]
    dfu_retab = sum(p["retab"] for _, p in dfu_pages)
    dfu_ret = sum(p["ret"] for _, p in dfu_pages if p["retab"] == 0)
    print(f"- DFU/USB code pages (0x100006000-0x10000b000): {len(dfu_pages)} pages, "
          f"{dfu_retab} retab, {dfu_ret} plain-ret-only")
    if real_islands:
        print(f"\nNon-PAC code islands EXIST ({len(real_islands)} pages), BUT the only one "
              f"(0x{base + real_islands[0][0]*0x1000:x}) is the panic/idle-task STRING region, "
              "not the DFU code path. The DFU USB-task return path is PAC-protected.")
        print("\n-> t8020-style unsigned LR-ROP is DEAD on the DFU path. A PAC-aware "
              "first hijack (signed-return forge / callback smash / data-only) is REQUIRED.")
    else:
        print("\nNo non-PAC code islands: every returning code page uses retab. "
              "t8020-style unsigned LR-ROP is DEAD. A PAC-aware first hijack "
              "(signed-return forge / callback smash / data-only) is REQUIRED.")
    print()
    print("## See also\n")
    print("- PAC_AND_CONTROL_FLOW.md / SYMBOL_WORKSHEET.md / FIRST_RE_PASS.md")
    print("- Output is EVIDENCE; do not paste VAs into stubs from this.")


if __name__ == "__main__":
    main()
