# A12X SecureROM RE worksheet — iBoot-4172.0.0.100.14 (t8027)

**Phase:** 1 — RE only toward `PWND:[usbliter8]` on A12X.  
**Not this phase:** Pico UF2 flash, iBSS/ramdisk, bootstrap/AMFI, XR kernel work.  
**Do not commit ROM binaries to git.**

Deeper notes already in-repo (structure + PAC):  
[`research/usbliter8-t8027/FIRST_RE_PASS.md`](../research/usbliter8-t8027/FIRST_RE_PASS.md),  
[`research/usbliter8-t8027/SYMBOL_WORKSHEET.md`](../research/usbliter8-t8027/SYMBOL_WORKSHEET.md),  
[`docs/research/usbliter8-a12x-ipad-pro-12.9-3rd.md`](research/usbliter8-a12x-ipad-pro-12.9-3rd.md).

---

## 1. ROM on this Mac

| Field | Value |
|-------|--------|
| Path (Downloads) | `/Users/kolby/Downloads/SecureROM for t8027si, iBoot-4172.0.0.100.14` |
| Lab copy (gitignored) | `research/usbliter8-t8027/artifacts/SecureROM_t8027_4172.bin` |
| Size | **163840** bytes (`0x28000`) |
| SHA-256 | `223866855772be24ac57d4ac0033fd6f99012a2e94646b9e2094b3adee7a8baf` |
| Identity strings | `SecureROM for t8027si…`, `iBoot-4172.0.0.100.14` |
| Downloads ≡ artifacts | **yes** (same SHA-256) |

Quick re-check:

```bash
ROM="$HOME/Downloads/SecureROM for t8027si, iBoot-4172.0.0.100.14"
wc -c < "$ROM"
shasum -a 256 "$ROM"
strings -a "$ROM" | grep -E 'iBoot-4172\.0\.0\.100\.14|SecureROM for t8027si'
```

---

## 2. Open at base `0x100000000`

SecureROM VAs below = **`0x100000000 + file_offset`**.

### Binary Ninja
1. **File → Open** the ROM path above.  
2. Architecture: **aarch64** / ARMv8.  
3. Image base / load address: **`0x100000000`**.  
4. Do **not** treat as Mach-O/IMG4 — raw binary.  
5. Optional: create a segment `0x100000000`–`0x100028000` (file size).

### IDA
1. Open as **Binary file**, processor **ARM Little-endian [ARM64]**.  
2. Loading address / ROM start: **`0x100000000`**.  
3. File offset → VA: add `0x100000000`.

### Ghidra
1. New project → Import File → format **Raw Binary**, language **AARCH64:LE:64:v8A**.  
2. In options: base address **`0x100000000`**.  
3. Analyze; jump to the VAs in the worksheet.

Host-side string map (no decompiler needed):

```bash
strings -a -t x "$ROM" | grep -E 'DFU Mode|SRTG:|CPID:%04X|iBoot-4172|t8027si'
```

---

## 3. Worksheet

| role | VA | notes | confidence | PAC risk |
|------|-----|-------|------------|----------|
| Version string `iBoot-4172…` | `0x100000280` | Identity / SRTG text | **confirmed** | n/a |
| ` SRTG:[%s]` | `0x10001d4c2` | Used by serial builder | **confirmed** | n/a |
| DFU name string | `0x10001d45a` | `adr` from DFU setup @ `0x10000ad58` | **confirmed** | n/a |
| USB serial builder | `0x1000067bc` | Formats CPID + SRTG into SRAM buf @ `0x19C010058`; `pacibsp`/`retab`; **does not** store code ptrs | **confirmed** | **high** (pro/epi) |
| Format / append helpers | `0x1000115a8` / `0x1000116c8` | Called from serial builder | **high** | check |
| **Direct caller of serial builder** | `0x10000dda0` | Sole `bl 0x1000067bc` site (`0x10000de24`); fills USB desc fields under `0x19C00C6F0` / `0x19C010D10`; ends with `bl 0x10000da50` | **confirmed** | **high** — `pacibsp`/`retab` |
| **DFU setup (parent)** | `0x10000ad30` | `adr` DFU string → `bl 0x10000dda0`; gate byte `0x19C010800`; on DFU enum path | **confirmed** | **high** — `pacibsp`/`retab` |
| DFU setup trampoline | `0x10000adc0` | `bl` helpers → `autibsp` → `b 0x10000ad30` | **confirmed** | **high** — `autibsp` before tail `b` |
| Serial string SRAM buf | `0x19C010058` | ASCII output of builder (data) | **high** | n/a |
| DFU-ready flag | `0x19C010800` | `ldrb`/`strb` gate in DFU setup/teardown | **high** | n/a |
| **USB handler table base** | `0x19C010C80` | **15× u64** (`0x78` bytes); idx = byte_off/8 | **confirmed** | see install/dispatch |
| Default ROM table (install src) | `0x100023040` | Returned by `0x10000c2cc` (`adr x0,…; ret`); copied wholesale into SRAM table | **confirmed** | raw code VAs in ROM |
| Handler-table installer | `0x10000da04` | `x0==0` → `bzero` `0x78`; else `memcpy` from `x0`; **no** `pacia`/`paciza` on elements | **confirmed** | prologue `pacibsp`/`retab` only |
| Handler dispatch stubs | `0x10000da50+` | Per-slot: `ldr xn,[0x19C010C80+#off]; cbz; br xn` — **no** `autia`/`autiza`/`xpaci`/`blraa` before `br` | **confirmed** | **raw `br`** |
| Control-req parser (SETUP) | `0x10000e2f8` | Copies SETUP to `0x19C010D08`; standard vs class; jump table `@0x10000e8e0` | **confirmed** | `pacibsp`/`retab` |
| `JUMP_STATE` | `0x19C014030` | Materialized @ `0x100001944` | **confirmed** | n/a |
| PAC census | — | `pacibsp`×462 / `retab`×364 vs t8020 0/0 | **confirmed** | blocks blind XR ROP |

### Table layout `0x19C010C80`

| idx | slot off | dispatch stub | default ptr (ROM `@0x100023040`) | DFU SETUP relevance |
|-----|----------|---------------|----------------------------------|---------------------|
| 0 | `+0x00` | `0x10000da50` | `0x10000cc40` | Init only (`bl` from `dda0` after serial) — **not** SETUP parse |
| 1 | `+0x08` | `0x10000da7c` | `0x10000d290` | Teardown / secondary |
| 2 | `+0x10` | `0x10000daac` | `0x10000c2d8` | — |
| 3 | `+0x18` | `0x10000dadc` | `0x10000c434` | Teardown path (`eb68`) |
| 4 | `+0x20` | `0x10000db0c` | `0x10000c538` | Std **SET_FEATURE / SET_ADDRESS** (bReq 3/5) |
| 5 | `+0x28` | `0x10000db3c` | `0x10000c578` | Config-related (`e940`) |
| 6 | `+0x30` | *(no stub)* | `0x10000c5b8` | Present in table; **no** `da50+` loader found |
| 7 | `+0x38` | `0x10000db6c` | `0x10000c718` | **Hot IN:** after GET_DESCRIPTOR / EP0 TX prep (`bl db6c`) |
| 8 | `+0x40` | `0x10000db9c` | `0x10000c7c4` | **Hot:** stall/status (`w0=0x80`) for many std bReqs + errors |
| 9 | `+0x48` | `0x10000dbcc` | `0x10000c860` | Std **CLEAR_FEATURE** (bReq 1) |
| 10 | `+0x50` | `0x10000dbfc` | `0x10000c8c4` | Device-to-host feature path |
| 11 | `+0x58` | `0x10000dc2c` | `0x10000c930` | *(no direct `bl` found)* |
| 12 | `+0x60` | `0x10000dc5c` | `0x10000c970` | **Every SETUP entry** in `e2f8` (`mov w0,#0x80; bl dc5c`) |
| 13 | `+0x68` | `0x10000dc8c` | `0x10000cb28` | *(no direct `bl` found)* |
| 14 | `+0x70` | *(no stub)* | `0x10000cc38` | In table only |

**Index source:** not computed at dispatch — each USB site hardcodes a stub, which hardcodes a slot offset. SETUP packet lives at **`0x19C010D08`**.

### Which slots fire on DFU SETUP?

From control parser **`0x10000e2f8`** (called from USB stack `@0x10000ccb4`):

| When | Slot(s) |
|------|---------|
| **Any** SETUP (`w1` bit0 set) before type switch | **`+0x60` first** (`mov w0,#0x80; bl dc5c`) |
| Std OUT bReq **1** CLEAR_FEATURE (endpoint) | `+0x48` then `+0x40` |
| Std OUT bReq **5** SET_ADDRESS | `+0x20` |
| Std OUT bReq **3** SET_FEATURE (device) | no c80 slot (writes `0x19C010D10`); EP feat → `+0x40` |
| Std OUT bReq **9** SET_CONFIGURATION | iface `obj+0x50` via `blr` (not c80); completion helper |
| Std IN bReq **0** GET_STATUS (endpoint) | `+0x50` then EP0 TX helper → may `+0x38` |
| Std IN bReq **6** GET_DESCRIPTOR | desc copy from `0x19C00C6F0+`; EP0 TX → **`+0x38`** |
| Std reject / stall epilogue | **`+0x40`** (`w0=0x80,w1=1`) |
| **DFU class** (type=class, recip=interface) | **Not via c80** — `blr` **`iface_obj+0x40`** (`list@0x19C010D10+0x60`) |

### USB device ctx `0x19C010D10` + DFU iface object

`0x19C010D10` is the **USB device/config context**, not the iface object itself.

| off | role |
|-----|------|
| `+0x00` | device feature / config byte |
| `+0x08` / `+0x0c` | transfer length / iface index (class path) |
| `+0x10` | **iface count** (`w32`) |
| `+0x14` | current configuration value |
| `+0x18` | data-stage bytes received |
| `+0x28` | data-stage cursor / buf bookkeeping (`x1` to class cb) |
| `+0x30` | string/desc helper result |
| `+0x38` | EP0 scratch buffer ptr |
| `+0x40` / `+0x48` | built config descriptors |
| **`+0x60 + i×8`** | **iface object pointer array** (indexed by SETUP `wIndex`) |

**How the DFU iface is found (class SETUP @ `0x10000e4c0`):**
1. Require recip=interface (`bmRequestType & 0x1f == 1`).
2. `wIndex` → compare against `d10+0x10` count.
3. `obj = *(d10 + 0x60 + wIndex×8)`.
4. `blr *(obj+0x40)` with `x0=SETUP@0x19C010D08`, `x1=d10+0x28`.
5. **No PAC** on this `blr`.

**DFU object install** (`0x10000eccc`, from DFU setup `ad30 → eccc`):
- DFU **state blob** fixed at **`0x19C010DD0`** (status/state, `+0x28` recv buffer ptr, etc.).
- After `str w1, [DD0+0x48]!`, registered iface object base = **`0x19C010E18`** (`DD0+0x48`).
- `bl 0x10000e2d0` → `*(d10+0x60 + count×8) = obj`; count++. DFU is iface **0**.

**Iface object @ `0x19C010E18` (offsets from registered base):**

| off | default VA | role |
|-----|------------|------|
| `+0x00` | `w32=1` | iface present / flags |
| `+0x08` | `0x100021c3c` | iface descriptor bytes |
| `+0x10` | `w32=1` | endpoint count-ish |
| `+0x18` | `0x100021c45` | endpoint descriptor bytes |
| **`+0x40`** | **`0x10000ede8`** | **shared DFU class SETUP callback** |
| **`+0x48`** | **`0x10000f004`** | **data-stage complete** (DNLOAD RX done; `blr` from `e480`) |
| `+0x50` | *(unset in `eccc`)* | SET_CONFIGURATION per-iface (`blr` if non-null) |
| `+0x70` | `0x10000f0f8` | DFU state helper (manifest/done) |
| `+0x78` / `+0x80` | *(unset)* | GET/SET_INTERFACE hooks if present |

### DFU class bRequest → field (not separate slots)

All class SETUP goes through **one** field: **`obj+0x40` → `0x10000ede8`**, which switches on `bRequest`:

| bRequest | name | path in `ede8` |
|----------|------|----------------|
| **1** | **DNLOAD** | OUT: `ee90` — `wLength==0` → state dnload-idle; else if `<0x801` publish buf to `x1`, else error |
| **2** | **UPLOAD** | **not implemented** — falls to `eedc` (`w0=-1`) |
| **3** | **GETSTATUS** | IN: `eee4` — builds 6-byte status from `DD0` into `DD0+0x28` |
| 4 | CLRSTATUS | OUT with ABORT: `ee10` reset status |
| 5 | GETSTATE | IN: `ee74` — 1-byte state |
| 6 | ABORT | OUT with CLRSTATUS: `ee10` |

**Shared / default handler:** `obj+0x40` (`ede8`). DNLOAD payload completion uses sibling **`obj+0x48`** (`f004`), not a separate DNLOAD function pointer.

### Iface callback auth (parallel to c80)

| Stage | Semantics |
|-------|-----------|
| Install `eccc` | `adr` + `str`/`stp` of raw code VAs — **no** `pacia`/`paciza` |
| Class SETUP call | `ldr` `[obj+0x40]` → **plain `blr`** — **no** `blraa`/`autia`/`xpaci` |
| Data-stage call | `ldr` `[obj+0x48]` → **plain `blr`** |

**Overwrite-with-raw-gadget viable on iface callbacks?** **Yes** — same as c80: raw store, raw `blr`. Caveat: targets entered with `blr` (LR set); real `pacibsp`/`retab` functions OK; object lives at fixed SRAM **`0x19C010E18`**.

### DFU DNLOAD data-stage buffer (bRequest=1)

**Allocation** (`0x10000eccc`, once at DFU setup):
```text
bl 0x100011f60          ; region/tag select (w0=0x200, w1=0x30000)
mov w0, #0x800
bl 0x1000100b8          ; heap alloc 0x800
str x0, [DD0+0x28]      ; buffer base pointer
bl 0x1000118e0          ; clear 0x800 bytes
```
→ Buffer is **heap/dynamic** (arena meta @ `0x19C011728` / `0x19C012148`). **No fixed SRAM VA.**

**DNLOAD SETUP** (`ede8` @ `ee90`):
| check | effect |
|-------|--------|
| `wLength == 0` | state→dnload-idle; **no** data stage |
| `wLength >= 0x801` | DFU error status; reject |
| `1 ≤ wLength ≤ 0x800` | `* (d10+0x28) = *(DD0+0x28)` (cursor←base); `DD0+0x10 = wLength`; return `wLength` |

Class path then `stp w0, wIndex, [d10+8]` → **expected total** = `wLength` at `d10+0x08`.

**OUT data copy** (`e2f8` data path @ `e3b4`, `w1` bit0 clear):
```text
if received + pkt > d10+8:  stall; reset cursor/len
else:
  n = min(pkt, remaining)
  memcpy(d10+0x28, usb_pkt, n)     ; 0x100011730
  d10+0x28 += n;  d10+0x18 += n    ; cursor walks upward in heap buf
when transfer complete → blr obj+0x48 (f004)
```

**`f004` (data-complete):** verifies `x0 == DD0+0x10` (wLength); copies heap buf into image at `DD0+0x20` with further bounds vs `DD0+4` / `DD0+0xc` — does **not** enlarge the USB write window.

| limit | value |
|-------|-------|
| Max `wLength` (SETUP) | **`0x800`** (`cmp #0x801; b.lo accept`) |
| Allocated buffer | **`0x800`** |
| Per-packet | `min(pkt, remaining)`; EP0 pkt often ≤ `0x40` (`cmp w20,#0x40` at complete) |
| Unchecked memcpy? | **No** — cumulative check vs `d10+8` before copy |

**Fixed SRAM distances (for orientation; buffer is not here):**

| from → to | delta |
|-----------|-------|
| `0x19C010C80` → `0x19C010E18` | `+0x198` |
| `0x19C010C80` → `0x19C010DD0` | `+0x150` |
| `0x19C010DD0` → `0x19C010E18` | `+0x48` (object embedded) |
| heap buf base → C80 / E18 | **not fixed** (dynamic alloc) |

**Reachability via DNLOAD OUT write:**

| target | verdict | why |
|--------|---------|-----|
| `0x19C010C80` (+`0x60`) | **not reachable** | Write lands in heap buf, not USB SRAM; max `0x800` into `0x800` alloc; length-checked |
| `0x19C010E18` (+`0x40`/`+0x48`) | **not reachable** | Same; object is fixed SRAM **above** `DD0`, not the heap payload |
| Overflow past heap buf | **not via this path** | `received+pkt ≤ wLength ≤ 0x800` before `memcpy` |

Cursor growth is upward **within the heap buffer only**; it does not walk from `d10` toward `C80`/`E18`.

### Fixed USB SRAM map (`0x19C010000`–`~0x19C011000`)

| VA | size / notes | role |
|----|--------------|------|
| `0x19C010058` | ASCII | USB serial / SRTG string (builder `67bc`) |
| `0x19C010800` | byte | DFU-ready flag |
| **`0x19C010860`** | softctx | USB device soft-state (IRQ handler `x21`) |
| `860+0x20` → **`0x19C010880`** | ptr → **heap 0x40** | EP0 **data** buffer pointer |
| `860+0x28` → **`0x19C010888`** | ptr → **heap 8** | EP0 **SETUP** buffer pointer |
| `860+0x60` → **`0x19C0108C0`** | **`0x3c0`** | EP soft/TRB-ish region; **ends exactly at `C80`** |
| **`0x19C010C80`** | `0x78` | CB handler table |
| **`0x19C010D00`** | byte | USB ready flag (`dda0`) |
| **`0x19C010D08`** | **8** | **SETUP packet mirror** (software copy) |
| **`0x19C010D10`** | ctx | device/config ctx + iface ptr array |
| `d10+0x38` | ptr → heap `0x100` | EP0 descriptor scratch (`dda0`) |
| **`0x19C010DD0`** | state | DFU state blob |
| **`0x19C010E18`** | obj | DFU iface object (`DD0+0x48`) |

USB controller MMIO base (literal `0x100021bb8`): **`0x25D100000`**.

### Ordered attacker-influenced writes vs `C80+0x60`

SETUP IRQ path: `0x10000ccb4` → `0x10000ced0` → `0x10000e2f8`.

| # | where | size | who controls | before `+0x60`? |
|---|-------|------|--------------|-----------------|
| 1 | **heap** `*0x19C010880` (EP0 data) | ≤`0x40` | USB **DMA** (host SETUP/OUT) | **yes** (HW, before software parse) |
| 2 | **heap** `*0x19C010888` (SETUP buf) | 8 | software `cea0`: `*setup = *ep0_data` (when IRQ flags set); else prior contents | **yes** |
| 3 | **fixed `0x19C010D08`** | **8** | software `e32c`: `str` first qword from SETUP buf — full SETUP fields | **yes — immediately before** |
| 4 | `br` `C80+0x60` | — | `e334: bl 0x10000dc5c` | *(handler runs)* |
| 5 | later `blr obj+0x40` | — | class path `e504` | after `+0x60` |

Other fixed writes in the same IRQ **before** step 3 (`str`/`strb` to `860+…`) are **controller status / ROM constants**, not packet payload.

**EP0 heap buf alloc:** **`0x10000c2d8`** (`0x40` @ `*880` + `8` @ `*888` via `100b8`).

### USB DMA register map (ROM-evidenced)

MMIO base literal `@0x100021bb8` → **`0x25D100000`**. Per-EP stride **`<<5`**. OUT-side regs at `+0xb00/+0xb10/+0xb14`; IN-side at `+0x900/+0x910/+0x914` (see `cb50` / `d5ec`).

| MMIO off (EP0 ⇒ ep<<5=0) | writers | value programmed |
|--------------------------|---------|-------------------|
| **`+0xb14`** (OUT DMA addr) | **`d1fc` `d250`**; **`d90c` `d990`**; `cb50` clears to 0 | see below |
| **`+0xb10`** (OUT DMA ctl/len) | **`d1fc` `d230`** (`0x20080040`); **`d90c` `d9dc`**; `cb50` clears | len/pkt fields |
| **`+0xb00`** (OUT EP ctl) | `d1fc` / `d90c` / reset path | arm/enable bits |
| **`+0x914`** (IN DMA addr) | **`d5ec` `d67c`** | `xfer.buf+off` (not `+0xb14`) |
| `+0xb10` read | `cee4` | status during IRQ |

### All `+0xb14` value sources

| site | when | address written |
|------|------|-----------------|
| **`0x10000d1fc`** | EP0 re-arm: bus reset `ce34`; after SETUP/data parse `cf10` | **always** `lo32(*(0x19C010880))` — heap `0x40` EP0 data buf |
| **`0x10000d90c`** | OUT xfer start/continue (`c7a8`, IRQ `d4f4`/`d528`) | `lo32(*(xfer+8) + xfer.off)` — xfer from softctx queue `@ slot+0x88`; for EP0 still MMIO`+0xb14` |
| **`0x10000cb50`** | EP teardown | **`0`** (not a buffer VA) |

**Is `+0xb14` always `*(880)`?** **No.**  
- **SETUP / idle re-arm (`d1fc`):** yes → heap `*880`.  
- **OUT data (`d90c`):** transfer-object buffer (DNLOAD heap, other request bufs via `eab0`/`dd08` — still **heap / caller VA**, not softctx).  
- **IN:** uses **`+0x914`**, not `+0xb14`.

**Any path programming a non-heap address into `+0xb14`?** **None found** in ROM `str`s. Fallback EP0 TX scratch is `*(d10+0x38)` (also heap `0x100` from `dda0`).

### Fixed `0x19C0108C0`–`C80` as DMA target?

| check | result |
|-------|--------|
| `str` of VA ∈ `[0x19C0108C0, 0x19C010C80)` into `+0xb14` / `+0x914` | **never** (no xref) |
| `d1fc` length walk from `*880` into `8C0` | **no** — len fixed `0x40` into heap alloc; `*880` only set by `c2d8` heap |
| Verdict | **never** software-selected as USB DMA target |

**What `0x3c0` EP soft state is:** **CPU-only** per-EP structs (stride `0x50` from softctx `860`; region `860+0x60`‥`C80`). Holds ep addr/maxpacket (`+0x60`‥), active flag (`+0x7c`), **xfer queue head/tail (`+0x88/+0x90`)**, etc. Hardware sees buffer VAs from **xfer objects**, not this abutting slab. Adjacency: `8C0+0x3c0 = C80` exactly — layout contact only.

### Best candidate (before handler)

**Best software write into fixed USB SRAM before `+0x60`:** **`0x19C010D08`** — 8-byte SETUP mirror (`e32c` then `e334` → `+0x60`). Does not reach `C80`/`E18`. No pre-handler SW write into callback slots.

### USB IRQ routing (`0x10000ccb4` + latch `0x10000d294`)

Two stages:

1. **`0x10000d294`** (HW IRQ registered @ `c3e0`): read MMIO → softctx; may **`bl d90c`/`d5ec`**; set `860+4` bit0; signal worker (`a178`).
2. **`0x10000ccb4`** (deferred): consume latches; SETUP/`e2f8` → **`C80`**.

| source → latch | |
|----------------|--|
| `MMIO+0x14` → `@860+8` (`w23`) | device IRQ word |
| `MMIO+0x818` → `@860+0xc` (`w27`) | per-EP bitmap (if `w23 & 0xc0000`) |
| `MMIO+0xB08` → `@860+0xc0` (`w19`) | EP0 OUT status (via `d294`: `x23=MMIO+0x908`, `ldr [x23,#0x200]`) |
| `@860+4` bit0 | `ccb4` work gate |

#### Bit → path (`ccb4`)

| Path | Site | Exact test | Notes |
|------|------|------------|-------|
| no work | `cd20` | `tbz [860+4], #0` | |
| enum/bring-up | `cd48` | `tbz w23, #0xb` | else `cfa8`/`d110` |
| bus reset + EP0 re-arm | `cd64` | `tbz w23, #0xc` | wipe `8C0`/`0x3c0`; **`bl d1fc`** |
| misc | `ce38` | `tbz w23, #0xd` | `MMIO+0x808` |
| EP IRQs pending | `ce48` | `and w8, w23, #0xc0000`; `cbz` | bits **18\|19** |
| EP0 IN drain | `ce54` | `tbz w27, #0` | else `d140(0x80)` |
| EP0 OUT enter | `ce60` | `tbz w27, #0x10` | DAINT bit **16** |
| **SETUP → `e2f8` → `C80+0x60`** | `ceac`–`ced0` | `(w19 & #8) != 0` and `[860]==1`; `e2f8(,…,w1=1)` | EP0 OUT status **bit 3** |
| **OUT data → `e2f8`** | `cedc`–`cefc` | SETUP bit clear / `#0x8000` arm; `e2f8(,…,w1=0)` | |
| EP0 re-arm | `cf10` | after `e2f8`: **`bl d1fc`** | |
| other EPs | `cf14`+ | bit walk `w27` → `d140` | drain only |

**`d90c`/`d5ec`:** **not in `ccb4`** — only from **`d294`** (`d4f4`/`d528` → `d90c`; `d38c`/`d3c0` → `d5ec`).

#### When is `C80` indexed?

- **Not** every IRQ; **not** from `ccb4`/`d90c`/`d5ec`/reset directly.
- **Yes** after `ccb4` → **`e2f8`**: SETUP always `bl dc5c` (`+0x60`); std-request arms use other stubs; OUT data path may hit `+0x40` stall.

```text
d294 (MMIO latch + optional d90c/d5ec) → set +4 bit0
ccb4: bits 18|19 → DAINT bit16 → DOEP bit3
   → e2f8: str → D08; bl dc5c; ldr [C80+0x60]; br
```

#### Ordering

```text
DMA → heap *880
 → d294 softctx (+ maybe d90c/d5ec)
 → ccb4 SETUP: D08 mirror → C80+0x60 → d1fc
```

Gap before `+0x60`: softctx/queues only — no SW callback-slot write.

### EP0 bring-up order (to first `d1fc`)

Call chain from DFU setup (`0x10000ad30`):

```text
ad30
 ├─ da04              install C80 defaults (ROM table @23040)
 ├─ dda0              serial/desc identity
 │   └─ da50 → cc40   register worker ccb4 (@9bc4); init softctx events
 ├─ eccc              DFU iface object @ E18
 └─ df84              build config descriptors
     └─ e288 → daac → c2d8     USB softctx + controller init
          ├─ alloc *880 (0x40), *888 (8); bzero 8C0..C80
          ├─ cfa8              MMIO bring-up (below) — **no +0xb14 yet**
          ├─ 2cd0(d294)        register HW IRQ latch
          └─ d110              tweak MMIO+0x804
… host issues bus reset …
d294: MMIO+0x14 bit12 → latch w23 → wake ccb4
ccb4 bit12 path (cd64):
 ├─ wipe softctx 8C0 (0x3c0); re-seed EP0 soft fields
 ├─ MMIO EP/IRQ re-arm (below)
 └─ **d1fc**           FIRST program +0xb14 ← *880  ← EP0 can accept SETUP DMA
```

#### `cfa8` MMIO stores @ `0x25D100000` (before any `d1fc`)

| Order | Off | Value / source | Role (from use) |
|------:|-----|----------------|-----------------|
| 1 | `+0x10` | `1` | soft-connect / run bit; polled until clear |
| 2 | `+0x804` | `orr #2` | (after AHB idle wait) |
| 3 | `+0x8` | `orr #0x21` w/ ROM byte | device config |
| 4 | `+0xc` | `8 \| (byte<<10)` | device config2 |
| 5 | `+0x800` | `4` | |
| 6 | `+0x18` | `0` then later **`0x3000`** | IRQ mask — **`0x3000` = bits 12\|13** (arms bus-reset bit12) |
| 7 | `+0x814/810/81c` | `0` | clear EP IRQ en masks |
| 8 | `+0x14` | `-1` | clear device IRQ status |
| 9 | `+0xba8`‥ (loop ×5, step `-0x20`) + peer `-0x200` | `0xf` / `0x1f` | per-EP FIFO/flush words |
| — | *(side)* | `6db8(0xb0006,…)` → **`0x203D2B8030`** | **not** `25D1`; PMGR/clk-style window — **not DART** |

`cfa8` also fills softctx `@860+0x10/+0x14` from `MMIO+0x4c` (size caps). **No `+0xb14` / `+0xb10` / `+0x914` here.**

#### Bus-reset bit12 path (`ccb4` `cd64` → first `d1fc`)

| Order | Off | Value | Notes |
|------:|-----|-------|-------|
| 1 | `+0x814/810/81c` | `0` | clear |
| 2 | softctx `8C0` | `bzero 0x3c0` | **rebuild EP soft state**; **not** `C80` |
| 3 | `+0x24` / `+0x28` | `0x21b` / `0x100021b` | |
| 4 | `+0xb00` / `+0x900` | `0` | clear EP0 OUT/IN ctl |
| 5 | `+0x18` | `orr` large mask incl. `#0x800` | re-enable IRQs |
| 6 | `+0x814/810` | `0xd`; `+0x81c`=`0x10001` | EP IRQ enables |
| 7 | **`d1fc`** | **`+0xb10`=`0x20080040`, `+0xb14`=`lo32(*880)`** | **first EP0 DMA arm** |

**Bit12 armed by:** `cfa8` final `str 0x3000 → MMIO+0x18` (unmasks bits 12\|13). HW then sets `MMIO+0x14` bit12 on bus reset; `d294` ORs into `@860+8`.

**Reset rebuilds?** softctx `8C0` yes; EP0 soft fields yes; **`C80` no** (left as `da04` install); heap `*880` **reused** if non-null (`c2d8` only allocs once).

**DART / SMMU / IOMMU:** **never** appears in this bring-up (no strings; no stores into a DART-like window). Side window is only `0x203D2B8030` via `6db8`. Next place to look: platform init before DFU (`6e10` / early `b52c` path), not USB EP0.

### Race surface after `d1fc` → before `C80+0x60` (SETUP)

Timeline under test: return from **first** `d1fc` (post bit12) → host SETUP DMA → `d294` → `ccb4` SETUP → `e2f8` → `br` `[C80+0x60]`.

| Reg | ROM use on SETUP path | Window before `+0x60`? | Race interest |
|-----|----------------------|-------------------------|---------------|
| `+0xb00` | **`d1fc`**: `ldr` busy (bit31); `str` arm (`orr` `0x80000000` / `0x84000000`) | only **inside** `d1fc` (before DMA) | EP arm/doorbell — not re-touched until after `+0x60` (`cf10`→`d1fc`) |
| `+0xb10` | **`d1fc`**: `str 0x20080040` (len `0x40`) | only in `d1fc` | length/ctl; **not read** on SETUP before `+0x60` (`cee4` is OUT-data path only) |
| `+0xb14` | **`d1fc`**: `str lo32(*880)` | only in `d1fc` | buffer ptr; ROM **never reloads** it before parse — uses softctx `*880` + heap |
| `+0x14` | **`d294`**: `ldr` + `str` (W1C ack) | **yes** | IRQ status latch → `@860+8`; path select only |
| `+0x818` | **`d294`**: `ldr` if `+0x14 & 0xc0000` | **yes** | DAINT → `@860+0xc`; EP0 OUT = bit16 |
| `+0xB08` | **`d294`**: `ldr` + `str` (W1C) via `MMIO+0x908+0x200` | **yes** | EP0 OUT status → `@860+0xc0`; **bit3** ⇒ SETUP |
| `+0x18` | **`d294`**: `ldr` mask & status → wake worker | **yes** | gate `ccb4` only |
| `+0xb14` via `d90c` | **skipped for EP0** (`d294`: `cbz x24 →` skip xfer/`d90c`) | n/a on SETUP | cannot retarget EP0 DMA mid-SETUP via that path |

**`ccb4` / `cea0` / `e2f8` before `+0x60`:** softctx + heap only — **zero MMIO** until after handler (`cf10`→`d1fc` re-arm).

#### Gap inventory (MMIO vs softctx)

| Phase | MMIO | Softctx / heap |
|-------|------|----------------|
| `d1fc` | `+0xb00/b10/b14` | load `*880` |
| DMA | *(HW → heap)* | |
| `d294` | `+0x14`, `+0x818`, `+0xB08`, `+0x18` | latch `@860+8/+0xc/+0xc0`; **no** `d90c` on EP0 |
| `ccb4` SETUP | — | bit tests; optional `*880→*888`; `e2f8` |
| `e2f8`→`dc5c` | — | `D08` mirror; `ldr [C80+0x60]; br` |

#### Ranked race candidates

| Rank | Surface | Why |
|------|---------|-----|
| **1** | **Heap `*880` (DMA data)** | Only attacker-controlled bytes that SETUP parse consumes; fixed VA from softctx, not from re-reading `+0xb14` |
| **2** | **`+0xb14` (HW-only race)** | If something outside this CPU path changes the DMA addr **after** `d1fc` `str` and **before** DMA completes, HW could land elsewhere — **not** driven by USB packets alone; ROM does not re-check |
| — | `+0xB08` / `+0x14` | Select SETUP vs data / wake worker; host influences via **real** USB events, not by forging MMIO; no callback corruption |

**To matter before `ldr [C80+0x60]` a race would need to:** change **heap SETUP bytes** (normal DMA — already owned), or **redirect DMA** (change `+0xb14`/`+0xb10` pre-completion from outside ROM), or **corrupt `C80` itself** (no SW path found). Status-bit games only change control flow, not slot contents.

### Phase-1 exploitability verdict (software + MMIO map)

| Claim | Verdict |
|-------|---------|
| Controlled SW write into `C80` / `E18` cbs? | **No** |
| DMA target fixed to heap (`*880` / xfer heap)? | **Yes** on EP0 SETUP (`d1fc`; EP0 skips `d90c`) |
| Fixed SRAM SETUP mirror `D08` reaches cbs? | **No** (8 B, wrong side of `C80`) |
| DNLOAD heap overflow → cbs? | **No** (checked `≤0x800`) |
| **Best remaining lever** | **HW timing / non-ROM agent** against `+0xb14` pre-DMA, or a **new bug class** outside this USB parse map — not a clean SW callback plant from DFU SETUP alone |

### Raw or PAC-signed before `br`?

| Stage | Semantics |
|-------|-----------|
| Install `0x10000da04` | **Raw** `memcpy`/`bzero` of 15 pointers — **no** element PAC |
| Default fill | ROM literals @ `0x100023040` = plain code VAs |
| Dispatch stub | `ldr` → **`br xn`** with **zero** auth/strip insns |

**Overwrite-with-raw-gadget viable?** **Yes (for slot contents)** — table holds and `br`s raw PCs.  
Caveat: planted target is entered by `br` (LR still inside the USB caller/`bl` stub path). Handlers that expect `pacibsp`/`retab` pairing can still run if they are real functions; bare XR-style `ret` gadgets are **uncertain/unsafe**. Callers of stubs remain PAC-wrapped (`pacibsp`/`retab`/`autibsp`).

### Call chain (serial — prior)

```text
0x10000adc0  bl c2cc → x0=0x100023040; autibsp; b ad30
0x10000ad30  bl da04 (install defaults); bl dda0 (serial/desc); …
0x10000dda0  bl 67bc; …; bl da50 (slot+0)
```

### Structure-only vs t8020 — do **not** copy

| Shared *structure* | Divergent |
|--------------------|-----------|
| SRAM handler **table** + stub `br` | Base **`0x19C010C80`** ≠ `0x19C010C68` |
| Default ROM vector install | Exact slot indices / stub VAs |
| DFU class via iface object | Object @ **`0x19C010E18`**; list head ctx **`0x19C010D10`** |

---

## 4. Prior session (callers of `0x1000067bc`) — unchanged

Sole `bl`: `0x10000de24` in `0x10000dda0`; parent `0x10000ad30`; outer `0x10000adc0`.

---

## 5. Next single RE question

**Outside the EP0 SETUP map: does any non-SETUP path (`d90c` on EP≠0, DFU DNLOAD complete `f004`, or image copy @ `DD0+0x20`) ever write a caller-influenced pointer into `C80` / `E18` — or is the callback-plant surface closed for all USB DFU paths in this ROM?**
