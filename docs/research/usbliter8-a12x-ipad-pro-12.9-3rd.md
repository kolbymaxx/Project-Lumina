# Memo: usbliter8 A12X support — iPad Pro 12.9" (3rd gen)

**Status:** research only (2026-08-02)  
**Scope:** future A12X bring-up notes for Lumina. **Do not** wire into XR `boot/`, `fix_exec`, or live device paths.  
**Target device:** iPad Pro 12.9-inch (3rd generation), Apple **A12X** (`T8027`).  
**Baseline already working:** iPhone XR (`n841ap`, **A12** / `T8020`) SecureROM pwn via usbliter8 + Pico → CUSTOM_BOOT iBSS → ramdisk SSH.

---

## Verdict (executive)

| Question | Answer |
|----------|--------|
| Same DWC2 / DART-bypass race class as A12? | **Yes (claimed by authors)** — A12X/Z listed as *theoretically* supportable |
| Implemented in published usbliter8? | **No** — authors + Elcomsoft both say A12X/Z **not implemented** |
| Closest existing target tree? | **`t8020`** (non-PAC A12 path), **not** `t8030` (PAC) and **not** `t8006` (different SRAM map) |
| “Same Pico + usbliter8 host, new board files only”? | **PARTIAL — NO as stated** |

**PARTIAL explanation:** Pico + USB race hardware can be reused; host `usbliter8ctl` is largely CPID-agnostic once `PWND:[usbliter8]` appears. A12X still needs a **new SecureROM target** (`t8027`: offsets, ROP overwrite, descriptors, shellcode, handler, CPID dispatch). That is **not** a Pico `boards/*.cmake` stub and **not** a drop-in copy of `t8020` offsets. Post-pwn still needs **board-specific iBSS/iBEC/DeviceTree/ramdisk** (XR payloads will not boot).

---

## 1. A12X vs A12 — identifiers & exploit-relevant diffs

### 1.1 Product / board IDs (iPad Pro 12.9" 3rd gen)

| ProductType | BoardConfig | BDID | Connectivity / storage note | CPID | Platform |
|-------------|-------------|------|-----------------------------|------|----------|
| `iPad8,5` | `J320AP` | `0x08` | Wi-Fi, &lt; 1 TB | `0x8027` | `t8027` |
| `iPad8,6` | `J320xAP` | `0x18` | Wi-Fi, 1 TB | `0x8027` | `t8027` |
| `iPad8,7` | `J321AP` | `0x0A` | Cellular, &lt; 1 TB | `0x8027` | `t8027` |
| `iPad8,8` | `J321xAP` | `0x1A` | Cellular, 1 TB | `0x8027` | `t8027` |

Compare to live XR baseline:

| Field | XR (A12) | iPad Pro 12.9 3rd (A12X) |
|-------|----------|---------------------------|
| SoC | A12 Bionic | A12X Bionic |
| Platform | `t8020` | `t8027` |
| CPID | `0x8020` | `0x8027` |
| Board | `n841ap` | `J320*` / `J321*` (variant-dependent BDID) |
| USB connector | Lightning | **USB-C** |
| SecureROM SRTG (public) | `iBoot-3865.0.0.4.7` (usbliter8 README example) | **`4172.0.0.100.14`** (Apple Wiki / T8027 Bootrom row — confirm on-device serial) |

**Implication:** CPID `8027` is a distinct firmware identity. Upstream `exploit_run()` currently switches only `0x8020` / `0x8006` / `0x8030` and logs `Txxxx is not supported (yet?)` for everything else — including `0x8027`.

### 1.2 Closest shellcode / handler trees

Published usbliter8 layout (snapshot clone under `upstream/usbliter8/`, gitignored):

| Tree | SoCs | Race / CE style | Why / why not for A12X |
|------|------|-----------------|------------------------|
| `t8020_t8006_shellcode/targets/t8020` + `usb_req_handler/targets/t8020` | A12 phones | Stack LR ROP → EL1 → plant handler (no PAC in SecureROM) | **Closest template** — same non-PAC class authors group with A12X |
| `t8020_t8006_shellcode/targets/t8006` | S4/S5 | Same *style*, different SRAM (`0x1801…` vs A12 `0x19C0…`) and USB MMIO | Wrong memory map; do not cargo-cult addresses |
| `t8030_shellcode` + `usb_req_handler/targets/t8030` | A13 | PAC path; heap/DART/IRQ stages | Wrong CE class for A12X expectation |

**Do not confuse** Pico MCU configs in `usbliter8/boards/*.cmake` (GPIO12/13, LED) with Apple SoC “board files.” A12X work is a **new `t8027` target**, not a new Waveshare cmake.

### 1.3 SecureROM / DFU behavior — same race class?

| Claim | Source | Confidence |
|-------|--------|------------|
| Bug is Synopsys DWC2 Setup-ring underflow; A12/A13 SecureROM leave USB DART in bypass | Paradigm Shift write-up / usbliter8 README | High for A12/A13 |
| A12X/Z “can theoretically be supported … not implemented yet” | usbliter8 README + paper TLDR | High that authors believe same class |
| A12X excluded from shipped PoC | README, Elcomsoft (2026-07-15) | High |
| Exact T8027 SRAM layout, DOEPDMA base, stack LR slot, trampoline VA match T8020 | — | **Unknown — must RE from SecureROM dump / live DFU serial + dump tooling** |

**Working assumption for later agents:** treat A12X as **same race class as A12** (malformed short packets → DOEPDMA underflow → SRAM overwrite → non-PAC ROP), with a **separate offset / ROP table**. Do **not** assume `t8020` addresses (`0x19C028B18`, `0x239100B14`, tramp `0x19C018000`, handler CB `0x19C010C68`, etc.) transfer.

Reference T8020 handler symbols already documented for XR in [`research/CUSTOM_BOOT_NEXT.md`](../../research/CUSTOM_BOOT_NEXT.md) — useful as a *checklist of symbols to re-find* on T8027, not as copy-paste values.

---

## 2. Host tool — what must change for A12X

### 2.1 Pico firmware (primary gap)

In `exploit.c` (upstream):

- Identify: parse USB serial `CPID:….`
- Dispatch: `0x8020`/`0x8006` → `t8020_t8006_exploit_run`; `0x8030` → `t8030_exploit_run`; **else fail**
- Per-target artifacts under `resources/`:
  - `shellcode_t8020.h` / `handler_t8020.h` / `descriptors_t8020.h` (and t8006 / t8030 analogues)
- Per-target `offsets.h` in shellcode + `usb_req_handler` trees
- Hardcoded ROP overwrite frames inside `t8020_create_overwrite()` / `t8006_create_overwrite()`

**For A12X, expect to add (names illustrative):**

1. `CPID 0x8027` case → new `t8027_*` config (or shared runner with new config struct)
2. `t8020_t8006_shellcode/targets/t8027/{offsets.h,blocks.S,cleanup.S}` (or sibling dir)
3. `usb_req_handler/targets/t8027/offsets.h` (`HANDLE_USB_REQ`, `PLATFORM_DEMOTE`, `PLATFORM_SET_REMOTE_BOOT`, stack LR, `JUMP_AWAY`)
4. Regenerated `resources/{shellcode,handler,descriptors}_t8027.h`
5. Timing knobs (`crazy_delay`, post-plant sleeps) retuned on RP2350 — race is timing-sensitive

**Pico `boards/*.cmake`:** reuse existing Pico 2 / Waveshare UF2. No Apple-SoC dependency there.

**Cable note:** XR path is Lightning ↔ Pico. iPad Pro 3rd gen is **USB-C**. Waveshare RP2350 USB-A host port can take a short USB-C→USB-A cable; GPIO solder path must use USB-C pinout (README’s “do not use USB-C cables” warning is about **Lightning cable pinout confusion**, not “USB-C devices unsupported”). Validate D+/D− orientation and keep cable short.

### 2.2 Host `usbliter8ctl` (Lumina root + upstream)

Lumina `./usbliter8ctl` talks to **already-pwned** DFU (`05ac:1227`) / Recovery (`05ac:1281`):

- Looks for `PWND:[usbliter8]` in serial
- Issues `CUSTOM_DEMOTE` / `CUSTOM_BOOT` + DFU DNLOAD
- **Does not** embed CPID-specific SecureROM offsets

| Host concern | A12X change? |
|--------------|--------------|
| USB PIDs `0x1227` / `0x1281` | Likely unchanged (Apple DFU/Recovery constants) |
| Product / iProduct strings | No hardcoding today; serial carries `CPID`/`BDID`/`SRTG` |
| Board-id gating in ctl | None today — **optional** future check that `CPID:8027` + expected BDID match chosen payloads |
| Boot image path | Point at **J320/J321** raw iBSS, not XR `payload/iBSS.raw` |
| Lumina `boot/lumina-boot.sh` / `config.env` | **Out of scope for this memo** — do not merge A12X into XR wrappers |

Elcomsoft’s A12 sigpatch / ipwndfu fork is also **A12-only** so far; their post notes A12X still missing r/w + img4 sigpatches.

---

## 3. iBSS / iBEC path — IPSW naming & patchfinders

### 3.1 IPSW / restore naming (typical)

Restore package identity (examples; version changes over time):

- Device: `iPad8,5` … `iPad8,8`
- Platform: `t8027`
- Latest seen via ipsw.me API at memo time (Wi-Fi `iPad8,5`): **iPadOS 26.6 (23G71)** — always re-query before work

Inside a Restore IPSW, expect board-suffixed boot objects (names vary slightly by tooling):

| Component | Typical pattern |
|-----------|-----------------|
| iBSS | `Firmware/dfu/iBSS.j320ap.RELEASE.im4p` (or `j320xap` / `j321ap` / `j321xap`) |
| iBEC | `Firmware/dfu/iBEC.<board>.RELEASE.im4p` |
| DeviceTree | `Firmware/all_flash/DeviceTree.<board>.im4p` |
| kernelcache | `kernelcache.release.ipad8` (confirm exact name in IPSW) |
| Restore ramdisk | `*.dmg` under Restore / under `asset/` depending on iPadOS gen |

**Extraction:** `ipsw extract` / `img4` / `pyimg4` → decrypt if needed → raw payload for `usbliter8ctl boot`. XR known-good path boots **raw** iBSS after pwn (see CUSTOM_BOOT notes), not stock img4 via iTunes.

### 3.2 Leeksov-style `--mode ibss|ibec`

[Leeksov/usbliter8-iboot-patchfinder](https://github.com/Leeksov/usbliter8-iboot-patchfinder) is **pattern-based** (ADRP + string xrefs), default VA base `0x870000000`, modes `ibss|ibec|llb`.

| Claim | Relevance to A12X |
|-------|-------------------|
| Tested matrix includes **iPad Pro 2018/2020 (A12X/Z)** iBoot images (8 patches vs 14 on iPhones) | **Offline patchfinder likely transfers** to J320/J321 iBSS/iBEC **if** you pass correct `--mode` and verify `--base` against the image |
| [usbliter8ra1n](https://github.com/Leeksov/usbliter8ra1n) lists “iPad Pro 2018 A12X ✅ **(offsets TBD)**” under *exploit* support | **BootROM offsets still TBD** — iBoot patch ≠ SecureROM pwn |
| SPTM/TXM patchfinders | A12/A12X do **not** use SPTM/TXM the way A15+ does; ignore for A12X boot-chain parity with XR |

**Transfer rule for later agents:**

1. Extract board-matching iBSS/iBEC from the **same IPSW build** you intend to boot.
2. Run `--mode ibss` / `--mode ibec` separately; do **not** assume phone bases without checking the image header / IDA loader.
3. Treat Leeksov success on A12X *images* as evidence the **iBoot patch strategy** ports; treat SecureROM bring-up as a **separate** RE task.
4. Lumina’s XR path historically preferred a known-good hsbugss raw iBSS over locally patched blobs when sizes diverged — same discipline on A12X.

---

## 4. ICH / ramdisk notes

| Project | What it is | A12X? |
|---------|------------|-------|
| [hsbugss/usbliter8-xr-ramdisk](https://github.com/hsbugss/usbliter8-xr-ramdisk) | XR (`n841ap`) tethered chain: raw iBSS → irecovery img4 (FW, **DeviceTree**, ramdisk, trustcache, kernel) → SSH | **No** — DeviceTree / board / ECID / apticket are XR-specific |
| [Pa7r0n/ICH_A12_plus_Ramdisk](https://github.com/Pa7r0n/ICH_A12_plus_Ramdisk) (ICH A12+) | SSH ramdisk after usbliter8; `mount_ich`; iBoot finalize wrappers for **`n841ap` / `d321ap`** | **Phone A12/A13 oriented** — not a published J320/J321 pack |
| Leeksov `ramdisk_ssh.dmg` | Generic restore-style SSH ramdisk + dropbear | May be a **starting userspace**, still needs board DeviceTree + kernel + trustcache matching the iPad |

**Practical note (not a claim of a working A12X ramdisk):**

- Same *architecture* as XR: pwn → iBSS/iBEC → send DeviceTree + ramdisk + kernel → `bootx` → `iproxy` SSH.
- **Not** “same ramdisk as A12 with only DeviceTree swapped” until proven: kernelcache, trustcache, SEP/restore SEP, and iBoot board checks must match `J320*` / `J321*`.
- Closest honest phrasing: **same stage names as A12; rebuild payloads from an iPad8,\* IPSW; DeviceTree is necessary but not sufficient.**

Lumina Phase A Data-mount caveats (15.1 `mount_apfs` vs modern Data) are XR-specific observations — re-inventory on any A12X ramdisk rather than copying STATUS claims.

---

## 5. GO / NO-GO / PARTIAL matrix

| Proposal | Rating | Why |
|----------|--------|-----|
| Reuse same Pico 2 / Waveshare RP2350 UF2 **without** new SoC target | **NO-GO** | Firmware rejects `CPID:8027` |
| Same Pico hardware + **new `t8027` SecureROM target** (offsets/ROP/shellcode/handler) | **PARTIAL → GO after RE** | Authors claim theoretical support; work is real but scoped |
| Same host `usbliter8ctl` demote/boot protocol after PWND | **GO** (protocol) | No CPID tables in ctl; still need correct raw image |
| “New board files only” meaning only Pico `boards/*.cmake` | **NO-GO** | Wrong layer |
| “New board files only” meaning only copied `t8020` headers renamed to `t8027` | **NO-GO** | Different SecureROM (`4172…` vs `3865…`); addresses almost certainly differ |
| Drop XR ramdisk + swap DeviceTree | **NO-GO** | Board/kernel/SEP mismatch |
| Leeksov iboot `--mode ibss/ibec` on A12X IPSW images | **PARTIAL / likely GO** for *patchfinding*; still blocked on BootROM pwn |
| Full “iPad boots like XR tomorrow” | **NO-GO** today | Missing public T8027 exploit implementation |

### Recommended later work order (docs only — not this PR)

1. Capture live DFU serial on the iPad (`CPID`/`BDID`/`SRTG`/`ECID`) — Mac only, no Lumina bootstrap edits.
2. Dump / obtain T8027 SecureROM; map symbols parallel to T8020 `offsets.h` list.
3. Port A12-style overwrite + shellcode; add `0x8027` dispatch; retune race delays on RP2350.
4. Confirm CUSTOM_BOOT / demote handler addresses; boot raw board-matched iBSS.
5. Build iPad8,\* restore ramdisk chain (DeviceTree + kernel + trustcache); only then compare to ICH/hsbugss flows.

---

## Sources

| Source | Used for |
|--------|----------|
| Local upstream snapshot `upstream/usbliter8/` (clone of `ahmadkamal09999-tech/usbliter8`, mirrors Paradigm Shift tree; official `prdgmshift/usbliter8` 404 as of 2026-08-01) | README A12X caveat; CPID switch; t8020/t8006/t8030 layout; offset tables |
| Paradigm Shift write-up (“Introducing usbliter8” / ps.tc blog) | Race class; A12X/Z theoretical support |
| [Elcomsoft — A12 usbliter8 BootROM sigpatches](https://blog.elcomsoft.com/2026/07/a12-usbliter8-bootrom-sigpatches/) (2026-07-15) | Confirms A12X/Z still missing public r/w + sigpatches |
| [The Apple Wiki — iPad Pro 12.9" (3rd gen)](https://theapplewiki.com/wiki/IPad_Pro_(12.9-inch)_(3rd_generation)) | ProductType / BoardConfig / BDID table |
| [The Apple Wiki — T8027](https://theapplewiki.com/wiki/T8027) (via search snippets; raw fetch blocked by CF) | SoC identity; Bootrom `4172.0.0.100.14`; usbliter8 listed under vulnerabilities |
| [ipsw.me / ipsw.me API](https://ipsw.me/iPad8,5/info) | CPID `0x8027`, BDID, platform `t8027`, latest build sample |
| [Leeksov/usbliter8ra1n](https://github.com/Leeksov/usbliter8ra1n) + [usbliter8-iboot-patchfinder](https://github.com/Leeksov/usbliter8-iboot-patchfinder) | iBoot `--mode ibss/ibec`; A12X image tests; exploit “offsets TBD” |
| [hsbugss/usbliter8-xr-ramdisk](https://github.com/hsbugss/usbliter8-xr-ramdisk) | XR-only ramdisk stage model |
| [Pa7r0n/ICH_A12_plus_Ramdisk](https://github.com/Pa7r0n/ICH_A12_plus_Ramdisk) | ICH A12+ phone wrappers (`n841ap`/`d321ap`) |
| Lumina [`research/CUSTOM_BOOT_NEXT.md`](../../research/CUSTOM_BOOT_NEXT.md), [`docs/STATUS.md`](../STATUS.md) | Working XR CUSTOM_BOOT / Phase A context (do not regress) |

---

## Unknowns (explicit)

1. **Confirmed on-device `SRTG` / CPRV** for each J320/J321 SKU (Wiki Bootrom version vs live serial).
2. **Full T8027 SecureROM offset table** (stack LR, USB MMIO DOEPDMA, trampoline, heap repair blocks, descriptor restore blob, handler callback).
3. Whether T8027 USB MMIO base matches T8020 (`0x239100B14` in A12 overwrite) or differs.
4. Whether A12X SecureROM uses any PAC / extra checks that force an A13-like path (authors imply no; **unverified** on device).
5. Public availability of a tested **T8027 usbliter8 UF2** (none in Paradigm Shift PoC; Elcomsoft TBD).
6. Exact iBSS/iBEC load VA for modern iPadOS on `t8027` (Leeksov default `0x870000000` must be verified per image).
7. Whether any public ICH / SSHRD pack already ships `J320*` DeviceTree + kernel sets.
8. USB-C host path reliability on Waveshare RP2350 USB-A with this iPad (timing/cable length).
9. SEP / restore-SEP pairing requirements for any future Data-volume work on A12X (out of BootROM scope).

---

## Out of scope (enforced for this memo)

- No changes to `boot/lumina-boot.sh`, `boot/lib-udid.sh`, `fix_exec`, or XR `config.env`
- No phone/iPad commands run in cloud
- No merge of research trees into live boot
- No new exploit board stub unless a later task explicitly asks for a **flag-gated** `t8027` skeleton

---

## One-line handoff

**A12X iPad Pro 12.9 3rd gen is CPID `0x8027` / platform `t8027` / boards `J320*`·`J321*`; same usbliter8 race *class* as XR A12 but **unimplemented** — closest code is `t8020`, not a Pico board cmake; host ctl mostly fine after PWND; iBoot patchfinders may transfer with new bases; ramdisk needs a full iPad8,\* rebuild. Verdict: PARTIAL (new SecureROM target + payloads), not “board files only.”**
