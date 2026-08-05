# JB Framework — Module 1: Porting usbliter8 to T8027 (A12X)

**Role:** sequential module 1 of 4 (BootROM port → patch-diff → K/W → pipeline).  
**Audience:** engineering co-pilot / later agents.  
**Status:** research + automation blueprints — **SecureROM pwn on A12X not claimed**.  
**Do not** wire into `boot/`, `fix_exec`, or XR live paths.

| Field | Lab-locked value |
|-------|------------------|
| Device | iPad Pro 12.9" 3rd gen (USB-C) |
| SoC / CPID | A12X / `0x8027` (`t8027`) |
| Live DFU SRTG | `iBoot-4172.0.0.100.14` |
| BDID (this unit) | `0A` |
| ECID | `0019052A1413002E` |
| Closest *race* teacher | `t8020_t8006_*` (DWC2 underflow shape) |
| Closest *PAC* teacher | `t8030` handler/`WITH_PAC` (control-flow only) |

**Prerequisite reading (do not duplicate blindly):**

- Identity + t8020 inventory: [`usbliter8-t8027-bringup.md`](usbliter8-t8027-bringup.md)
- Derivation order: [`../../research/usbliter8-t8027/OFFSET_DERIVATION.md`](../../research/usbliter8-t8027/OFFSET_DERIVATION.md)
- ROM acquisition: [`../../research/usbliter8-t8027/SECUREROM_ACQUISITION.md`](../../research/usbliter8-t8027/SECUREROM_ACQUISITION.md)
- First RE pass (PAC density, SRAM ADRPs): [`../../research/usbliter8-t8027/FIRST_RE_PASS.md`](../../research/usbliter8-t8027/FIRST_RE_PASS.md)
- PAC control-flow problem: [`../../research/usbliter8-t8027/PAC_AND_CONTROL_FLOW.md`](../../research/usbliter8-t8027/PAC_AND_CONTROL_FLOW.md)
- Empty stubs: [`../../research/usbliter8-t8027/stubs/`](../../research/usbliter8-t8027/stubs/)

---

## 0. Architectural constraints (read before coding)

### 0.1 Same USB bug class ≠ same exploit path

| Layer | T8020 (XR A12) | T8027 (A12X, this lab) |
|-------|----------------|-------------------------|
| DWC2 Setup-ring underflow | Yes | Same *hardware class* (authors: A12X/Z theoretically supportable) |
| USB DART bypass in SecureROM | Yes (A12/A13 write-up) | Assumed same class; **verify** once SRAM/USB map known |
| SecureROM build | `3865.0.0.4.7` | **`4172.0.0.100.14`** (confirmed live + in dump) |
| PAC in SecureROM | **None** (`pacibsp`/`retab` = 0) | **Heavy** (`pacibsp`×462, `retab`×364) — **confirmed** |
| Upstream PoC | Implemented | **Not implemented** |

**Implication:** Module 1 is *not* “rename t8020 → t8027 and retune delays.” Memory geometry may partially rhyme with `0x19C0…` (ADRP evidence), but **first PC hijack must be PAC-aware**. Blind LR smash with raw gadget VAs is a **disproven planning assumption** until a specific victim frame is shown to use plain `ret`.

### 0.2 Chicken-and-egg (honest)

You cannot dump SecureROM *via* usbliter8 on a chip that has no port yet. Acquisition is offline (securerom.fun / lab corpus) → static RE → then Pico port. See acquisition doc. Do not invent dump recipes that claim live unsigned DFU readback without a working handler.

### 0.3 Success criterion for Module 1

Device re-enumerates DFU with serial containing `PWND:[usbliter8]` and `CPID:8027`.  
**Not** Module 1: iBSS/ramdisk, iPadOS 26.5 PE, K/W, bootstrap.

---

## 1. Locate and map target offsets

### 1.1 Theory — what you must name

Treat every usbliter8 constant as a **role**, not a number. Roles cluster into four maps:

```text
┌─────────────────────────────────────────────────────────────┐
│ ROM @ 0x100000000                                           │
│  gadgets (load X19, store W8, task_sleep, EL1 escalate)     │
│  funcs (memcpy, strlcat, heap checksum, usb_desc_make_str)│
│  HANDLE_USB_REQ / PLATFORM_DEMOTE / SET_REMOTE_BOOT         │
│  ROM_TRAMP / JUMP_AWAY / RETURN_TO_EL0                      │
├─────────────────────────────────────────────────────────────┤
│ SRAM @ ~0x19C0_xxxx (T8027 ADRP-confirmed bank)             │
│  USB task stack / io frame (ROP victim)                     │
│  DMA buf / heap cursor / heap blocks to repair              │
│  tramp page (shellcode plant) / JUMP_STATE / PTEP           │
│  USB_SN_STR / DEV_DESC_SN_IDX / REQ_HANDLER_CB              │
│  MAIN_TASK_STACK_LR (CUSTOM_BOOT return slot)               │
├─────────────────────────────────────────────────────────────┤
│ USB MMIO (DWC2)                                             │
│  controller base + DOEPDMA dest used in ROP store step      │
├─────────────────────────────────────────────────────────────┤
│ Config timing                                               │
│  crazy_delay, TASK_SLEEP_US, post-plant sleeps              │
└─────────────────────────────────────────────────────────────┘
```

T8020 baseline inventory (teacher numbers only): bring-up memo §“t8020 → t8027 constant inventory”.

### 1.2 Tool workflow — SecureROM → worksheet

1. **Identity gate (live Mac)** — confirm still unpwned 4172:

   ```bash
   python3 ./usbliter8ctl info
   # expect: CPID:8027 … SRTG:[iBoot-4172.0.0.100.14]  (no PWND)
   ```

2. **Obtain matching AP SecureROM** (not SEPROM/iBSS). Verify version string + SHA-256 privately. Lab note already references dump SHA-256 `22386685…7a8baf` for `4172`.

3. **Load with segment-accurate loader** ([ibis](https://github.com/jonpalmisc/ibis) / IDA / Binary Ninja) at base `0x100000000`.

4. **String → function index** (stable anchors shared across generations):

   | String / role | Use |
   |---------------|-----|
   | `iBoot-4172.0.0.100.14` | Confirm image |
   | `CPID:%04X CPRV:…` | USB serial builder → DFU USB path |
   | `Apple Mobile Device (DFU Mode)` | Descriptor path |
   | `panic:` / `double panic` | Error paths near USB/heap |
   | `IMG4` / demote-related strings | `PLATFORM_DEMOTE` neighbourhood |

5. **SRAM map via ADRP/ADD literals** — FIRST_RE_PASS already confirmed traffic to `0x19C00C000`…`0x19C014000` and `JUMP_STATE == 0x19C014030`. Continue: build a table of every `0x19C0…` materialization; label by xrefs (USB, heap, tramp).

6. **USB MMIO** — find stores to physical MMIO near DWC2 (T8020 teacher used `0x239100B14` as DMA dest). On T8027, re-find base; do not assume `0x2391…`.

7. **PAC policy pass** — for each candidate saved-LR / callback:

   - Does the consumer use `retab` / `autib*`?
   - Key A vs B? Modifier = SP?
   - Or is the slot a raw `blr` target (callback smash)?

8. **Fill worksheet only with evidence** — [`SYMBOL_WORKSHEET.md`](../../research/usbliter8-t8027/SYMBOL_WORKSHEET.md). Never paste guesses into git stubs.

### 1.3 Automation blueprint — identity + role checklist

Modular helper (lab-local; no device write):  
[`../../research/usbliter8-t8027/tools/module1_offset_audit.py`](../../research/usbliter8-t8027/tools/module1_offset_audit.py)

- Parse DFU serial fields (`CPID`, `SRTG`, `PWND`).
- Emit the **role checklist** CSV (ROM / SRAM / MMIO / timing) with empty `t8027_va` columns.
- Diff two worksheets (before/after RE sessions).
- Refuse to “approve” a stub fill if any `#error` / zero address remains.

### 1.4 Exact derivation order (dependency)

```text
1. Verified 4172 SecureROM image
2. ROM gadgets + funcs (all 0x10000…)     ← highest churn vs 3865
3. JUMP_STATE / tramp / heap banks (SRAM)
4. USB-task stack frame = DMA victim object
5. PAC policy on that victim’s return / callback
6. USB MMIO DMA dest used by ROP/data write
7. Handler symbols (HANDLE_USB_REQ, DEMOTE, STACK_LR, JUMP_AWAY)
8. Descriptor restore blob (only after knowing destroyed region)
9. Build shellcode+handler via make.sh (no hand-faked .h blobs)
10. Retune Pico timing last
```

---

## 2. Adapt heap grooming / race payloads

### 2.1 Theory — what “grooming” means in usbliter8

On the published A12 path, “grooming” is not a classic userspace heap spray. It is:

1. **Malformed short USB packets** (PIO bitbang) that underflow DOEPDMA in 12-byte steps.
2. An **overwrite buffer** (`ov_size` ≈ `0xB04` on t8020) laid out with `SET32`/`SET64` packing that matches the DMA write order.
3. A **ROP / control-transfer frame** planted into the USB-task stack/io region.
4. A second transfer that **plants shellcode** onto the tramp page (`shc_base` / `shc_start`).
5. A **sleep window** (`TASK_SLEEP_US`, `crazy_delay`) so DMA lands before the next SecureROM step.
6. **Heap-block repair** in shellcode (`blocks.S` + checksum) so DFU continues instead of panicking.

T8006 vs T8020 teaches: **absolute bases slide**; **relative packing and step order** often stay in-family. T8027 may keep `0x19C0` banks (evidence) while every ROM gadget and the **hijack method** change.

### 2.2 What must change for the ‘X’ variant

| Knob | Why it moves on T8027 | How to adapt |
|------|------------------------|--------------|
| Absolute SRAM slots | Different SecureROM / BSS layout | Re-derive from ADRP + heap map; keep `SET*` packing helper |
| `ov_start` / `ov_size` | DMA cursor vs destroyed region | Size = span of corrupted objects; start = first corrupted word the packing scheme expects |
| ROP contents | **PAC** — raw LR overwrite likely dies on `retab` | Prefer PAC-signed LR (t8030 teacher), callback smash, or proven non-PAC island — see PAC doc |
| Shellcode plant VA | Tramp / PTE may rhyme with `0x19C018000` | Validate candidate; regenerate blob |
| Heap repair list | Block headers move | Rebuild `blocks.S` from live heap after first reliable write primitive *or* from static heap metadata |
| `crazy_delay` / sleeps | RP2350 QSPI cache + USB-C harness timing | Sweep experimentally **after** addresses are real; log attempt/ACK/timeout |
| Descriptor restore | Destroyed USB descriptors differ | Capture virgin descriptor SRAM from static init or first-stage dump |

### 2.3 PAC-aware control-flow (Module 1 critical path)

**Do not** ship a t8020-shaped `t8027_create_overwrite` that only swaps numbers.

Planning frame (THEORY until victim frame ID):

1. Keep DWC2 race + SRAM geometry as the *memory* story.
2. Identify the **exact** corrupted object (saved LR vs function pointer).
3. If LR + `retab`: install **signed** continuation (learn key/modifier; teacher = t8030 `WITH_PAC` handler).
4. If callback/`blr` without auth: raw code pointer may suffice — still verify.
5. After shellcode runs, plant handler with T8027-correct `HANDLE_USB_REQ` and PAC policy for `CUSTOM_BOOT`’s `MAIN_TASK_STACK_LR` write.

### 2.4 Experiment harness (already in-tree)

Use [`research/usbliter8-t8027/experiments/`](../../research/usbliter8-t8027/experiments/) for candidate logs. Rules:

- One hypothesis per candidate file.
- No Pico race claiming PWND without filled stubs.
- Record cable (USB-C data vs race harness), UF2 build id, delay settings, serial before/after.

### 2.5 Automation blueprint — timing sweep *scaffold*

[`module1_timing_sweep.py`](../../research/usbliter8-t8027/tools/module1_timing_sweep.py) — **scaffold only**:

- Reads a YAML of delay candidates.
- Invokes *your* local picotool/UF2 flash + `usbliter8ctl info` poll.
- Classifies outcomes: `unsupported` / `no_device` / `still_unpwned` / `pwnd` / `error`.
- Never embeds packet payloads; assumes firmware already built with real offsets.

Gate: refuse to run if `offsets.h` still contains `#error` or zeroed config fields.

---

## 3. Extend the codebase (clean T8027 profile)

### 3.1 Design rules

1. **Flag-gated** until offsets evidence-backed: e.g. `-DUSBLITER8_TARGET_T8027=1` **and** a compile-time `#error` if required macros unset.
2. Reuse `struct t8020_t8006_config` *shape* only if the race runner stays shared; PAC hijack may justify a parallel `t8027_exploit_run` later.
3. Do **not** commit nested `upstream/usbliter8/`. Edit a local clone; keep templates under `research/usbliter8-t8027/stubs/`.
4. Host `./usbliter8ctl` needs **no** CPID table for post-PWND; optional identity assert is fine.

### 3.2 File blueprint (local upstream clone)

```text
upstream/usbliter8/   (gitignored local)
├── exploit.c
│     case 0x8027 → t8027 runner/config   # behind flag; after fills
├── t8020_t8006_shellcode/targets/t8027/
│     offsets.h  blocks.S  cleanup.S
├── usb_req_handler/targets/t8027/
│     offsets.h   # consider WITH_PAC if handler needs signed JUMP_AWAY
├── resources/
│     shellcode_t8027.h  handler_t8027.h  descriptors_t8027.h
└── (boards/*.cmake unchanged — Pico MCU only)
```

In-repo templates: [`stubs/`](../../research/usbliter8-t8027/stubs/) (`t8027_config.snippet.c`, `exploit_cpid_switch.snippet.c`, empty `offsets.h` with `#error`).

### 3.3 Registration sketch (illustrative — not enabled)

```c
/* research template — enable only when USBLITER8_TARGET_T8027 && offsets filled */

#if defined(USBLITER8_TARGET_T8027)
#include "resources/shellcode_t8027.h"
#include "resources/handler_t8027.h"
#include "resources/descriptors_t8027.h"

/* t8027_config + create_* from stubs/t8027_config.snippet.c */
#endif

/* exploit_run switch */
switch (cpid) {
case 0x8020:
case 0x8006:
    func = t8020_t8006_exploit_run;
    break;
case 0x8030:
    func = t8030_exploit_run;
    break;
#if defined(USBLITER8_TARGET_T8027)
case 0x8027:
    /* Prefer dedicated runner if PAC path diverges from t8020_t8006_exploit_run */
    func = t8027_exploit_run;
    break;
#endif
default:
    INFO("T%04X is not supported (yet?)", cpid);
    goto fail;
}
```

### 3.4 Build / regenerate

```bash
# after offsets.h is real — in local upstream clone
TARGET=t8027 ./t8020_t8006_shellcode/make.sh
TARGET=t8027 ./usb_req_handler/make.sh
# cmake Pico UF2 with -DUSBLITER8_TARGET_T8027=1
```

Hand-author `descriptors_t8027.h` only after the overwrite’s destroyed region is known. Do not invent blob bytes in git.

### 3.5 Host-side optional assert

```python
# conceptual — keep out of XR boot wrappers
serial = ...  # from usbliter8ctl info
assert "CPID:8027" in serial
assert "PWND:[usbliter8]" in serial  # Module 1 exit
assert "4172.0.0.100.14" in serial or True  # SRTG sanity
```

### 3.6 Automation blueprint — stub sync checker

[`module1_stub_sync.py`](../../research/usbliter8-t8027/tools/module1_stub_sync.py):

- Lists required stub files vs upstream clone paths.
- Fails CI-style if someone removes `#error` without a worksheet citation file.
- Prints copy commands into the local upstream tree.

---

## 4. Module 1 execution checklist (operator)

| Step | Action | Exit |
|------|--------|------|
| A | `usbliter8ctl info` → CPID 8027, SRTG 4172, no PWND | Identity OK |
| B | Verified SecureROM 4172 on disk (gitignored) | Artifact OK |
| C | Worksheet: ROM symbols filled with citations | ROM map OK |
| D | Worksheet: victim object + PAC policy | Hijack plan OK |
| E | SRAM/MMIO/config fields filled; stubs compile without `#error` | Port buildable |
| F | Local UF2 + race harness; serial gains `PWND:[usbliter8]` | **Module 1 done** |
| — | iBSS / ramdisk / 26.5 PE | **Modules 2–4** |

---

## 5. Handoff to Module 2

Module 1 yields **BootROM code execution + CUSTOM_BOOT/demote** on A12X only.  
Module 2 (iOS 26.5↔26.6 kernel patch-diff for K/W candidates) is independent on the **XR A12** track where userspace already runs, and only becomes relevant on A12X *after* a bootable research environment exists.

Do not block XR kernel RE on finishing T8027 PWND.

---

## Non-goals / non-claims

- No claim of working A12X usbliter8 today.
- No invented stub addresses in this module doc.
- No `boot/` merge, no XR UDID reuse, no “jailbreak” claim.
- No weaponized USB packet schedules in-repo — methodology and scaffolding only.
