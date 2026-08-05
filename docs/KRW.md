# KRW research — A12 / 22H311

**Goal:** documented, reproducible kernel R/W on **iPhone XR / 18.7.5 (22H311)**  
if a public (or own-lab) primitive still applies.  
**Status: blocked** — DarkSword PE **PATCHED** (18.7.2); pending a new public
primitive **verified on 22H311**. Lab mode **B** (docs/offline; no test host).
**No fake kread/kwrite backends.**

Evidence levels used here: **none** / **literature** / **partial** / **demonstrated**.

## Verdict (2026-08-05)

| Question | Answer | Level |
|----------|--------|-------|
| Public DarkSword **kernel** PE on 22H311? | **PATCHED** (fixed iOS **18.7.2**) | literature |
| Public DarkSword **full chain** on 22H311? | **PATCHED** (kernel 18.7.2; WebKit/ANGLE stages 18.7.3) | literature |
| Public kfd / Dopamine-era KRW? | **Patched** long before 18.7.5 | literature |
| Any KRW demonstrated on this XR? | **No** | none |
| KRW track status | **Blocked** pending new PE verified on 22H311 | — |
| Harness in tree? | Thin API stubs — backend **none**; will not fake success | partial (code only) |
| Human-time priority | **usbliter8 post-pwn iBEC jump** (not app signing) | operator decision C |

**Pivot:** DarkSword is a **teacher / dead candidate**. KRW stays parked
docs/offline. Advisory watches remain literature-only until something is
verified on this build. See matrix.

## Viability notes (public primitives)

| Primitive | On 22H311 | Entry required | arm64e / PAC | What we can test without hand-waving |
|-----------|-----------|----------------|--------------|--------------------------------------|
| DarkSword kernel (`CVE-2025-43510`, `CVE-2025-43520`) | **Patched** (18.7.2) | Malicious app / chain stage (GTIG); not WebKit-alone for PE | A12 is arm64e; PE claimed phys/virt R/W after race — **irrelevant if bug fixed** | Re-read Apple/NVD/GTIG; **do not** run kit blobs as “proof” against a known fix |
| DarkSword full chain (WebKit → sbx → PE) | **Patched** (18.7.2 + 18.7.3 landmarks) | Safari / watering-hole | PAC bypass stage tracked separately (e.g. dyld PAC CVE) | **Out of product scope** — we will not package WebKit weaponization |
| opa334 `darksword-kexploit` / ClearSword-class ports | **Unknown as residual bug**; README version claims ≠ Apple fix | Typically app / already-privileged context | Needs 22H311 offsets; PAC-aware | Only after a **citable** “still unpatched on 18.7.5” claim — default = dead |
| kfd / PhysPuppet family | **Patched** (≤17.0 public methods) | App | Historical Dopamine path | Docs only ([T001](../research/kexploit/experiments/T001_kfd_dead_on_1875.md)) |
| Advisory watches (e.g. CVE-2026-28972 fixed **18.7.9**) | **Unknown** — may still be live on 18.7.5 | **Unknown** until writeup (app vs privileged) | Assume arm64e constraints | Identity confirm + literature chase; no panic PoC until writeup + RO plan |
| BootROM / ramdisk (usbliter8) | **Works** (separate track) | Pico + Mac | N/A for live SpringBoard KRW | Already demonstrated — **does not** equal kernel R/W on running 18.7.5 |

Detail cards: [viability/](../research/kexploit/viability/), [T004](../research/kexploit/experiments/T004_darksword_kernel_dead_on_1875.md),
[PUBLIC_PRIMITIVE_MATRIX.md](../research/kexploit/PUBLIC_PRIMITIVE_MATRIX.md).

### Patch landmarks (DarkSword-related)

| Landmark | What Apple / GTIG say | Implication for 22H311 (18.7.5) |
|----------|----------------------|----------------------------------|
| **18.7.2** | `CVE-2025-43510`, `CVE-2025-43520` fixed | Kernel PE stages **dead** |
| **18.7.3** | `CVE-2025-43529` (JSC), `CVE-2025-14174` (ANGLE) fixed | Full-chain WebKit/sbx stages **dead** |
| **18.7.7** / later messaging | Broader DarkSword protection rollout / other kernel CVEs | Confirms chain was already broken earlier; do not treat 18.7.7 as the first PE fix |
| **18.7.9** | Separate advisory set (OOB write / auth / leaks) — **not** DarkSword PE | Possible **other** KRW candidates — still unproven |

Conflict note: some public reimplementations claim broad iOS version support.  
**Apple + NVD + GTIG override README marketing.** Until a lab shows PE on **22H311**, STATUS stays **patched / no KRW**.

## Entry reality (M1) — can a kexploit even run?

**On stock iOS 18.7.5 XR, TrollStore is unavailable** (CoreTrust install window ends at 17.0; 17.0.1+ unsupported).  
See [ENTRY.md](ENTRY.md).

| Path | Viable on this build? | Notes |
|------|----------------------|-------|
| TrollStore (arbitrary entitlements) | **No** | Blocked |
| Free / paid Apple Developer sideload | **Partial** | 7-day / paid signing; **entitlement set limited** vs TrollStore |
| Already-jailbroken helper | **No** | Circular — we do not have a JB |
| WebKit full chain as product | **Refused** | Not our path; also patched for DarkSword stages |
| Ramdisk root (usbliter8) | **Yes** | Different environment — not SpringBoard KRW |

Public “kexploit IPA” style work often assumes TrollStore-class entitlements.  
**That entry is blocked on stock 18.7.5.** Developer-signed sandboxed apps may still reach some IOKit/VFS surfaces — **unknown per CVE**.

## Harness design (M2)

Minimal C API (stubs only):

```c
int      krw_init(void);
int      kread(uint64_t kaddr, void *out, size_t len);
int      kwrite(uint64_t kaddr, const void *in, size_t len);
uint64_t kbase(void);   /* or slide helper */
void     krw_deinit(void);
```

| File | Role |
|------|------|
| [`src/krw/krw.h`](../src/krw/krw.h) | Public API |
| [`src/krw/krw.c`](../src/krw/krw.c) | Stub backend (`KRW_BACKEND_NONE`) |
| [`src/krw/offsets_n841_22H311.h`](../src/krw/offsets_n841_22H311.h) | Offset skeleton — all `TODO verify` |
| [`src/krw/README.md`](../src/krw/README.md) | Integration + LICENSE rules |
| [`src/krw/test_plan.md`](../src/krw/test_plan.md) | Read-known-stable first; no random writes |

### Integration plan (when a *live* public kexploit exists)

1. Vendor or submodule under `research/kexploit/<name>/` (gitignored if upstream clone) with **LICENSE + attribution**.
2. Thin adapter in `src/krw/` implementing `krw_init` → upstream init; never paste exploit into `boot/`.
3. Fill `offsets_n841_22H311.h` from kernelcache derivation or public **22H311** tables only.
4. Lab: `kread` of a known stable value → log → only then consider controlled write tests.

### Offset policy

1. Public table for **n841 / 22H311** with citation, or  
2. Derived from our hashed kernelcache with notes, or  
3. `/* TODO verify */` + symbol name.  
**Invented immediates are a hard fail in review.**

### Test plan (refuse write-first)

1. `krw_init` success / structured failure (no crash-as-success).
2. `kbase` / slide matches offline expectation (± documented tolerance).
3. `kread` of a **known stable** kernel value (version string / constant structure field agreed in notes).
4. Only after (3): minimal controlled `kwrite` with restore — never “spray random”.

## Kernelcache / offsets workflow (M3)

See [BUILD_22H311.md](BUILD_22H311.md) and [../scripts/fetch_kernelcache.md](../scripts/fetch_kernelcache.md).

## What success looks like (KRW milestone)

A STATUS upgrade to **demonstrated** requires a command the human can re-run, with expected output, on this XR @ 22H311 — e.g. successful `kread` of a cited kernel field.  
Literature + stubs ≠ success.

## Related

- [STATUS.md](STATUS.md) — living truth  
- [ENTRY.md](ENTRY.md) — signing / entry  
- [PPL.md](PPL.md) — after KRW  
- [ATTRACT_DEVS.md](ATTRACT_DEVS.md)  
- [../research/kexploit/](../research/kexploit/) — hunt loop / matrix  
