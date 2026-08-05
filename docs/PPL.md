# PPL research — A12 / iPhone XR / 22H311

**Mode:** parallel written track. **No PPL bypass claimed.**  
Deep notes live under [`research/ppl/`](../research/ppl/).

| Fact | Status |
|------|--------|
| SoC model | A12 — **PPL**, not SPTM/TXM |
| Build | 18.7.5 (**22H311**) |
| Public iOS 18 PPL bypass | **None** (public catalogs) |
| Prerequisite | Demonstrated **KRW** (missing) |
| Evidence level | **literature** (+ offline kernel strings) / **not demonstrated** |

## What PPL enforces on A12 (high level)

Page Protection Layer isolates sensitive kernel page-table and related
operations so that ordinary EL1 kernel R/W is **not** enough to safely
mutate protected mappings / certain privileged state. On A12 this is the
relevant model through iOS 18; **do not** import A15+ SPTM/TXM playbooks as
the XR plan.

Observed in 22H311 kernelcache survey (operator strings): `__PPLTEXT`,
`__PPLTRAMP`, `__PPLDATA`, `__PPLDATA_CONST`. Details:
[../research/kexploit/22H311_NOTES.md](../research/kexploit/22H311_NOTES.md),
[../research/mitigations/README.md](../research/mitigations/README.md).

## Historical A12 public approaches (citations only)

| Era | Approach | Fix / end | On 22H311 |
|-----|----------|-----------|-----------|
| Dopamine 2.x | **dmaFail** (GFX/DMA → PPL memory write) | Fixed **iOS 16.6** ([DmaFail](https://theapplewiki.com/wiki/DmaFail)) | **Patched** |
| iOS 15.2+ | PPL becomes hard gate for app JB on A12+ | Still the model | Gate remains |
| Coruna / later kits | Public disclosure research (claim vs proof) | Not an XR 18.7.5 installer | Teacher only |
| Relaxin 0.4.2 `ppl-dma-a12` | Closed IPA; A12 DMA backend **after** early KRW | Confirm window **17.0–17.3.1**; early entry DarkSword (dead here) | Teacher only |

Full map: [../research/ppl/HISTORICAL_A12.md](../research/ppl/HISTORICAL_A12.md).  
Strategy: [../research/ppl/STRATEGY_22H311.md](../research/ppl/STRATEGY_22H311.md).

Public landscape: [PPL/SPTM Bypasses (Apple Wiki)](https://theapplewiki.com/wiki/PPL/SPTM_Bypasses) —
“No PPL/SPTM bypass is publicly available on iOS 18.”

## What must be true after KRW for a jailbreak (mapping only)

```text
KRW (arbitrary or sufficient)
  → PAC-aware use of pointers (arm64e)
  → PPL bypass / PPL-safe phys or PT mutation   [MISSING — no public iOS 18 method]
  → AMFI / trustcache / codesign policy changes
  → unsandbox / bootstrap (Dopamine-shaped architecture)
```

Architecture references (Dopamine / RootHide / Relaxin plug-in shape) are
**integration patterns**, not proof of a live primitive on 22H311.
See [../research/kexploit/viability/dopamine_bootstrap_arch.md](../research/kexploit/viability/dopamine_bootstrap_arch.md).

## Experiments **if** KRW exists (observational)

| # | Experiment | Pass / fail idea |
|---|------------|------------------|
| P-RO-1 | Read PPL-related globals / state pointers without writing | Stable read; matches offline layout notes |
| P-RO-2 | Compare structure shapes to public 16.x/17.x writeups | Diff documented; no assume-same |
| P-RO-3 | Confirm SPTM absence at runtime (expected on A12) | No SPTM surfaces; PPL still present |
| P-WR-x | Any write into PPL-protected memory | **Forbidden** until cited mechanism + restore plan |

Stubs for future instrumentation (no fake success): [`src/ppl/`](../src/ppl/).

## Exit criteria — “PPL blocked on 18.7.5 with known public techniques”

Mark **PPL: blocked** (and keep it) when all are true:

1. No citable public PPL bypass for **iOS 18** on **A12**.  
2. Historical A12 public method(s) (dmaFail-class) known-fixed before 18.7.5.  
3. No own-lab mechanism with a written test plan has succeeded.  
4. KRW either absent or insufficient to validate a PPL strategy end-to-end.

**Current: all four hold → PPL blocked for v0.**

## Explicit non-claims

- No PPL bypass on 22H311  
- BootROM pwn ≠ PPL defeat  
- No wiring of PPL code into `boot/`  

## Related

- [STATUS.md](STATUS.md)
- [KRW.md](KRW.md)
- [ATTRACT_DEVS.md](ATTRACT_DEVS.md)
- [../research/ppl/README.md](../research/ppl/README.md)
