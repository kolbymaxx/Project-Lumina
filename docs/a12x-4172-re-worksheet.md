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

**EP0 DMA program site** (`0x10000d1fc`, also from bus reset path):
```text
x1 = *(0x19C010880)          ; heap EP0 data buf
bl  0x100006620              ; cache/DMA prep (w0=3, len=0x40)
str w1_lo → [MMIO+0xb14]     ; USB EP0 buffer address register
str ctl   → [MMIO+0xb10]     ; includes length 0x40 (0x20080040)
```
Alloc of the two heap bufs: **`0x10000c2d8`** (`0x40` + `8` via `100b8`).

### Best candidate (before handler)

**Best software write into fixed USB SRAM before `+0x60`:** **`0x19C010D08`** — 8-byte SETUP mirror, attacker controls all fields, store at `e32c` then `bl +0x60` at `e334`.

- Does **not** reach `C80` (`D08` is **`+0x88` above** `C80`; write is only 8 bytes upward).
- Does **not** reach `E18` (`D08 → E18 = +0x110` > 8).
- Payload DMA itself lands in **heap**, not in `C80`/`E18`.
- Fixed `0x19C0108C0`–`C80` abuts the table but is **software EP state**, not the EP0 DMA target programmed at `MMIO+0xb14`.

**No software path found** that writes attacker bytes into `C80` or `E18` callback fields before those handlers run.

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

**For EP0 SETUP/OUT, is `MMIO+0xb14` (`0x25D100000+0xb14`) always programmed with the heap buf at `*0x19C010880`, and is the fixed abutting region `0x19C0108C0`–`0x19C010C80` ever used as a USB DMA target (any `str` of that VA into `+0xb14` / related EP regs)?**
