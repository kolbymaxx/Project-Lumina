# T3 — Callback / function-pointer smash (research note)

**Date:** 2026-08-03  
**Status:** THEORY — unconfirmed  
**Parent:** [PAC_THEORY_MATRIX.md](PAC_THEORY_MATRIX.md) §T3 (ranked #1 shortlist)  
**ROM:** `research/usbliter8-t8027/artifacts/SecureROM_t8027_4172.bin`  
**SHA-256:** `223866855772be24ac57d4ac0033fd6f99012a2e94646b9e2094b3adee7a8baf`  
**Supports:** [FIRST_RE_PASS.md](FIRST_RE_PASS.md), [PAC_AND_CONTROL_FLOW.md](PAC_AND_CONTROL_FLOW.md), [SYMBOL_WORKSHEET.md](SYMBOL_WORKSHEET.md)

VA load base assumed `0x100000000`. Confirm in ibis/IDA.  
**Non-claims:** no A12X pwn; no stub fills; no experiment READY; no invented “confirmed” CB addresses.

---

## 1. Theory statement

**THEORY — unconfirmed:** On t8027 SecureROM DFU, a more promising first control-flow object than a saved LR is a **mutable SRAM function pointer** (callback / handler CB / vtable-like slot) that USB/DFU code later loads and branches to (`blr`, or an authenticated branch variant).

Teacher *role* (not VA): t8020’s `USB_REQ_HANDLER_CB_ADDR` — a planted callback the USB stack invokes on control requests. Worksheet row exists; t8027 candidate is still `TODO — derive` ([SYMBOL_WORKSHEET.md](SYMBOL_WORKSHEET.md) §4.3).

T3 does **not** claim that slot is at t8020’s `0x19C010C68`. It claims the *object class* is worth hunting before raw LR ROP.

---

## 2. Why CB smash beats raw LR ROP here

### Confirmed PAC pressure on returns

| Observation | Source | Effect on LR ROP |
|-------------|--------|------------------|
| `pacibsp` ×462 / `retab` ×364 (t8020: 0 / 0) | FIRST_RE_PASS §1 | Saved LR is authenticated on use |
| USB serial builder `@0x1000067bc` starts with `pacibsp` | FIRST_RE_PASS §2; PAC_AND_CONTROL_FLOW §1 | Hot USB path is PAC’d |
| ~18 `pacibsp` / ~15 `retab` in `0x100006xxx` 4K | PAC_AND_CONTROL_FLOW §2.B | Race-adjacent code is not a non-PAC island |

Raw LR overwrite with a gadget VA is expected to **fault on `retab`**, not transfer PC ([PAC_THEORY_MATRIX.md](PAC_THEORY_MATRIX.md) §1). That is a hard planning constraint, not a vibe.

### Why a callback is a different problem

| Property | Saved LR + `retab` | SRAM FP + `blr` / auth-branch |
|----------|--------------------|-------------------------------|
| Auth on use | Almost always (this ROM) | **Unknown per site** — must measure |
| Where it lives | Stack frame (often) | Often a **fixed SRAM slot** (teacher pattern) |
| Overwrite shape | Need correct frame + signing or plain-`ret` | May be a single qword in a known bank |
| Post-plant reuse | Handler still needs PAC-aware LR poke on t8027 | Same CB slot is what usbliter8 *wants* to own on t8020 |

**THEORY — unconfirmed:** if the DFU request path does `ldr xN, [sram_cb]; blr xN` (or equivalent) **without** authenticating the pointer the way `retab` authenticates LR, then corrupting that qword is a shorter path to PC control than forging PAC for every return.

Even if the call site uses `blraa`/`blrab` / signed FP, T3 still matters: the forge surface may be “sign once into a durable SRAM slot” rather than “sign every ROP link,” which is closer to the t8030 `WITH_PAC` teacher than to t8020 unsigned LR smash ([PAC_AND_CONTROL_FLOW.md](PAC_AND_CONTROL_FLOW.md) §2.A/C).

### What T3 is *not*

- Not “SRAM under `0x19C010000` is the CB” (busy ADRP ≠ identified pointer).
- Not “copy t8020 `0x19C010C68`”.
- Not a reason to skip finding USB MMIO / underflow reachability — without a write primitive that can hit the slot, T3 stays offline.

---

## 3. Anchors already in evidence (start here — do not invent)

These are **confirmed or high-confidence RE entry points**, not confirmed CB addresses.

| Anchor | Status | Why it matters for T3 |
|--------|--------|------------------------|
| `@0x1000067bc` USB serial / DFU string builder | Confirmed `pacibsp`; formats CPID + `SRTG:[%s]`; uses `0x19C00C000` / `0x19C010000` | Callers = USB enum / DFU setup graph; callees may register handlers |
| `@0x10000ad58` second DFU-string site | Confirmed string/code site (FIRST_RE_PASS) | Ranked path toward `HANDLE_USB_REQ` |
| `@0x1000115a8` / `@0x1000116c8` | Plausible format/append helpers from serial builder | Side graph only — useful for naming, not CB itself |
| ADRP traffic to `0x19C010000` (and neighbors) | Confirmed heavy use | **Hunt zone** for SRAM pointer slots — not a symbol |
| Region table `@0x100008180` | Confirmed literals include `0x19C00C000`…`0x19C028000`… | Bounds which banks are plausible for durable CBs |
| `JUMP_STATE == 0x19C014030` | Confirmed | Context for early map; unlikely the CB itself |
| `USB_DMA_DEST` / `0x2391…` | **No evidence** | Do not seed; T3 can proceed on *ROM load/store* of CBs while MMIO stays open |

Teacher role list (structure only): `HANDLE_USB_REQ`, `USB_REQ_HANDLER_CB_ADDR`, `USB_DESC_MAKE_STR`, demote / remote-boot — see worksheet §4.3 / §4.6. Fill candidates only with new evidence.

---

## 4. Offline RE plan against `SecureROM_t8027_4172.bin`

### 4.1 Preflight

```bash
ROM=research/usbliter8-t8027/artifacts/SecureROM_t8027_4172.bin
shasum -a 256 "$ROM"
# expect: 223866855772be24ac57d4ac0033fd6f99012a2e94646b9e2094b3adee7a8baf
strings -a -t x "$ROM" | rg 'DFU Mode|CPID:%04X|SRTG:|NONC:|Apple Mobile Device|idle task|IMG4|panic'
```

Load with ibis (or equivalent) at SecureROM base `0x100000000`.

### 4.2 Strings / constants to hunt first

Priority order:

1. **`Apple Mobile Device (DFU Mode)`** / **`CPID:%04X…`** / **` SRTG:[%s]`** — already located; walk *xrefs to code*, then *callers of those functions*.
2. **`NONC:` / `SNON:`** — same identity block; often adjacent to USB string assembly.
3. Request-path hints if present (exact spelling varies): DFU state names, `GET_STATUS`-class logic may be **stringless** — do not stall on missing ASCII.
4. **`panic:` / `double panic in `** — note sites that abort on bad function pointers (falsifier signal if CB is checksummed).
5. Avoid wasting time on copyright / `ROMRELEASE` for T3 (identity only).

### 4.3 Code patterns to hunt first

In IDA/BN, prefer pattern search + xref over guessing VAs:

| Pattern | What to record |
|---------|----------------|
| `adrp`/`add` or literal load → address in `0x19C010000`–`0x19C011FFF` (expand if needed) | Every site; classify load vs store |
| `ldr xN, [xM]` / `ldr xN, [xM, #imm]` where base is that SRAM page, followed within a few insns by `blr xN` | **Primary T3 hit class** |
| Same but `blraa` / `blrab` / `braa` / `brab` | Auth-FP variant — still T3, harder |
| `str xN, [sram…]` where `xN` holds a **ROM code pointer** (`0x1000xxxxx`) | Candidate **registration** / plant site |
| Indirect call through a small ROM table of code pointers (constant pool) with index from SRAM | May collapse to T4 (selector); note and park |
| Compare epilogue: `retab` vs plain `ret` on functions that *call through* the CB | Separates “PAC on return” from “PAC on FP” |

**Explicit non-pattern:** do not search for t8020’s `0x19C010C68` as a literal and call it confirmed.

### 4.4 Structures / object shapes (conceptual)

Expect (THEORY — unconfirmed) something like:

```text
USB / DFU device object in SRAM
  ...
  +off  request_handler_fn   ; qword, ROM VA or signed ptr
  +off  interface / ep state
  +off  descriptor / serial pointers → 0x19C00C000-class buffers
```

Or a global:

```text
g_usb_req_handler_cb  @ unknown 0x19C01xxxx
```

On t8020 the global form is what usbliter8 patches. t8027 may use either. Record:

- Slot VA (when found)
- Writer(s) and whether write happens at USB init vs per-request
- Reader(s) and branch opcode
- Whether value is ever PAC-signed before store

### 4.5 Concrete navigation sequence (ibis/IDA)

Do in order; stop and log when a kill criterion hits.

1. **Open `@0x1000067bc`** — confirm PAC prolog; list all `bl` targets; list all ADRP targets into `0x19C0…`.
2. **Xrefs → who calls `0x1000067bc`** — build upward graph toward USB configuration / DFU setup.
3. **Open `@0x10000ad58`** — define function; same ADRP/store/load audit; cross-link to step 2’s graph.
4. **For each store of a `0x1000…` code pointer into `0x19C0…`**, create a worksheet row: `CB_CANDIDATE_n` with evidence (file VA of `str`, destination SRAM VA, value source).
5. **For each candidate, find all loads** — require at least one call/branch through the loaded value for the row to stay alive.
6. **Classify auth:** raw `blr` vs authenticated branch vs “loaded but only compared/stored.”
7. **Only then** ask whether the DWC2 underflow *could* reach that SRAM (needs heap/stack/DMA map — may remain open; do not invent `0x2391`).
8. Optional side-by-side t8020: compare *roles* of handler registration — never copy VAs into stubs.

### 4.6 Deliverables of the offline pass (no stubs)

Update notes only (SYMBOL_WORKSHEET / this file’s log section):

- 0+ `CB_CANDIDATE` rows with: SRAM VA, store site, load+branch site, auth class, DFU-reachable? (yes/no/unknown)
- Explicit kill of T3 if zero durable mutable FPs on the DFU path
- Cross-link to T1 if every interesting branch authenticates and no forge path appears

---

## 5. Evidence bar for a future live DRAFT candidate

Creating a harness **DRAFT** (Status still not READY) is justified only when **all** of the following are true:

1. **Named slot:** one SRAM VA with evidenced `str` of a code pointer and evidenced load+branch (not “busy page”).
2. **Auth class recorded:** `blr` vs `blraa`/`blrab`/other — determines whether payload needs a signed pointer (T1 hybrid) or raw ROM VA.
3. **Observable chosen:** a *benign* target for the first live try — e.g. point CB at an existing ROM routine that mutates serial/USB in a predicted way — **not** full shellcode / PWND plant on first shot.
4. **Write story sketched:** THEORY for how the race/overwrite reaches that qword (even if MMIO base still TBD) — or an alternate non-race write if RE finds one (unlikely in DFU).
5. **Falsifiable expected observable** written in the candidate (harness classes: `NO_EFFECT` / `USB_ANOMALY` / `PWND` / `ERROR`).
6. **C002-class baseline** still green (stable unpwned DFU) so deltas are meaningful.

**Still forbidden at DRAFT time:** stub `#define`s, READY flag, Pico spray, claiming PWND.

**READY** (later, separate human decision) additionally needs: one prepared payload, one action (`manual_pico` or future host action), cable notes, and acceptance that non-PWND is the default outcome.

---

## 6. Fast falsifiers (kill T3 quickly)

Any one of these should demote or kill T3 as primary:

| Falsifier | Meaning |
|-----------|---------|
| No `str` of ROM code ptrs into mutable `0x19C0…` on USB/DFU graph | No registration surface |
| Loads exist but never branch through the value | Not a CF object (data-only) |
| Every call site uses authenticated branch **and** stores are integrity-protected / re-signed from ROM-only secrets we cannot forge | Collapses to “need T1-level forge” or dead |
| Slot is write-once at boot then relocated to RO mapping before DFU | Not race-reachable |
| Underflow reachability RE shows CB bank outside corruptible window (once DMA/stack map exists) | Offline-interesting, live-useless for race |
| Corrupting the slot in a careful offline model only hits `panic` paths | Too brittle for a first live probe |

Weak / non-falsifiers (do not kill early):

- Absence of ASCII “handler” strings
- t8020 CB VA not present as literal
- Missing `0x2391` MMIO (blocks live race packaging, not the ROM-side CB hunt)

---

## 7. Relationship to other theories

| Theory | Interaction with T3 |
|--------|---------------------|
| **T1** signed LR | Fallback if victim is LR; also may be required if CB call sites authenticate FPs |
| **T2** plain-`ret` | Parallel kill/keep on USB-task epilogue; does not replace CB hunt |
| **T4** selector corruption | If “CB” is really an index into a ROM table, reclassify as T4 |
| **T6** DFU soft targets | Buffer/descriptor corruption may *reach* the CB object or only affect host-visible data — keep separate |
| **T7** hybrid | Preferred program: prove T3 slot → package under hybrid memory story |

---

## 8. Working log (fill during RE — leave empty until evidence)

| Date | Candidate | SRAM VA | Store site | Load+branch | Auth | Notes |
|------|-----------|---------|------------|-------------|------|-------|
| — | — | — | — | — | — | no CB candidates yet |

---

## See also

- [PAC_THEORY_MATRIX.md](PAC_THEORY_MATRIX.md) — T3 summary + shortlist  
- [PAC_AND_CONTROL_FLOW.md](PAC_AND_CONTROL_FLOW.md) §2.B/C, §3 (`0x1000067bc`, `0x10000ad58`)  
- [FIRST_RE_PASS.md](FIRST_RE_PASS.md) §2 usb_req_handler, §3 ranked targets 4–6  
- [SYMBOL_WORKSHEET.md](SYMBOL_WORKSHEET.md) `USB_REQ_HANDLER_CB_ADDR` / `HANDLE_USB_REQ` rows  
- [experiments/README.md](experiments/README.md) — DRAFT → READY discipline (do not READY from this note)
