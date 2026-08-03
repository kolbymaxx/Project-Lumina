# t8027 SecureROM — first RE pass

**Date:** 2026-08-03  
**ROM:** `research/usbliter8-t8027/artifacts/SecureROM_t8027_4172.bin`  
**SHA-256:** `223866855772be24ac57d4ac0033fd6f99012a2e94646b9e2094b3adee7a8baf`  
**Teacher compare:** securerom.fun `SecureROM for t8020si, iBoot-3865.0.0.4.7` (local analysis only)  
**Status:** research findings — **pwn not claimed; stubs not filled; THEORY labeled**

Load assumption for VAs below: image base `0x100000000` (file offset + base). Confirm in ibis/IDA before trusting.

---

## Scope / non-claims

- No claim that usbliter8 works on A12X.
- **Confirmed** = observed in this binary (string / insn / literal).
- **THEORY — unconfirmed** / **plausible candidate — needs validation** = structural inference; do **not** write into [`stubs/`](stubs/).
- Do not touch `boot/` or live exploit paths.

---

## 1. String & constant reconnaissance

### High-signal strings (file offset → VA @ `0x100000000`)

| File off | VA | String |
|----------|-----|--------|
| `0x200` | `0x100000200` | `SecureROM for t8027si, Copyright 2007-2017, Apple Inc.` |
| `0x240` | `0x100000240` | `ROMRELEASE` |
| `0x280` | `0x100000280` | `iBoot-4172.0.0.100.14` |
| `0x1d450` | `0x10001d450` | `IMG4` / `IM4P` |
| `0x1d45a` | `0x10001d45a` | `Apple Mobile Device (DFU Mode)` |
| `0x1d479` | `0x10001d479` | `CPID:%04X CPRV:%02X CPFM:%02X SCEP:%02X BDID:%02X ECID:%016llX IBFL:%02X` |
| `0x1d4c2` | `0x10001d4c2` | ` SRTG:[%s]` |
| `0x1d4cd` / `0x1d4d9` | … | ` NONC:` / ` SNON:` |
| `0x1d4e0` | `0x10001d4e0` | `double panic in ` |
| `0x1d4f5` | `0x10001d4f5` | `panic: ` |
| `0x1d500` | `0x10001d500` | `constructing idle task` |
| `0x1d518` | `0x10001d518` | `idle task` |
| `0x21e93` | `0x100021e93` | `Apple Secure Boot Root CA - G21` |
| `0x24618` | `0x100024618` | `bootstrap` |

Compared to t8020 `3865.0.0.4.7`: same *roles* and similar packing; DFU/CPID/SRTG block sits ~`0x1000` higher on t8027 (`0x1d45a` vs `0x1c25a`). Copyright / `ROMRELEASE` / version still at `0x200` / `0x240` / `0x280`.

### Build / identity constants

- Pointer at `0x100000310` → `0x100000280` (version string) — used when appending `SRTG:[…]`.
- DFU PID helper near `0x100006790`: builds `0x1226 + (x & 3)` → **0x1227** DFU product id (matches live `05ac:1227`).
- Image content ends ~`0x2492f`; file padded with zeros to **163840** (`0x28000`). Teacher t8020 image is **524288** bytes — different ROM footprint, not a simple truncated copy of the t8020 dump.

### PAC / return auth (important divergence)

| Mnemonic / encoding | t8027 count | t8020 (3865.4.7) |
|---------------------|-------------|------------------|
| `pacibsp` (`0xD503237F`) | **462** | **0** |
| `retab` (`0xD65F0FFF`) | **364** | **0** |
| plain `ret` | 282 | 625 |

**Confirmed:** t8027 SecureROM is **PAC-heavy**. Upstream write-up’s “A12 has no PAC in SecureROM” describes **t8020**, not this t8027 image.

**THEORY — unconfirmed:** the t8020 non-PAC ROP/LR-overwrite path may **not** drop in. Evaluate PAC-aware strategies (t8030-class lessons as *teachers only*) before assuming stack LR smash equals PC control. Sparse `pacib`/`autib` also present; full policy needs IDA/ibis review.

---

## 2. High-probability structural matches

### Config blob / SRAM cluster

| Expect | Confidence | Notes |
|--------|------------|-------|
| Shared `t8020_t8006_*` race *shape* | Medium (design) | Same DWC2 class; still unimplemented for 8027 |
| SRAM window under `0x19C0_xxxx` | **High (confirmed ADRP traffic)** | Heavy `ADRP` to `0x19C00C000`, `0x19C010000`, `0x19C011000`, `0x19C014000`, `0x19C012000` |
| `JUMP_STATE == 0x19C014030` | **High (confirmed)** | At `0x100001944`: `adrp x0,#0x19c014000` / `add x0,x0,#0x30` |
| `TRAMP_BASE` / `shc_base == 0x19C018000` | **plausible candidate — needs validation** | Appears in BSS/region table at `0x100008188`; early clear loop uses it as **end** of a zeroed range starting `0x19C00C000` (same role as tramp base on t8020) |
| Heap/stack bank `0x19C028000` | **plausible candidate — needs validation** | Same table (`0x100008190`); t8020 `NEW_SP` `0x19C028BC0` would live in this bank if layout matches |
| Exact `ov_start` / `shc_start` / `ov_size` | Low / unknown | No literal `0x19C02960C` etc. found; need DFU heap map |

Region table (confirmed literals @ `0x100008180`):

```text
0x19C00C000, 0x19C018000, 0x19C028000, 0x19C030000,
0x19C01C000, 0x19C020000, ...
```

### ROP / overwrite frame

| Expect | Confidence | Notes |
|--------|------------|-------|
| Same gadget *roles* (load X19 / W8 / store / sleep / EL1) | Medium structure | Family path — **addresses differ** (spot-check: t8020 VAs are different code on t8027) |
| Plain LR overwrite without PAC | **Low for t8027** | Mass `pacibsp`/`retab` — see §1 |
| `X24 == 0x100000200` | **plausible candidate — needs validation** | Still the copyright string VA (same as t8020 “lol” constant) |
| USB DMA dest `0x239100B14` | **Unknown — do not assume** | **No** `0x2391…` literal or `movk` imm16 `0x2391` found in this image |

### Shellcode offsets

| Expect | Confidence | Notes |
|--------|------------|-------|
| ROM helpers near USB serial builder | Medium | See ranked targets |
| `RETURN_TO_EL0` / tramp / memcpy VAs ≠ t8020 | **Confirmed different** | Same file offsets as t8020 symbols disassemble to unrelated insns |
| `JUMP_STATE` | **Confirmed** `0x19C014030` | Only SRAM symbol with direct materialization so far |

### Heap blocks / cleanup.S

| Expect | Confidence | Notes |
|--------|------------|-------|
| Blocks inside `0x19C028000` bank | **THEORY — unconfirmed** | Region exists; exact five pointers unknown |
| cleanup USB base `0x239100000` | **Unknown** | Not seen; find MMIO another way (ibis data xrefs / DWC2 driver) |

### usb_req_handler

| Expect | Confidence | Notes |
|--------|------------|-------|
| Serial/USB string assembly near `0x1000067bc` | **High (confirmed xrefs)** | `pacibsp` function; formats CPID line + `SRTG:[%s]` |
| `USB_DESC_MAKE_STR` / snprintf-like | **plausible candidates — needs validation** | `bl 0x1000115a8` (format), `bl 0x1000116c8` (append-like), from serial builder |
| `HANDLE_USB_REQ` exact VA | Unknown | Trace DFU control-request path from second DFU-string site `0x10000ad58` |
| Non-PAC handler blob like t8020 | **Likely wrong assumption** | PAC density argues otherwise |

---

## 3. Ranked first targets

Confirm these first — they unlock the most worksheet rows:

1. **`JUMP_STATE`** — already `0x19C014030` (**confirmed**); re-check in ibis, then mark worksheet row done.
2. **PAC policy for PC control** — decide if t8020 LR ROP is viable or if a PAC-aware path is required (**blocks entire ROP strategy**).
3. **`TRAMP_BASE` / `shc_base`** — validate `0x19C018000` beyond BSS-clear end (**plausible**).
4. **USB serial builder @ `0x1000067bc`** — name `USB_DESC_MAKE_STR` / demote / remote-boot callees; walk xrefs.
5. **Format/append helpers `0x1000115a8` / `0x1000116c8`** — confirm vs `snprintf` / `strlcat`; hunt `MEMCPY` from their callees.
6. **DFU / USB request path from `0x10000ad58`** — toward `HANDLE_USB_REQ`.
7. **USB controller MMIO base** — still missing; search DWC2 DOEPDMA usage without assuming `0x2391`.
8. **`NEW_SP` / `ov_start` inside `0x19C028000`** — only after heap/task stack map (may need runtime/DFU insight, not ROM alone).

---

## 4. Concrete next commands / tool steps

On the Mac (repo root, ROM in place):

```bash
ROM=research/usbliter8-t8027/artifacts/SecureROM_t8027_4172.bin
shasum -a 256 "$ROM"   # must match 223866855772be24ac57d4ac0033fd6f99012a2e94646b9e2094b3adee7a8baf
strings -a -t x "$ROM" | rg 'DFU Mode|CPID:%04X|iBoot-4172|idle task|SecureROM for t8027'
```

In **ibis + IDA/Binary Ninja** (base `0x100000000`):

1. Jump to `0x100001944` — confirm `JUMP_STATE` materialization (`0x19C014030`).
2. Jump to `0x100008180` — inspect region table; xrefs to `0x19C018000` / `0x19C028000`.
3. Jump to `0x1000067bc` — define function; map calls to `0x1000115a8` / `0x1000116c8`; rename only with evidence.
4. From `0x10000ad58`, navigate callers/callees for USB/DFU request handling; look for callback store to SRAM under `0x19C010000` (busy page in ADRP traffic).
5. Search program-wide for `pacibsp`/`retab` vs signed LR load patterns; explicitly **kill or keep** t8020-style ROP THEORY.
6. Search for DWC2 / `DOEPDMA`-style MMIO (do not seed `0x2391` as fact).
7. Optional: load t8020 `3865.0.0.4.7` side-by-side for *role* diff only — never copy VAs.

Kill criteria for a THEORY row: wrong insn at candidate, no xref, or PAC model contradiction.

---

## 5. Updated worksheet notes (`SYMBOL_WORKSHEET.md`)

Do **not** treat these as stub fills. Summary only:

| Area | Now | Still unknown |
|------|-----|----------------|
| `JUMP_STATE` | **Confirmed** `0x19C014030` | — |
| SRAM bank `0x19C0…` | **Confirmed** in use | Exact `ov_*` / heap block list |
| `TRAMP_BASE` / `shc_base` | **plausible** `0x19C018000` | Validate via tramp copy / PTE code |
| `NEW_SP` / ROP frame SRAM slots | **THEORY** in `0x19C028000` bank | Exact VAs |
| `X24` | **plausible** `0x100000200` | Confirm in real overwrite plan |
| All t8020 `0x10000…` ROM gadgets/funcs | **Confirmed not same VA** | Need fresh symbolization |
| `USB_DMA_DEST` / USB base | **No evidence for `0x2391`** | Find MMIO |
| Handler PAC | **Confirmed PAC-heavy ROM** | Handler strategy choice |
| `ov_size` / `shc_size` / `delay` | Unchanged family hypotheses | Hardware / layout proof |
| Heap `blocks.S` / cleanup USB literals | Unknown | Runtime / deeper RE |

Suggested worksheet discipline: when promoting a row, append evidence like `FIRST_RE_PASS §2 (adrp+add @0x100001944)` and keep label until validated in ibis.

---

## See also

- [PAC_AND_CONTROL_FLOW.md](PAC_AND_CONTROL_FLOW.md) — deepened PAC / hijack planning
- [SYMBOL_WORKSHEET.md](SYMBOL_WORKSHEET.md)
- [OFFSET_DERIVATION.md](OFFSET_DERIVATION.md)
- [SECUREROM_ACQUISITION.md](SECUREROM_ACQUISITION.md)
- [docs/research/usbliter8-t8027-bringup.md](../../docs/research/usbliter8-t8027-bringup.md)
