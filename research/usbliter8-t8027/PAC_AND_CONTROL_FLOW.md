# t8027 PAC + control-flow problem (research only)

**Date:** 2026-08-03  
**Depends on:** [FIRST_RE_PASS.md](FIRST_RE_PASS.md), [SYMBOL_WORKSHEET.md](SYMBOL_WORKSHEET.md)  
**ROM:** `SecureROM_t8027_4172.bin` (SHA-256 `22386685…7a8baf`)  
**Status:** analysis plan — **no stub fills; no Pico attempt claimed; THEORY labeled**

VA load base assumed `0x100000000`. Confirm in ibis/IDA.

---

## Scope / non-claims

- No claim that usbliter8 pwns A12X / t8027.
- Confirmed PAC density (from first pass): `pacibsp` ×462, `retab` ×364, plain `ret` ×282 on t8027 vs **zero** `pacibsp`/`retab` on teacher t8020 `3865.0.0.4.7`.
- Upstream “A12 SecureROM has no PAC” describes **t8020**, not this **t8027** image.
- t8030’s `WITH_PAC` handler path is a **teacher only** (`usb_req_handler/handler.c`); not proof of a t8027 strategy.
- Do not write candidates into [`stubs/`](stubs/). Do not touch `boot/`.

---

## 1. Why PAC density matters for a t8020-style port

### What the t8020 path assumes

On t8020, usbliter8’s A12 path roughly:

1. DWC2 DMA underflow → corrupt USB-task stack / heap in SRAM.
2. Overwrite a saved **LR** (and build a short ROP) with **raw** code pointers.
3. Return / chain into shellcode that patches the USB request handler.
4. Plant a handler that, on `CUSTOM_BOOT`, writes **unsigned** `JUMP_AWAY` into `MAIN_TASK_STACK_LR` (`WITH_PAC` off).

That model needs: stack return addresses that are **not** authenticated on use.

### What t8027 shows instead

| Observation | Implication for t8020-style port |
|-------------|----------------------------------|
| Pervasive `pacibsp` / `retab` | Function returns authenticate LR (key B, SP modifier) — smashing LR with a raw gadget VA is expected to **fault** on `retab` |
| USB serial builder @ `0x1000067bc` starts with `pacibsp` | Hot DFU/USB path is inside the PAC regime, not a leftover non-PAC island |
| Still many plain `ret` (282) | Early boot / EL1 helper islands exist — **not** automatically the USB-task return path |
| Teacher t8020 gadgets at same VAs are wrong code here | Even ignoring PAC, ROP LRs must be re-found |

**Bottom line:** SRAM layout similarities (`JUMP_STATE`, `0x19C0…` banks) do **not** rescue a blind copy of `t8020_create_overwrite`. Control-flow takeover is a separate, PAC-shaped problem.

---

## 2. Plausible strategies on a PAC-heavy SecureROM

Everything in this section is **THEORY — unconfirmed** unless marked otherwise.

### A. Signed-return / `PACIB` forge (t8030-shaped teacher)

**Idea:** When installing a fake LR (ROP or `CUSTOM_BOOT` stack poke), store a pointer signed with the same key/context the consumer will authenticate — e.g. handler does `PACIB(JUMP_AWAY, MAIN_TASK_STACK_LR+8)` when `WITH_PAC` (see upstream `handler.c`).

**Would need to be true:**

- Know which PAC key (A/B) and modifier (SP, disc, etc.) the target `retab` / `autib` uses.
- Ability to execute or reuse a signing gadget/`PACIB` before the authenticating return (shellcode already running, or a useful non-auth window).
- Correct `MAIN_TASK_STACK_LR` (SRAM) once mapped.

**Risks:** Wrong context → immediate auth fail. t8030 offsets/gadgets do not apply.

### B. Limited non-PAC windows

**Idea:** Prefer corruption of frames that still use plain `ret`, or overwrite a **function pointer / callback** that is loaded and `blr`’d without auth (not LR).

**Evidence so far:** plain `ret` sites cluster in early/system-register helpers; USB path around `0x100006xxx` is PAC-rich (`pacibsp` 18 / `retab` 15 in that 4K alone).

**THEORY — unconfirmed:** DFU USB-task LR may still be PAC’d; non-PAC `ret` islands may be useless for the race’s actual victim frame. Must identify the **exact** saved LR / FP the DMA underflow hits.

### C. Alternate control-flow (not classic LR ROP)

**THEORY — unconfirmed** options to investigate only after victim-object ID:

| Class | Sketch | Needs |
|-------|--------|-------|
| Callback / vtable smash | Overwrite `USB_REQ_HANDLER_CB`-class SRAM pointer with raw or signed code ptr | Find store/load sites; auth policy on `blr` |
| Exception / IRQ path | Divert a handler registered in BSS | Rare in SecureROM DFU; high uncertainty |
| Trampoline / PTE path | Abuse boot-tramp mapping once EL1 reached | Already part of t8020 *after* PC control — not a substitute for first hijack |
| Data-only → later PAC bypass | Corrupt state so a legitimate signed return lands in attacker-controlled continuation | Speculative; no evidence yet |

### D. “Ignore PAC / hope LR raw works”

**Not a strategy.** Given measured `retab` density, treat as **disproven assumption** for planning until a specific victim return is shown to use plain `ret`.

### E. Hybrid (most realistic planning frame)

**THEORY — unconfirmed:**

1. Keep DWC2 race + `0x19C0` SRAM geometry as the *memory* story (partially evidenced).
2. Replace t8020 ROP with a PAC-aware first hijack (A or C).
3. Once shellcode runs, plant a handler compiled with a t8027 `WITH_PAC`-style path (teacher: t8030 `handler.c`), not the t8020 unsigned LR write.

---

## 3. Analysis plan for the three flagged addresses

### `0x100001944` — `JUMP_STATE` materialization / early map loop

**Already confirmed nearby:** `adrp/add` → `0x19C014030` (`JUMP_STATE`).

**Look for in ibis/IDA:**

| Question | Why |
|----------|-----|
| Function bounds / callers of the `svc #0` block just above | Privilege / EL transitions around state setup |
| What `bl 0x1000097e8` does with `x0 = JUMP_STATE` | Init vs consume |
| Loop using `x22 ≈ 0x19C020000`, `x20 = 0x19C014038` | Page-table / remapping teacher for tramp |
| Any PAC prolog on this function | Whether early boot here is non-PAC |

**Exit:** Document function name/role; list SRAM VAs touched; note PAC or not on this frame.

### `0x100008180` — SRAM region table (data, not code)

**Confirmed literals** (qword table; disassembly as code is misleading):

```text
0x19C00C000, 0x19C018000, 0x19C028000, 0x19C030000,
0x19C01C000, 0x19C020000, ...
```

**Look for:**

| Question | Why |
|----------|-----|
| Xrefs via `ldr xN, =` / literal pools to each qword | Who treats `0x19C018000` as tramp vs BSS end |
| Pairing with clear loop @ ~`0x100007f4c`–`0x100007f88` | Confirms region roles |
| Any table entry usable as `shc_base` / heap bank proof | Feeds config blob THEORY |
| Absence of USB MMIO constants here | Reinforces MMIO still unknown |

**Exit:** Role label per region; promote or demote `TRAMP_BASE`/`NEW_SP` bank THEORIES in the worksheet (still not stub fills).

### `0x1000067bc` — USB serial / DFU string builder (`pacibsp`)

**Confirmed:** formats CPID line + `SRTG:[%s]`; calls `0x1000115a8` / `0x1000116c8`; uses SRAM `0x19C00C000` / `0x19C010000`; PAC prolog + expect matching `retab`.

**Look for:**

| Question | Why |
|----------|-----|
| Full xref graph: who calls `0x1000067bc` | Path from USB enum / DFU setup |
| Callees: demote, remote-boot, descriptor makers | Handler offset worksheet |
| Where the built serial lands (`USB_SN_STR` class) | SRAM string slot |
| Stack frame layout: saved LR slot offset, canary @ `-0x48` from `x29` loading `*[0x19C00C000+0x450]` | Cleanup / canary THEORY |
| Whether any callee returns with plain `ret` | Non-PAC window hunt |
| Cross-link to DFU site `0x10000ad58` | Toward `HANDLE_USB_REQ` |

**Exit:** Call graph sketch; candidate renames only with evidence; PAC verdict for this frame (**already PAC’d**).

---

## 4. Updated SYMBOL_WORKSHEET priority (given PAC)

Reorder effort — highest first:

| Priority | Item | Rationale |
|----------|------|-----------|
| 1 | **Victim control-flow object** under DFU race (which LR / callback; PAC or not) | Gates all ROP |
| 2 | **PAC policy** for that object (key, modifier, `retab` vs `blr`) | Gates gadget form |
| 3 | `HANDLE_USB_REQ` + plant site (`USB_REQ_HANDLER_CB_ADDR`) | Post-pwn I/O |
| 4 | `PLATFORM_DEMOTE` / `PLATFORM_SET_REMOTE_BOOT` / `JUMP_AWAY` | Handler usefulness |
| 5 | Signing primitive or signed-pointer write path (`PACIB` teacher) | If PAC required for LR |
| 6 | `JUMP_STATE` (done) + validate `TRAMP_BASE` `0x19C018000` | Shellcode plant |
| 7 | `NEW_SP` / `ov_start` in `0x19C028000` bank | Overwrite packing |
| 8 | USB MMIO (`USB_DMA_DEST`) — still **no `0x2391` evidence** | Race DMA redirect |
| 9 | Heap `blocks.S` / cleanup literals | Stability after hijack |
| 10 | `delay` retune | Last; hardware |

**Deprioritize:** copying t8020 ROP gadget VAs; assuming unsigned `MAIN_TASK_STACK_LR` write like t8020 handler.

---

## 5. What must be true before a Pico payload attempt is worth trying

A Pico UF2 attempt is **not** justified by DFU identity + SRAM resemblance alone. Minimum bar (research checklist):

1. **Victim identified:** Evidence which stack/callback the DWC2 underflow hits on t8027 DFU (not “probably like t8020”).
2. **PAC model for that victim:** Either (a) plain `ret` / unauthenticated `blr`, or (b) a concrete signing/context plan with at least one worked example in RE (not production pwn).
3. **ROM symbols for the chosen strategy:** Enough gadgets or callback targets for a *minimal* hijack — not the full worksheet.
4. **Shellcode plant region:** Validated writable execute path (e.g. tramp bank THEORY confirmed) compatible with the hijack.
5. **USB MMIO redirect:** A defended candidate for DMA destination register (currently **missing**).
6. **Failure telemetry:** Pico logs + LED meaning; willingness to treat non-PWND as expected.
7. **No stub self-deception:** Offsets in any local experiment tree labeled THEORY until PWND serial appears; still **no** claim of success without `PWND:[usbliter8]` on `CPID:8027`.

Until (1)–(5) have evidence, prefer ibis/worksheet work over flashing speculative overwrite blobs.

---

## 6. CONFIRMED — PAC-policy verdict (automated static RE-assist, 2026-08-08)

The #1 gate ("blocks entire ROP strategy") is now **answered by automated static
analysis**, not THEORY. Tool: [`tools/rom_re_assist.py`](tools/rom_re_assist.py)
(capstone, `skipdata=True`). Report:
[`experiments/logs/rom_re_assist-20260808-160259.md`](experiments/logs/rom_re_assist-20260808-160259.md).

### Evidence

- PAC density reproduces FIRST_RE_PASS §1 exactly: `pacibsp` ×462,
  `retab` ×364, plain `ret` ×282 (tool sanity-pass).
- **Non-PAC code islands: 1 page only** — `0x10001d000` — and it is the
  panic/idle-task **STRING** region (`"double panic in"`, `"panic: "`,
  `"constructing idle task"`, `"idle task"` live there), NOT code.
- **DFU/USB code pages `0x100006000`–`0x10000b000`: 6 pages,
  114 `retab`, 0 plain-ret-only.** Every return on the DFU code path
  authenticates LR.
- USB serial builder frame @ `0x1000067bc` (FIRST_RE_PASS confirmed): window
  scan shows `pacibsp` present, returns = `['retab','retab','retab']` ->
  **PAC-protected (retab)**. The hot DFU/USB path is inside the PAC regime.
- t8020 ROP gadget *shapes* do exist in 4172 (G1 `ldr x19,[sp,#imm]` ×5,
  G2 ×249, G3 ×34, G4 ×7, G5 ×1, G6 ×88) but the G1 hits on the DFU-relevant
  pages are all inside `retab`-returning functions. The 2 non-PAC G1 hits
  (`0x10000c310`, `0x100018628`) are outside the DFU code range.

### Verdict

**t8020-style unsigned LR-ROP is DEAD on the t8027 DFU path.** Smashing a
saved LR with a raw gadget VA faults on `retab`. A **PAC-aware first hijack
is REQUIRED** — strategy A (signed-return / `PACIB` forge), C (callback /
function-pointer smash loaded via unauthenticated `blr`), or E (data-only
-> later signed return). This kills planning assumption D ("ignore PAC /
hope LR raw works") and deprioritizes copying t8020 ROP gadget VAs.

### What this unblocks

- The port is NOT blocked — it is redirected. The memory story (DWC2 race +
  `0x19C0` SRAM geometry, `JUMP_STATE` confirmed) is still viable; only
  the first-hijack control-flow shape changes from t8020 LR-ROP to a
  PAC-aware path.
- Next highest-priority worksheet rows (PAC_AND_CONTROL_FLOW §4): #1 victim
  control-flow object (now: a callback / function pointer, not a saved LR),
  #2 PAC model for that object (which PAC key/modifier, or is it an
  unauthenticated `blr`), #5 signing primitive / signed-pointer write path.
- The `rom_re_assist.py` string-xref map (section 5) is currently empty
  (ADRP+ADD finder bug) — does not block the PAC verdict but should be
  fixed to bootstrap the `HANDLE_USB_REQ` / `USB_DESC_MAKE_STR` hunt (§4.6).

### Re-prioritized worksheet (post-PAC-verdict)

The confirmed verdict changes the priority order from PAC_AND_CONTROL_FLOW §4. Old
#1 (victim LR / PAC or not) is ANSWERED: the DFU victim return is `retab`, so a
saved LR is NOT the victim. Smashing a saved LR faults. The first
hijack must target a callback / function pointer loaded via unauthenticated `blr`, or a data-only corruption that diverts a legitimate signed return.

New priority (highest first):

| Pri | Item | Rationale (post-verdict) |
|-----|------|--------------------------|
| 1 | **Victim = callback / function pointer** (not a saved LR). Find `USB_REQ_HANDLER_CB`-class SRAM pointer; its store/load sites; whether the consuming `blr` is authenticated (`PACIB` on load) or plain `blr`. | Smashed LR faults on `retab`; a callback loaded+`blr`'d may not be authenticated. |
| 2 | **PAC model for that callback** (which PAC key/modifier, or unauthenticated `blr`). | Gates gadget form (signed-pointer forge vs raw pointer). |
| 3 | **Signing primitive / signed-pointer write path** (t8030 `PACIB` teacher, `handler.c`). | Needed only if the callback `blr` is authenticated. |
| 4 | `HANDLE_USB_REQ` + plant site (`USB_REQ_HANDLER_CB_ADDR`). | Post-pwn I/O; needs IDA/ibis (DFU string xrefs not reachable by static capstone — rom_re_assist §5). |
| 5 | `PLATFORM_DEMOTE` / `PLATFORM_SET_REMOTE_BOOT` / `JUMP_AWAY`. | Handler usefulness. |
| 6 | `JUMP_STATE` (done, 0x19C014030) + validate `TRAMP_BASE` 0x19C018000. | Shellcode plant region. |
| 7 | `NEW_SP` / `ov_start` in 0x19C028000 bank. | Overwrite packing (needs DFU heap map). |
| 8 | USB MMIO (`USB_DMA_DEST`) — still no `0x2391` evidence. | Race DMA redirect (find DWC2 DOEPDMA without assuming 0x2391). |
| 9 | Heap `blocks.S` / cleanup literals. | Stability after hijack. |
| 10 | `delay` retune. | Last; hardware. |

**Killed:** copying t8020 ROP gadget VAs; assuming unsigned `MAIN_TASK_STACK_LR` write like t8020 handler; planning assumption D ("ignore PAC").

**Unblocked by rom_re_assist (evidence):** the G1 `ldr x19,[sp,#imm]` gadget hits on the DFU-relevant pages are all inside `retab`-returning functions, so the t8020 ROP entry gadget is genuinely unusable on the DFU path — not just "probably." The 2 non-PAC G1 hits (`0x10000c310`, `0x100018628`) are outside the DFU code range.

## See also

- [FIRST_RE_PASS.md](FIRST_RE_PASS.md) — PAC counts, region table, string xrefs  
- [SYMBOL_WORKSHEET.md](SYMBOL_WORKSHEET.md) — row tracking  
- [OFFSET_DERIVATION.md](OFFSET_DERIVATION.md) — derive order  
- Upstream teacher (PAC handler shape only): `upstream/usbliter8/usb_req_handler/handler.c` (`WITH_PAC`)
