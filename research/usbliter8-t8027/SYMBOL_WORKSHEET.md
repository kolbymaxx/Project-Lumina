# t8027 SecureROM symbolization worksheet

**Date:** 2026-08-03  
**Phase:** after [SECUREROM_ACQUISITION.md](SECUREROM_ACQUISITION.md) + [OFFSET_DERIVATION.md](OFFSET_DERIVATION.md)  
**Teacher:** upstream `t8020` (shared `t8020_t8006_*` path)  
**Status:** worksheet only — **t8027 candidate column empty; stubs still TODO / `#error`; pwn not claimed**

Nothing here is wired into `boot/`. Do not paste guessed addresses into [`stubs/`](stubs/).

---

## Scope / non-claims / non-goals

### Non-claims

- No claim that usbliter8 pwns A12X / t8027.
- No claim that any t8027 candidate address is known yet.
- Structure similarity to t8020 ≠ same VAs.

### Non-goals

- Filling stub `#define`s with numbers in this PR
- Inventing SRAM / USB MMIO bases from the ROM file alone
- `boot/` / DarkSword / kexploit / bootstrap

### Goal

Make later stub fill **mechanical**: every symbol the stubs need appears here with a t8020 reference and an empty t8027 evidence slot.

---

## 1. ROM verification

Canonical local path (gitignored — do not commit):

`research/usbliter8-t8027/artifacts/SecureROM_t8027_4172.bin`

Source checked against public collection title: `SecureROM for t8027si, iBoot-4172.0.0.100.14` ([securerom.fun](https://securerom.fun/) APROM entry). Matches live DFU `SRTG:[iBoot-4172.0.0.100.14]`.

| Check | Result |
|-------|--------|
| Version string present | **Yes** — `strings` finds `iBoot-4172.0.0.100.14` |
| File size | **163840** bytes (`0x28000`) |
| SHA-256 | `223866855772be24ac57d4ac0033fd6f99012a2e94646b9e2094b3adee7a8baf` |
| `file(1)` | `data` (raw binary; expected) |

Re-verify on the Mac if the path differs (`~/Downloads/…`):

```bash
ROM=research/usbliter8-t8027/artifacts/SecureROM_t8027_4172.bin
# or: ROM=~/Downloads/<your-file>
strings -a "$ROM" | rg 'iBoot-4172\.0\.0\.100\.14'
wc -c < "$ROM"
shasum -a 256 "$ROM"
```

If SHA-256 differs from the table above, stop and reconcile which blob is under analysis before symbolizing.

---

## 2. Comparison baseline (t8020 teacher)

Paths relative to local `upstream/usbliter8/` clone (gitignored) and Lumina stubs.

### Config blob fields

From `exploit.c` → `t8020_config` / `struct t8020_t8006_config`; stub template `stubs/t8027_config.snippet.c`.

| Field | Role |
|-------|------|
| `cpid` | Switch key (`0x8020` teacher → `0x8027` identity already known) |
| `delay` | Pico timing (hardware retune; not from ROM) |
| `ov_start` | SRAM start of overwrite packing |
| `ov_size` | Overwrite transfer size |
| `shc_base` | Shellcode plant base (SRAM) |
| `shc_start` | Shellcode packing start |
| `shc_size` | Shellcode buffer size |
| `create_overwrite` / `create_shellcode` | Function pointers (code, not VAs) |

### ROP / overwrite frame

From `t8020_create_overwrite()` in `exploit.c` — each row is a write target and/or gadget.

| Role |
|------|
| new LR slot → load-X19 gadget |
| load X19: X19 value |
| load X19: next LR → load W8 |
| X19 store value (shellcode landing-related) |
| load W8: X19 = USB DMA dest |
| load W8: next LR → store W8 |
| store W8: next LR → load W0 |
| store W8: X20 = delay ptr − 8 |
| delay value (`TASK_SLEEP_US`) |
| load W0: next LR → BLR X19 |
| load W0: X19 = `task_sleep` |
| BLR X19: next LR → EL1 escalate |
| X22 / X23 / X24 |
| descriptor restore (`SETMANY` dest + blob) |

### Shellcode offsets

From `t8020_t8006_shellcode/targets/t8020/offsets.h` ↔ stub `stubs/.../t8027/offsets.h`.

ROM-class: `MEMCPY`, `STRLCAT`, `CALCULATE_HEAP_BLOCK_SUM`, `ROM_TRAMP`, `ROM_TRAMP_LEN`, `USB_DESC_MAKE_STR`, `RETURN_TO_EL0_ADDR`  
SRAM/USB-class: `NEW_SP`, `TRAMP_BASE`, `BOOT_TRAMP_PTEP`, `BOOT_TRAMP_PTE`, `DMA_BUF_LO`, `USB_DMA_DEST`, `JUMP_STATE`, heap repair symbols, `USB_SN_STR`, `USB_DEV_DESC_SN_IDX`, `USB_REQ_HANDLER_CB_ADDR`

### Heap blocks

From `targets/t8020/blocks.S` — five `.8byte` heap nodes (stub `blocks.S` empty).

### cleanup.S literals

From `targets/t8020/cleanup.S` — stub is TODO-only. Teacher literals: stack canary ptr, task-tramp LR, USB-related stack slot, USB base (`x20`), related SRAM (`x21`), small immediates (`w24`–`w26`/`w28`).

### usb_req_handler offsets

From `usb_req_handler/targets/t8020/offsets.h` ↔ stub handler `offsets.h`.

ROM-class: `HANDLE_USB_REQ`, `PLATFORM_DEMOTE`, `PLATFORM_SET_REMOTE_BOOT`, `JUMP_AWAY`  
SRAM-class: `MAIN_TASK_STACK_LR`

---

## 3. Symbolization strategy

### Approach

1. Load the verified **4172** image with a SecureROM-aware loader ([ibis](https://github.com/jonpalmisc/ibis) for IDA/Binary Ninja, or Ghidra with correct base — typically `0x100000000` family; let the tool define mapping).
2. Keep t8020 `offsets.h` + `t8020_create_overwrite` open as a **role list**, not as copy-paste VAs.
3. Find the same *roles* in 4172 by string → xref → function; record evidence in the tables below.
4. Mark each hit ROM vs SRAM. **This ROM file alone cannot fill SRAM/USB MMIO rows** — leave those TODO until a DFU SRAM/USB map exists ([OFFSET_DERIVATION.md](OFFSET_DERIVATION.md)).

### Search first (high signal)

| Anchor | Why |
|--------|-----|
| `iBoot-4172.0.0.100.14` | Confirms image; nearby version / identity code |
| USB serial field fragments (`CPID:`, `SRTG:`, `PWND:`) | Leads toward USB string / descriptor helpers |
| Demote / remote-boot related strings (as present) | `PLATFORM_DEMOTE`, `PLATFORM_SET_REMOTE_BOOT` |
| USB request / DFU handling xrefs | `HANDLE_USB_REQ`, `USB_DESC_MAKE_STR` |
| `memcpy` / `strlcat`-like leaf funcs | Shellcode helpers |
| Boot trampoline / exception return patterns | `ROM_TRAMP`, `RETURN_TO_EL0_ADDR`, EL1 escalate gadget |
| Small ROP gadgets: load X19 from stack, load W8, store W8 to `[X19]`, load W0, `BLR X19` | Overwrite chain LRs |

### Tools

| Tool | Use |
|------|-----|
| `strings` / `rg` | Version + USB string anchors |
| [ibis](https://github.com/jonpalmisc/ibis) | Segment-accurate SecureROM load in IDA / Binary Ninja |
| IDA / Ghidra / Binary Ninja | Xrefs, function boundaries, gadget search |
| `binwalk` | Optional entropy/carve sanity — not a substitute for version match |
| Side-by-side t8020 ROM (optional teacher image `3865…`) | Pattern recognition only |

### Explicit warning

**Structure similarity ≠ same addresses.** t8020↔t8006 already shows ROM gadgets and many BSS symbols moving independently even when ROP *shape* matches. Never slide `0x19C0…` or copy `0x10000…` from t8020 into t8027 stubs.

---

## 4. Worksheet tables

Fill **t8027 candidate** only with evidence-backed VAs. Until then: `TODO — derive`.

### 4.1 Config blob

| Symbol / Field | t8020 value (reference) | t8027 candidate | Notes / evidence |
|----------------|-------------------------|-----------------|------------------|
| `cpid` | `0x8020` | `0x8027` (identity only) | Live DFU; not a ROM derive |
| `delay` (RP2350 / RP2040) | `10` / `5` | TODO — derive | Hardware retune last |
| `ov_start` | `0x19C02960C` | TODO — derive | SRAM — needs DFU map |
| `ov_size` | `0xB04` | TODO — derive | Family hypothesis only |
| `shc_base` | `0x19C018000` | TODO — derive | SRAM |
| `shc_start` | `0x19C0183EC` | TODO — derive | SRAM |
| `shc_size` | `0x400` | TODO — derive | Family hypothesis only |

### 4.2 ROP / overwrite frame

| Symbol / Field | t8020 value (reference) | t8027 candidate | Notes / evidence |
|----------------|-------------------------|-----------------|------------------|
| new LR slot VA | `@0x19c028b18` | TODO — derive | SRAM frame |
| load X19 gadget | `0x10000FC30` | TODO — derive | ROM |
| load X19: X19 | `@0x19c028b58` ← `0x19C028D00` | TODO — derive | SRAM |
| load X19: next LR (load W8) | `0x100007510` | TODO — derive | ROM |
| X19 store value | `@0x19c028d00` ← `0x19C018400` | TODO — derive | SRAM |
| load W8: USB DMA dest | `@0x19c028b78` ← `0x239100b14` | TODO — derive | USB MMIO |
| load W8: next LR (store W8) | `0x100007358` | TODO — derive | ROM |
| store W8: next LR (load W0) | `0x10000e2bc` | TODO — derive | ROM |
| store W8: X20 delay ptr−8 | `@0x19c028b90` ← `0x19c028d00` | TODO — derive | SRAM |
| delay value slot | `@0x19c028d08` ← `TASK_SLEEP_US` | TODO — derive | SRAM + constant |
| load W0: next LR (BLR X19) | `0x100003948` | TODO — derive | ROM |
| `task_sleep` | `0x100009880` | TODO — derive | ROM |
| EL1 escalate (next LR) | `0x1000088B0` | TODO — derive | ROM |
| X22 | `@0x19c028c00` ← `0x19C034000` | TODO — derive | SRAM |
| X23 | `@0x19c028bf8` ← `0x19C034000` | TODO — derive | SRAM |
| X24 | `@0x19c028bf0` ← `0x100000200` | TODO — derive | often fixed stub VA — still verify |
| descriptor restore dest | `@0x19c029400` | TODO — derive | SRAM |

### 4.3 Shellcode offsets (`offsets.h`)

| Symbol / Field | t8020 value (reference) | t8027 candidate | Notes / evidence |
|----------------|-------------------------|-----------------|------------------|
| `NEW_SP` | `0x19C028BC0` | TODO — derive | SRAM |
| `MEMCPY` | `0x100010BD0` | TODO — derive | ROM — early target |
| `STRLCAT` | `0x100010B60` | TODO — derive | ROM — early target |
| `CALCULATE_HEAP_BLOCK_SUM` | `0x10000F664` | TODO — derive | ROM |
| `TRAMP_BASE` | `0x19C018000` | TODO — derive | SRAM |
| `ROM_TRAMP` | `0x100007640` | TODO — derive | ROM |
| `ROM_TRAMP_LEN` | `0x480` | TODO — derive | length; verify |
| `BOOT_TRAMP_PTEP` | `0x19C004030` | TODO — derive | SRAM / PT |
| `BOOT_TRAMP_PTE` | `0x19C0186E3` | TODO — derive | SRAM |
| `DMA_BUF_LO` | `0x9C029600` | TODO — derive | DMA (truncated form on t8020) |
| `USB_DMA_DEST` | `0x239100B14` | TODO — derive | USB MMIO |
| `JUMP_STATE` | `0x19C014030` | TODO — derive | SRAM |
| `HEAP_BLOCK_TO_REPAIR_DMA` | `0x19C0295C0` | TODO — derive | SRAM |
| `HEAP_BLOCK_TO_REPAIR_IO_BUF` | `0x19C028BC0` | TODO — derive | SRAM |
| `HEAP_WHATEVER_THAT_IS` | `0x19C011468` | TODO — derive | SRAM |
| `USB_SN_STR` | `0x19C00BC58` | TODO — derive | SRAM |
| `USB_DEV_DESC_SN_IDX` | `0x19C00890A` | TODO — derive | SRAM |
| `USB_DESC_MAKE_STR` | `0x10000D584` | TODO — derive | ROM — early target |
| `USB_REQ_HANDLER_CB_ADDR` | `0x19C010C68` | TODO — derive | SRAM |
| `RETURN_TO_EL0_ADDR` | `0x10000C408` | TODO — derive | ROM |

### 4.4 Heap blocks (`blocks.S`)

| Symbol / Field | t8020 value (reference) | t8027 candidate | Notes / evidence |
|----------------|-------------------------|-----------------|------------------|
| block[0] | `0x19C028BC0` | TODO — derive | SRAM |
| block[1] | `0x19C029400` | TODO — derive | SRAM |
| block[2] | `0x19C029480` | TODO — derive | SRAM |
| block[3] | `0x19C029500` | TODO — derive | SRAM |
| block[4] | `0x19C0295C0` | TODO — derive | SRAM |

### 4.5 cleanup.S literals

| Symbol / Field | t8020 value (reference) | t8027 candidate | Notes / evidence |
|----------------|-------------------------|-----------------|------------------|
| stack canary ptr | `0x19C008448` | TODO — derive | SRAM |
| task-tramp LR | `0x10000ACEC` | TODO — derive | ROM |
| stack slot `@sp+8` | `0x239100BA8` | TODO — derive | USB MMIO-related |
| `x20` USB base | `0x239100000` | TODO — derive | USB MMIO |
| `x21` | `0x19C010670` | TODO — derive | SRAM |
| `w24` / `w25` / `w28` / `w26` | `1` / `0x40` / `0x1F` / `0xF` | TODO — derive | immediates — verify if still required |
| frame clear size | `0xA0` | TODO — derive | structural hypothesis |

### 4.6 usb_req_handler offsets

| Symbol / Field | t8020 value (reference) | t8027 candidate | Notes / evidence |
|----------------|-------------------------|-----------------|------------------|
| `HANDLE_USB_REQ` | `0x10000E3EC` | TODO — derive | ROM — early target |
| `PLATFORM_DEMOTE` | `0x100007CF8` | TODO — derive | ROM — early target |
| `PLATFORM_SET_REMOTE_BOOT` | `0x100006850` | TODO — derive | ROM — early target |
| `MAIN_TASK_STACK_LR` | `0x19C01DF08` | TODO — derive | SRAM |
| `JUMP_AWAY` | `0x100001C8C` | TODO — derive | ROM |
| PAC / `WITH_PAC` | none on t8020 | TODO — confirm | Expect non-PAC like t8020; confirm on 4172 |

---

## 5. First concrete RE steps (next)

Ordered. Starts from verified ROM; ends at first high-confidence **ROM** symbols. Still no stub edits.

1. Confirm SHA-256 matches §1 on the Mac path you will analyze.
2. Load `SecureROM_t8027_4172.bin` with **ibis** (or equivalent) at the tool’s SecureROM base.
3. Locate string `iBoot-4172.0.0.100.14` and map nearby identity / USB serial construction.
4. From USB/DFU xrefs, identify candidates for `HANDLE_USB_REQ` and `USB_DESC_MAKE_STR`; record VA + xref evidence in §4.6 / §4.3.
5. Resolve `PLATFORM_DEMOTE` and `PLATFORM_SET_REMOTE_BOOT` (string or call-graph from USB/platform init); fill §4.6.
6. Identify `MEMCPY` / `STRLCAT` leaf helpers used by string/USB code; fill §4.3 ROM rows.
7. Search for ROP gadget shapes used in t8020 overwrite (load X19 / load W8 / store W8 / load W0 / `BLR X19` / EL1 escalate); fill **ROM** rows in §4.2 only.
8. Stop before inventing SRAM/USB MMIO. Open a separate note when a DFU heap/stack/USB map exists; leave those candidates `TODO — derive`.

Exit for this worksheet phase: several §4.3 / §4.6 ROM rows filled with evidence — **not** PWND, **not** stub `#define`s committed.

---

## See also

- [SECUREROM_ACQUISITION.md](SECUREROM_ACQUISITION.md)
- [OFFSET_DERIVATION.md](OFFSET_DERIVATION.md)
- [docs/research/usbliter8-t8027-bringup.md](../../docs/research/usbliter8-t8027-bringup.md)
- Empty stubs: [stubs/](stubs/)
