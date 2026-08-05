# DarkSword-class track — main line (Lumina)

**This is the project’s primary KRW path.**  
Literature landmarks are acknowledged; they are **not** an on-device stop.

Evidence labels (always use one):

| Label | Meaning |
|-------|---------|
| **literature** | Apple / NVD / GTIG / public writeups |
| **lab** | Observed on our device with a logged command + result |
| **unknown** | Not yet decided by literature or lab |

## Critical technical split (always label)

| Tag | What it is | Lumina product path? |
|-----|------------|----------------------|
| **DS-PE** | DarkSword-**class kernel PE / kexploit-only** — `CVE-2025-43510` + `CVE-2025-43520` family via public C/ports (e.g. opa334 `darksword-kexploit`, ClearSword-class) | **Yes — main line** until exhausted |
| **DS-FULL** | WebKit → sandbox → PE **full chain** (watering-hole / Safari kit) | **No** as product; citations OK for context |

Never mix them. A **DS-FULL** literature patch does not by itself close a careful **DS-PE** lab series (and vice versa) — but Apple’s **18.7.2** advisory covers the PE CVEs specifically (**literature**).

## Literature landmarks (acknowledged)

| Landmark | Scope | Literature status |
|----------|-------|-------------------|
| **18.7.2** | `CVE-2025-43510`, `CVE-2025-43520` | PE CVEs called **fixed** |
| **18.7.3** | JSC / ANGLE stages | **DS-FULL** pieces called fixed |
| **18.7.7**+ | Broader messaging | Does not replace on-device PE proof |

**literature ≠ lab.** We still **exhaust** public DS-PE options (ports, version gates, offset readiness, alternate builds if available) and record precise on-device outcomes before quitting this track.

## Lab identity

| Field | Value |
|-------|-------|
| Device | iPhone XR · A12 (`t8020`) · `n841` |
| Daily driver | iOS **18.7.5 / 22H311** |
| Goal order | **DS-PE KRW demo** → PPL research on the build where KRW works → bootstrap sketch |

## Exhaustion ladder (small milestones)

| Step | Goal | Success / fail signal |
|------|------|------------------------|
| **E0** | Inventory public DS-PE trees + LICENSE | Clone notes + commit hashes in ATTRIBUTION |
| **E1** | Version gates / claimed support vs 22H311 | Written table: code `#if` / README vs Apple 18.7.2 |
| **E2** | Offset readiness for n841 / 22H311 | Fields in `offsets_n841_22H311.h` filled from real analysis **or** explicit gaps |
| **E3** | Entry host for **DS-PE** | Developer-signed (or other legal) host that can run the PE trigger |
| **E4** | On-device **DS-PE** attempt @ 22H311 | Log: init OK / structured fail / panic — **no claim without paste** |
| **E5** | If E4 fails: alternate build / port variant | Precise failure taxonomy; optional pre-18.7.2 positive-control device |
| **E6** | Quit criterion | All public DS-PE options exhausted with **lab** negatives **or** KRW **demonstrated** |

Detailed protocol: [../research/kexploit/DARKSWORD_EXHAUST.md](../research/kexploit/DARKSWORD_EXHAUST.md).

## Honesty rules

1. Never invent offsets.  
2. Never claim KRW without a re-runnable command + observed bytes.  
3. Stub `src/krw` stays `KRW_ERR_NO_BACKEND` until a real backend is wired after lab evidence.  
4. **DS-FULL** weaponization pages are out of scope.  
5. usbliter8 / Pico / iBEC are **out of scope for this track** (historical Phase A may remain documented elsewhere).

## Related

- [STATUS.md](STATUS.md)
- [KRW.md](KRW.md)
- [ENTRY.md](ENTRY.md)
- [PPL.md](PPL.md) — after KRW works somewhere
- [../research/kexploit/viability/darksword_kexploit.md](../research/kexploit/viability/darksword_kexploit.md)
