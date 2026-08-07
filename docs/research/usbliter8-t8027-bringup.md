# usbliter8 → t8027 (A12X) SecureROM bring-up

**Date:** 2026-08-02 (identity locked 2026-08-03)  
**Target:** iPad Pro 12.9" 3rd gen (USB-C), A12X, CPID `0x8027` / t8027, iPadOS 26.5  
**Closest tree:** t8020 (shared `t8020_t8006_*` exploit path)  
**Status:** research + empty stubs only — **DFU identity captured; SecureROM pwn not implemented**

Nothing here is wired into `boot/`. DFU enum ≠ exploit success.

---

## Scope / non-claims

- XR (A12 / CPID `8020` / t8020) already reaches Pwned DFU + ICH lab on iOS 18.7.5 (separate device/path).
- A12X is **PARTIAL**: same DWC2 race *class*, **not** a board-file-only port.
- Goal of this track: **SecureROM bring-up** → Pwned DFU on A12X (not achieved here).
- Host tool (`usbliter8ctl`) needs no CPID table for post-PWND control; the missing work is Pico firmware offsets/ROP/shellcode/handler.

### Explicit non-claims

- No claim that usbliter8 pwns t8027 / A12X today.
- No claim of iPadOS 26.5 process exploit, kernel r/w, or untether **from this SecureROM track**.
- No Sileo / dpkg / bootstrap goal on 26.5.
- No DarkSword / kexploit port for this device in this memo.
- Do not reuse XR `n841ap` ramdisk / DeviceTree / UDID as if they were A12X.

**Cross-link (Path A/B PE hunt — separate tree):** iPadOS **26.5** delta research from
**26.6** patches lives under [`../../research/ipados26.5/`](../../research/ipados26.5/)
and [`../RESEARCH_PLAN_26.5.md`](../RESEARCH_PLAN_26.5.md). That track does **not**
wait on Pico/PWND. This bring-up doc remains **Path C only**.

---

## Required identity fields

### Live DFU capture (Mac, `~/Projects/lumina`, 2026-08-03)

```bash
python3 ./usbliter8ctl info
```

```text
05ac:1227 DFU
serial: CPID:8027 CPRV:01 CPFM:03 SCEP:01 BDID:0A ECID:0019052A1413002E IBFL:3C SRTG:[iBoot-4172.0.0.100.14]
```

No `PWND:[usbliter8]` — expected until a t8027 Pico port exists. Prefer root `./usbliter8ctl` under the Lumina clone (not other packaging trees).

| Field | Live value | Notes |
|-------|------------|-------|
| **CPID** | `8027` (`0x8027`) | Confirmed — Pico switch key |
| **CPRV** | `01` | Differs from XR lab sample (`11`) |
| **CPFM** | `03` | |
| **SCEP** | `01` | |
| **BDID** | `0A` | Board id (this unit); Wi‑Fi vs Cellular may differ across units |
| **ECID** | `0019052A1413002E` | Unique to this iPad |
| **IBFL** | `3C` | |
| **SRTG** | `[iBoot-4172.0.0.100.14]` | **Not** XR’s `iBoot-3865.0.0.4.7` — offsets must be re-derived against this SecureROM |
| **UDID** (host later) | `00008027-0019052A1413002E` | Derived shape only — **not** wired into `boot/` |

XR serial (format / contrast only):

```text
CPID:8020 CPRV:11 CPFM:03 SCEP:01 BDID:0E ECID:XXXXXXXXXXXXXXXX IBFL:3C SRTG:[iBoot-3865.0.0.4.7] PWND:[usbliter8]
```

Bring-up success (not claimed) means the A12X serial gains `PWND:[usbliter8]` after a future Pico pwn.

---

## t8020 → t8027 constant inventory

All SecureROM / SRAM / USB / ROP / handler constants live in the **Pico firmware** tree (`upstream/usbliter8/`, gitignored local clone — see [upstream/README.md](../../upstream/README.md)). Values below are the **t8020 baseline that must be re-derived** for t8027. Do **not** copy them blindly onto A12X.

### 1. CPID dispatch (`exploit.c`)

| Location | t8020 | t8027 action |
|----------|-------|--------------|
| Outer `exploit_run` switch (~791) | `case 0x8020` / `0x8006` → `t8020_t8006_exploit_run` | Add `case 0x8027` only after config/ROP/shellcode exist |
| Inner `t8020_t8006_exploit_run` (~471) | `case 0x8020` → `&t8020_config` | Add `case 0x8027` → `&t8027_config` (or equivalent) |
| Unsupported path | `T%04X is not supported (yet?)` | Current behavior for `8027` until filled |

### 2. Config blob (`t8020_config`)

| Field | t8020 value | t8027 |
|-------|-------------|-------|
| `cpid` | `0x8020` | `0x8027` |
| `delay` | RP2350: `10` / RP2040: `5` | Re-tune on hardware (TODO) |
| `ov_start` | `0x19C02960C` | TODO |
| `ov_size` | `0xB04` | TODO |
| `shc_base` | `0x19C018000` | TODO |
| `shc_start` | `0x19C0183EC` | TODO |
| `shc_size` | `0x400` | TODO |
| `create_overwrite` / `create_shellcode` | `t8020_*` | New `t8027_*` once addresses known |

### 3. ROP overwrite (`t8020_create_overwrite`)

Every address written into the overwrite buffer is chip-specific:

| Role | t8020 address / value |
|------|------------------------|
| Frame start / new LR | `@0x19c028b18` ← `0x10000FC30` |
| load X19: X19 | `@0x19c028b58` ← `0x19C028D00` |
| load X19: next LR | `@0x19c028b68` ← `0x100007510` |
| X19 store value | `@0x19c028d00` ← `0x19C018400` |
| load W8: USB DMA dest | `@0x19c028b78` ← `0x239100b14` |
| load W8: next LR | `@0x19c028b88` ← `0x100007358` |
| store W8: next LR | `@0x19c028ba8` ← `0x10000e2bc` |
| store W8: X20 (delay ptr−8) | `@0x19c028b90` ← `0x19c028d00` |
| delay value | `@0x19c028d08` ← `TASK_SLEEP_US` |
| load W0: next LR | `@0x19c028bd8` ← `0x100003948` |
| load W0: X19 = `task_sleep` | `@0x19c028bc8` ← `0x100009880` |
| BLR X19: next LR (EL1) | `@0x19c028c28` ← `0x1000088B0` |
| X22 / X23 | `@0x19c028c00` / `@0x19c028bf8` ← `0x19C034000` |
| X24 | `@0x19c028bf0` ← `0x100000200` |
| Descriptor restore | `@0x19c029400` ← `ov_descriptors_t8020` |

### 4. Shellcode ROM/SRAM offsets

File: `t8020_t8006_shellcode/targets/t8020/offsets.h`

| Symbol | t8020 |
|--------|-------|
| `NEW_SP` | `0x19C028BC0` |
| `MEMCPY` | `0x100010BD0` |
| `STRLCAT` | `0x100010B60` |
| `CALCULATE_HEAP_BLOCK_SUM` | `0x10000F664` |
| `TRAMP_BASE` | `0x19C018000` |
| `ROM_TRAMP` | `0x100007640` |
| `ROM_TRAMP_LEN` | `0x480` |
| `BOOT_TRAMP_PTEP` | `0x19C004030` |
| `BOOT_TRAMP_PTE` | `0x19C0186E3` |
| `DMA_BUF_LO` | `0x9C029600` |
| `USB_DMA_DEST` | `0x239100B14` |
| `JUMP_STATE` | `0x19C014030` |
| `HEAP_BLOCK_TO_REPAIR_DMA` | `0x19C0295C0` |
| `HEAP_BLOCK_TO_REPAIR_IO_BUF` | `0x19C028BC0` |
| `HEAP_WHATEVER_THAT_IS` | `0x19C011468` |
| `USB_SN_STR` | `0x19C00BC58` |
| `USB_DEV_DESC_SN_IDX` | `0x19C00890A` |
| `USB_DESC_MAKE_STR` | `0x10000D584` |
| `USB_REQ_HANDLER_CB_ADDR` | `0x19C010C68` |
| `RETURN_TO_EL0_ADDR` | `0x10000C408` |

Also: heap block list in `targets/t8020/blocks.S` (`0x19C028BC0`, `0x19C029400`, `0x19C029480`, `0x19C029500`, `0x19C0295C0`) and pre-return cleanup in `targets/t8020/cleanup.S` (stack canary `0x19C008448`, task-tramp LR `0x10000ACEC`, USB base `0x239100000`, related SRAM/USB slots).

### 5. USB request handler offsets

File: `usb_req_handler/targets/t8020/offsets.h` (also mirrored in Lumina `tools/decode_t8020_handler.py` / `research/CUSTOM_BOOT_NEXT.md` for XR — t8020 reference only):

| Symbol | t8020 |
|--------|-------|
| `HANDLE_USB_REQ` | `0x10000E3EC` |
| `PLATFORM_DEMOTE` | `0x100007CF8` |
| `PLATFORM_SET_REMOTE_BOOT` | `0x100006850` |
| `MAIN_TASK_STACK_LR` | `0x19C01DF08` |
| `JUMP_AWAY` | `0x100001C8C` |

t8020 has **no** `WITH_PAC` path (unlike t8030). Confirm SecureROM PAC behavior for A12X before assuming the t8020 handler shape is drop-in.

### 6. Generated / hand blobs

| Blob | t8020 path | t8027 |
|------|------------|-------|
| Descriptors | `resources/descriptors_t8020.h` | Hand-author after SRAM layout known — **do not invent** |
| Shellcode | `resources/shellcode_t8020.h` | Regenerate via `TARGET=t8027 ./t8020_t8006_shellcode/make.sh` after offsets |
| Handler | `resources/handler_t8020.h` | Regenerate via `TARGET=t8027 ./usb_req_handler/make.sh` after offsets |

### 7. Host (post-pwn) — mostly unchanged

Root `./usbliter8ctl` has **no CPID table**. It matches Apple DFU `05ac:1227` / Recovery `05ac:1281` and requires serial marker `PWND:[usbliter8]`. Post-PWND demote/boot against a t8027 handler is untested on this device.

**Out of scope for SecureROM bring-up:** `boot/lib-udid.sh`, XR UDID `00008020-…`, `n841ap` DeviceTree/iBSS/ramdisk.

---

## File-by-file change list

### Pico firmware (required for PWND)

Paths relative to local `upstream/usbliter8/` clone.

| File / tree | Change |
|-------------|--------|
| `exploit.c` | `t8027_config`, `t8027_create_overwrite`, `t8027_create_shellcode`; `case 0x8027` in both switches; includes for `resources/*_t8027.h` |
| `t8020_t8006_shellcode/targets/t8027/offsets.h` | Fill from t8027 SecureROM / SRAM map |
| `t8020_t8006_shellcode/targets/t8027/blocks.S` | Heap blocks for repair list |
| `t8020_t8006_shellcode/targets/t8027/cleanup.S` | Pre-return register/stack restore |
| `usb_req_handler/targets/t8027/offsets.h` | Handler ROM/SRAM symbols |
| `resources/descriptors_t8027.h` | After layout known |
| `resources/shellcode_t8027.h` | Build output — not hand-faked |
| `resources/handler_t8027.h` | Build output — not hand-faked |
| `boards/*.cmake` | Pico MCU board only — **not** Apple SoC; reuse existing Pico board configs |

Tracked empty stubs (TODO only, no invented addresses) live in-repo at:

[`research/usbliter8-t8027/stubs/`](../../research/usbliter8-t8027/stubs/)

Copy into the local upstream clone when filling; do not commit the nested upstream tree.

### Host (Lumina)

| File | Change for SecureROM bring-up |
|------|-------------------------------|
| `./usbliter8ctl` | None for CPID — use `info` / later `demote` / `boot` once PWND |
| `tools/decode_t8020_handler.py` | Keep as **t8020** reference; optional future `decode_t8027_handler.py` after a real blob exists |
| `boot/*` | **Do not wire** in this track |

---

## USB-C note

- **Protocol:** USB DFU on A12X USB-C iPads is the same class as Lightning DFU on XR (Apple DFU `05ac:1227`, same serial field layout). Cabling / physical attach differs; the DFU protocol does not become a different exploit API just because the connector is USB-C.
- **Upstream README warning** (“Do NOT use USB-C cables…”) refers to **Pico ↔ Lightning harness pinouts** (D+/D− mapping when adapting cables). It does **not** mean USB-C iPads cannot enter DFU or that the race is Lightning-only.
- For A12X: use a proper **data** USB-C cable host↔iPad for identity/`usbliter8ctl`; use a Pico harness with correct D+/D− for the race. Avoid charge-only C cables and random C-to-A adapters with unknown wiring.

---

## Success criteria / non-goals

| | |
|--|--|
| **Success (goal, not current state)** | Device re-enumerates in DFU with serial containing `PWND:[usbliter8]` (and `CPID:8027`) |
| **Current state** | Unpwned DFU identity only (`05ac:1227`, no `PWND`) |
| **Non-goals** | iPadOS 26.5 PE; Sileo/dpkg/bootstrap; ramdisk/SSH; wiring into `boot/`; claiming “jailbreak” |

---

## First live DFU checklist (human)

1. **Cables**
   - Short USB-C **data** cable: Mac/PC ↔ iPad (identity / `usbliter8ctl`).
   - Pico race harness: correct D+/D− to the iPad’s USB path (not through a charge-only cable; not assuming Lightning pinout adapters).
2. **Host USB driver**
   - **Windows:** if pyusb cannot open Apple DFU (`05ac:1227`), use Zadig → libusbK or WinUSB for that interface.
   - **macOS Sequoia (Lumina default):** skip Zadig; use brew `libusb` + `pyusb` ([AGENTS.md](../../AGENTS.md) / [boot/README.md](../../boot/README.md)).
3. **Enter DFU** on the iPad (normal DFU entry — do not rely on broken LLB). Confirm with one command:

```bash
python3 usbliter8ctl info
```

Identity already locked (see Live DFU capture above). Only after a future Pico pwn (not implemented) would `info` show `PWND:[usbliter8]`.

---

## See also

- Tracked stubs: [research/usbliter8-t8027/](../../research/usbliter8-t8027/)
- Next phase (derivation plan): [research/usbliter8-t8027/OFFSET_DERIVATION.md](../../research/usbliter8-t8027/OFFSET_DERIVATION.md)
- XR live status: [docs/STATUS.md](../STATUS.md)
- Upstream clone howto: [upstream/README.md](../../upstream/README.md)
- t8020 handler reference: [research/CUSTOM_BOOT_NEXT.md](../../research/CUSTOM_BOOT_NEXT.md)
