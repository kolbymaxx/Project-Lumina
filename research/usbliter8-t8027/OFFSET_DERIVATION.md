# t8027 offset derivation plan (research only)

**Date:** 2026-08-03  
**Phase:** after DFU identity baseline ([docs/research/usbliter8-t8027-bringup.md](../../docs/research/usbliter8-t8027-bringup.md))  
**Device:** iPad Pro 12.9" 3rd gen (A12X / T8027), live DFU  
**SRTG (locked):** `iBoot-4172.0.0.100.14`  
**Status:** analysis + checklist only — **SecureROM pwn not implemented; no offsets invented**

Nothing here is wired into `boot/`. Empty stubs remain TODO / `#error` until addresses are derived from real artifacts.

---

## Scope / non-claims / non-goals

### Non-claims

- No claim that usbliter8 pwns A12X / t8027.
- No claim that t8020 `0x19C0…` SRAM or `0x2391…` USB bases apply to t8027.
- No claim that “theoretical support” equals a finished port.
- Public wiki/paper language that lists usbliter8 under T8027 vulnerabilities is **not** evidence of a public A12X PoC — upstream still says A12X/Z is unimplemented.

### Non-goals (this phase)

- Filling stub `#define`s with guessed numbers
- Wiring `case 0x8027` into a buildable firmware claim
- `boot/` / UDID / ramdisk / DeviceTree
- DarkSword / XR `kexploit` port, bootstrap, Sileo/dpkg
- Claiming iPadOS 26.5 PE from SecureROM work (PE/KRW hunt is a **separate** tree:
  [`../ipados26.5/`](../ipados26.5/) — does not block on these offsets)

### Goal

A concrete order of reverse-engineering work to turn [`stubs/`](stubs/) into **evidence-backed** offsets, plus a Mac-side checklist for gathering the missing artifacts.

---

## What is known different: t8020 vs t8027

### Locked from this lab (identity)

| | XR / t8020 (lab) | A12X / t8027 (this iPad) |
|--|------------------|---------------------------|
| CPID | `8020` | `8027` |
| CPRV | `11` (XR sample) | `01` |
| BDID | `0E` (XR sample) | `0A` |
| SRTG | `iBoot-3865.0.0.4.7` | `iBoot-4172.0.0.100.14` |
| PWND | yes (XR path) | **no** |

Different SecureROM build string ⇒ **ROM function/gadget VAs cannot be copied** from t8020.

### From public sources (no offsets)

| Source | What it establishes |
|--------|---------------------|
| [The Apple Wiki — T8027](https://theapplewiki.com/wiki/T8027) | T8027 = A12X/A12Z; Bootrom version **4172.0.0.100.14** (matches our SRTG) |
| Upstream usbliter8 README / Paradigm Shift write-up | A12, S4/S5, A13 implemented; **A12X/Z theoretically possible, not implemented** |
| Same write-up | Bug class = DWC2 Setup DMA underflow + SecureROM USB DART bypass on A12/A13-class; A12 path is non-PAC ROP (vs A13 `WITH_PAC`) |
| Upstream multi-target tree | Closest code path = shared `t8020_t8006_*` family (A12 + S4/S5), not t8030 |

### From in-tree t8020 vs t8006 comparison (structure lesson only)

Comparing published `targets/t8020` vs `targets/t8006` in a local `upstream/usbliter8/` clone teaches **which address classes move together** — it does **not** give t8027 numbers.

| Class | Family behavior | Implication for t8027 |
|-------|-----------------|------------------------|
| SRAM tramp / heap / ROP frame / `ov_start` | Rigid relative geometry; absolute base slides between chips | Reuse **shape**; derive absolute base — do not assume `0x19C0…` |
| USB MMIO | Base slides; register offsets like `+0xB14` matched t8020↔t8006 | Confirm base + whether register offsets still hold |
| ROM gadgets (`0x10000…`) | Nearly all differ independently between chips | **Must** re-symbolize against **4172** |
| BSS / SN string / handler CB / canary / `MAIN_TASK_STACK_LR` / `BOOT_TRAMP_PTEP` | Already diverge within the family | High chance of differing on t8027 even if SRAM base looked “close” |
| `ov_size` / `shc_size` / ROP step order / non-PAC handler shape | Shared in `t8020_t8006_exploit_run` | Structural hypothesis only — verify, don’t invent |

---

## Constant groups — likelihood to differ

Ordered for planning fill of stubs (see inventory in the bring-up memo).

| Priority | Group | Stub / upstream path | Likelihood | Why |
|----------|-------|----------------------|------------|-----|
| 1 | **ROM gadgets + ROM funcs** | shellcode + handler `offsets.h`; ROP LRs in `exploit.c` overwrite | **Highest** | SRTG 4172 ≠ 3865 |
| 2 | **USB handler SRAM** (`MAIN_TASK_STACK_LR`, CB) | `usb_req_handler/targets/t8027/offsets.h` | **High** | Diverges t8020↔t8006 |
| 3 | **Shellcode SRAM extras** (SN, PTEP, heap “whatever”, canary, cleanup `x21`) | shellcode `offsets.h`, `cleanup.S` | **High** | Same |
| 4 | **USB MMIO base** (`USB_DMA_DEST`, cleanup USB) | shellcode `offsets.h`, `cleanup.S`, ROP frame | **Medium–high** | Chip-specific bases in family |
| 5 | **Config / ROP SRAM cluster** (`ov_start`, `shc_*`, frame slots, `blocks.S`) | `t8027_config`, `blocks.S`, overwrite | **Medium** | Relative layout may match family; absolute base unknown |
| 6 | **Descriptor restore blob** | `resources/descriptors_t8027.h` (not stubbed yet) | **High content / late** | Depends on knowing what overwrite destroys |
| 7 | **Timing `delay`** | `t8027_config` | **Retune last** | Hardware-only; already differs t8020 vs t8006 |

**Structural (assume shape, not values):** ROP comment sequence in `t8020_create_overwrite`, shared shellcode/`handler.c` non-PAC path, `ov_size`/`shc_size` as working hypotheses until layout proof says otherwise.

---

## Recommended reverse / derive order

Do not skip ahead to planting binaries. Dependency order:

```text
1. Obtain SecureROM image matching SRTG 4172.0.0.100.14
2. Symbolize ROM set (gadgets + funcs) → fill ROM half of offsets.h + handler ROM symbols
3. Map DFU SRAM: DMA buf, USB task stack/io frame, tramp page
4. Derive ov_start / ROP slots / NEW_SP / TRAMP_BASE / shc_* / blocks.S
5. Locate USB controller MMIO base; verify DMA dest register offset
6. Resolve remaining BSS/SN/CB/PTE/canary/MAIN_TASK_STACK_LR
7. Author descriptors restore only after knowing destroyed region
8. Build shellcode+handler via TARGET=t8027 make.sh (no hand-faked blobs)
9. Wire local exploit.c case 0x8027 + t8027_config from snippets — still research/local
10. Retune delay on Pico harness last
```

Exit for this research phase is **not** PWND. Exit is: documented artifact inventory + filled TODO list with citations to where each address was found. PWND remains a later lab milestone.

---

## Artifacts still needed

| Artifact | Purpose | In Lumina repo today? |
|----------|---------|------------------------|
| SecureROM dump / image for **4172.0.0.100.14** | All `0x10000…` symbols | **No** — not vendored; no dump recipe in-tree |
| Symbol map / IDA/Ghidra DB against that image | Gadgets + `HANDLE_USB_REQ` / demote / tramp / memcpy / … | **No** |
| DFU-time SRAM / heap / USB-task stack map | `ov_*`, ROP frames, tramp, heap repair, SN/CB | **No** in-repo dumper |
| USB DWC2 MMIO map for t8027 | `USB_DMA_DEST`, cleanup USB base | **No** |
| Live DFU identity | CPID/SRTG/ECID | **Yes** — captured |
| Empty stubs | Placeholders | **Yes** — [`stubs/`](stubs/) |

### Honest notes on “SecureROM dump method”

- Lumina and the nested upstream tree **do not document** a t8027 (or even t8020) SecureROM dump procedure. Published ports ship finished constants.
- Upstream blog link (`ps.tc` usbliter8 post) may be unavailable; the public write-up PDF describes the **bug class and A12 ROP strategy**, not a dump how-to for 4172.
- Researchers typically obtain SecureROM images from existing RE corpora / device-specific acquisition methods outside this repo. This note does **not** invent or prescribe an undocumented dump exploit.
- Until a 4172 image is in hand, **do not fill stub addresses**. Keep `#error` guards.
- Acquisition pointers (securerom.fun, verify workflow): [SECUREROM_ACQUISITION.md](SECUREROM_ACQUISITION.md).

When an image exists (local, gitignored), record provenance in a private lab note: hash, SRTG string match, tool used — do not commit dumps to this repo.

---

## First real derivation steps (Mac checklist)

Research-only. Still no claim of pwn. Prefer `~/Projects/lumina`.

1. **Reconfirm identity** (device in DFU, data USB-C cable):

   ```bash
   cd ~/Projects/lumina
   python3 ./usbliter8ctl info
   ```

   Expect `CPID:8027` … `SRTG:[iBoot-4172.0.0.100.14]` and **no** `PWND:[usbliter8]`.

2. **Ensure upstream clone** (gitignored) for reading t8020/t8006 as teachers:

   ```bash
   # see upstream/README.md
   ls upstream/usbliter8/t8020_t8006_shellcode/targets/t8020/offsets.h
   ```

3. **Obtain / verify a SecureROM image** whose embedded version string matches `4172.0.0.100.14` — see [SECUREROM_ACQUISITION.md](SECUREROM_ACQUISITION.md). Record SHA-256 locally; do not commit the blob.

4. **Load in your RE tool** and search for stable strings / xrefs used on t8020 (serial construction, USB request handling, demote, memcpy). Build a **scratch symbol table** — do not paste guesses into git stubs yet.

5. **Diff roles, not numbers:** open t8020 `offsets.h` + `t8020_create_overwrite` side-by-side with your 4172 symbols; fill a **local worksheet** (columns: role, t8020 VA, t8027 VA, evidence). Only after evidence exists, edit `research/usbliter8-t8027/stubs/...` in a later PR.

6. **Defer Pico race attempts** until ROM + at least DMA/stack anchors exist. Blind timing with t8020 UF2 on CPID 8027 is not a derivation plan (device may simply hit “not supported”).

7. **Do not** touch `boot/`, invent `resources/*_t8027.h`, or claim PWND from DFU enum alone.

---

## See also

- Identity + full t8020 inventory: [docs/research/usbliter8-t8027-bringup.md](../../docs/research/usbliter8-t8027-bringup.md)
- SecureROM acquisition: [SECUREROM_ACQUISITION.md](SECUREROM_ACQUISITION.md)
- Symbolization worksheet: [SYMBOL_WORKSHEET.md](SYMBOL_WORKSHEET.md)
- Stubs: [stubs/](stubs/)
- XR handler reference (t8020 only): [research/CUSTOM_BOOT_NEXT.md](../CUSTOM_BOOT_NEXT.md)
- Upstream clone: [upstream/README.md](../../upstream/README.md)
