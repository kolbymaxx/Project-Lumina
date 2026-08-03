# t8027 SecureROM acquisition notes (research only)

**Date:** 2026-08-03  
**Phase:** after [OFFSET_DERIVATION.md](OFFSET_DERIVATION.md)  
**Target match:** live DFU `SRTG:[iBoot-4172.0.0.100.14]` on CPID `8027`  
**Status:** documentation only — **no image vendored here; no offsets; pwn not claimed**

Nothing here is wired into `boot/`. Do not commit SecureROM binaries to this repo.

---

## Scope / non-claims / non-goals

### Non-claims

- No claim that a SecureROM image has been obtained or verified in this tree.
- No claim that usbliter8 pwns A12X / t8027.
- No claim that every public collection hosts a verified `4172.0.0.100.14` dump — collections change; **you must verify the version string**.

### Non-goals

- Inventing stub offsets
- Hosting or committing ROM/IPSW blobs
- Deep links to full IPSW downloads
- `boot/` wiring, DarkSword, kexploit, bootstrap

### Goal

Document **what artifact to seek**, **where researchers commonly look**, and **how that image feeds the empty stubs** once verified.

---

## 1. Exact artifact needed

| Field | Value |
|-------|--------|
| SoC | T8027 (A12X / A12Z family) |
| CPID | `0x8027` / `8027` |
| Live DFU SRTG (this lab) | `iBoot-4172.0.0.100.14` |
| Public bootrom version label | `4172.0.0.100.14` (see [Apple Wiki — T8027](https://theapplewiki.com/wiki/T8027) Bootrom section) |
| Artifact class | **AP SecureROM** (immutable BootROM image), **not** SEPROM, **not** SEPOS, **not** iBSS/iBoot from an IPSW restore stack |

**Acceptance test (local, after download):** the binary (or a mapped load) must contain a version string consistent with `4172.0.0.100.14` / `iBoot-4172.0.0.100.14`, matching the device serial field. Record SHA-256 in a private lab note.

**Reject / confuse carefully:**

| Wrong class | Why |
|-------------|-----|
| **SEPROM** (`SEPROM_t8027…`) | Secure Enclave ROM — useless for usbliter8 AP ROP/handler offsets |
| **SEPOS** | Enclave OS firmware |
| **IPSW iBoot / iBSS / LLB** | Later boot stages; gadget VAs differ from SecureROM |
| t8020 SecureROM `3865.0.0.4.x` | Wrong chip / SRTG (XR baseline) |
| t8030 SecureROM `4479…` | A13 path (`WITH_PAC`) — different family |

---

## 2. Known public research locations / collections

Focus on **indexes and tools**, not IPSW mirrors. Availability and filenames change; treat every hit as unverified until the version string matches.

### Primary: [securerom.fun](https://securerom.fun/)

- Community **Apple SoC BootROM / SecureROM collection** (Darwin / iPod / RTKit filters + search UI).
- Common first stop for researchers assembling a local ROM corpus.
- **Workflow:** open site → search / filter for **t8027** / **A12X** / version **4172** → download candidate → run acceptance test above.
- Lumina does **not** mirror these files. Do not commit downloads.

### Mirrors / secondary indexes

| Location | Role | Caution |
|----------|------|---------|
| [zzVertigo/SecureROMs](https://github.com/zzVertigo/SecureROMs) | GitHub zip that **credits** securerom.fun as source | May be incomplete/outdated vs the live site; still verify 4172 string |
| Community dump indexes / leak catalogs | Sometimes list `SecureROM for t8020si, iBoot-3865…`, `t8030…`, and separately **SEPROM_t8027** | Easy to grab the **wrong** blob (SEPROM vs SecureROM; 3865 vs 4172). Prefer securerom.fun naming clarity |
| Private lab corpora | Many teams already keep hashed SecureROM sets offline | Fine if provenance + hash are recorded locally |

### RE tooling (not a ROM host)

| Tool | Role |
|------|------|
| [jonpalmisc/ibis](https://github.com/jonpalmisc/ibis) | Segment-accurate SecureROM/iBoot loader for Binary Ninja & IDA; README points at securerom.fun for dumps |
| IDA / Ghidra / Binary Ninja | Symbolization / xref work once the image loads |

### Identity references (no binaries)

| Doc | Role |
|-----|------|
| [Apple Wiki — T8027](https://theapplewiki.com/wiki/T8027) | Confirms bootrom version **4172.0.0.100.14** for T8027 devices |
| [docs/research/usbliter8-t8027-bringup.md](../../docs/research/usbliter8-t8027-bringup.md) | Live DFU capture locking SRTG on this iPad |
| Upstream usbliter8 README | A12X/Z “theoretically” supported, **not implemented** |

---

## 3. Workflow once the image is obtained

Still research-only. Aligns with [OFFSET_DERIVATION.md](OFFSET_DERIVATION.md).

```text
1. Verify version string == 4172.0.0.100.14 (accept/reject)
2. Hash (SHA-256) + store outside git (e.g. ~/Lab/securerom/, gitignored)
3. Load with ibis (or equivalent) at SecureROM base (typically 0x100000000 family mapping — tool-defined)
4. Symbolize ROM roles from t8020 teacher list (memcpy, USB handler, demote, ROP gadgets, tramp, …)
5. Fill a local worksheet: role | t8020 VA | t8027 VA | evidence
6. Only then edit research/usbliter8-t8027/stubs/... in a later PR
7. SRAM / USB MMIO still need separate maps — ROM image alone is not enough for ov_start / heap / DMA
```

### How this maps onto empty stubs

| After ROM symbolization | Stub / file |
|-------------------------|-------------|
| ROM funcs/gadgets | `stubs/t8020_t8006_shellcode/targets/t8027/offsets.h` (ROM half) |
| Handler ROM symbols | `stubs/usb_req_handler/targets/t8027/offsets.h` |
| ROP LR targets in overwrite | Informs later `t8027_config.snippet.c` / local `exploit.c` (not yet) |
| Still **not** filled from ROM alone | `ov_start`, heap `blocks.S`, USB MMIO, SN/CB/canary, descriptors blob |

Keep `#error` guards until evidence exists. Do not invent.

---

## 4. Other supporting files (useful, secondary)

Not substitutes for SecureROM. Useful later or for board context; **not** required to start ROM symbolization.

| Artifact | Use for t8027 track | Priority now |
|----------|---------------------|--------------|
| **DeviceTree** for this board (`j317ap` / `j318ap` class iPad Pro 3rd gen — confirm against live BDID `0A` / model) | Board peripherals, product identity; **not** SecureROM gadgets | Low for offset derivation; later if boot chain ever considered (out of scope here) |
| IPSW for a matching restore (metadata only / your own legal copy) | BuildManifest board ids, payload names | Optional identity cross-check — do not treat as SecureROM |
| Decrypted iBSS/iBoot (post-PWND world) | Host `usbliter8ctl boot` experiments | **After** PWND — not this phase |
| t8020 SecureROM `3865…` (teacher) | Side-by-side role diff while learning | Helpful; already implied by upstream constants |
| Pico UF2 / harness notes | Race hardware | Parallel track; useless without offsets |
| SEPROM / SEPOS | Enclave research | **Out of scope** — do not confuse with AP SecureROM |

---

## 5. Mac checklist (acquisition + verify)

```bash
# 1) Reconfirm device still matches target SRTG
cd ~/Projects/lumina
python3 ./usbliter8ctl info
# expect: CPID:8027 ... SRTG:[iBoot-4172.0.0.100.14]  (no PWND)

# 2) Browse public ROM collection (browser)
open https://securerom.fun/
# search for t8027 / 4172 / A12X — download candidate locally, outside the repo

# 3) Verify version string (example; adjust path)
strings -a ~/Lab/securerom/candidate.bin | rg -n '4172\.0\.0\.100\.14|iBoot-4172'
shasum -a 256 ~/Lab/securerom/candidate.bin >> ~/Lab/securerom/NOTES.txt

# 4) Load in RE tool (ibis / IDA / Ghidra / BN) — private DB, not committed
# 5) Follow OFFSET_DERIVATION.md worksheet before touching git stubs
```

If the collection has no matching 4172 image, **stop** — do not substitute 3865 or SEPROM. Re-check securerom.fun later or use another verified corpus with the same acceptance test.

---

## See also

- [OFFSET_DERIVATION.md](OFFSET_DERIVATION.md) — RE order + constant groups
- [docs/research/usbliter8-t8027-bringup.md](../../docs/research/usbliter8-t8027-bringup.md) — live identity
- [stubs/](stubs/) — TODO / `#error` placeholders
- [upstream/README.md](../../upstream/README.md) — local usbliter8 clone (teachers)
