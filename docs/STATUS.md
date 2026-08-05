# Lumina — Project Status (OVERRIDE 2026-08-05)

## Sole focus

**DarkSword-class primitives → path toward a jailbreak** on our lab device(s).

Primary engineering target = **DS-K** (kernel PE / public kexploit ports).  
**DS-Full** (WebKit→…→kernel chain) = read-only research reference — not product UX.  
**Not a jailbreak yet.** No Sileo claim. No invented offsets. No success without command + observed result.

> **OVERRIDE:** Earlier “docs-only KRW / prioritize usbliter8” language is **superseded**.  
> This track does **not** send lab time to Pico/iBEC work inside this project.

## Lab identity

| Field | Value |
|-------|--------|
| Primary interest | iPhone XR · A12 (`t8020`) · `n841` |
| Daily driver | iOS **18.7.5 / 22H311** |
| Role of 18.7.5 | Primary phone — **not assumed PE-viable** |
| UDID | `00008020-00117540340B002E` |
| ECID | `00117540340B002E` |

## Working hypotheses (track with evidence)

| ID | Hypothesis | Evidence so far |
|----|------------|-----------------|
| **H1** | Public DS-K fails cleanly on 22H311 (panic / early return / wrong offsets / entitlement fail) | **literature** leans this way (PE fixed 18.7.2); **lab** = not run yet |
| **H2** | DS-K still partially works; literature overstated a full kill on our device | **unknown** — needs on-device attempt |
| **H3** | DS-K only works on **earlier 18.4–18.6.x / pre-18.7.2** → move JB effort to a vulnerable test handset/build | **unknown** — open if H1 confirmed on 22H311 |

STATUS will name which hypothesis lab results support. literature ≠ on-device proof; on-device KRW ≠ jailbreak.

## Literature landmarks (acknowledged, not a lab stop)

| Landmark | Scope | Label |
|----------|-------|-------|
| **18.7.2** | `CVE-2025-43510`, `CVE-2025-43520` (kernel PE) | **literature:** called fixed |
| **18.7.3** | JSC / ANGLE (**DS-Full** stages) | **literature:** called fixed |
| **18.7.7**+ | Broader DarkSword messaging | Does not replace on-device DS-K proof |
| opa334 README | Claims iOS **15.0–26.0.1**; “offsets hardcoded for 15.x(?)” | **Conflict** with 18.7.2 PE fix — resolve via lab |

Dossier: [DARKSWORD.md](DARKSWORD.md).

## Current program state

| Item | State |
|------|--------|
| Main line | **DS-K** exhaustion → KRW demo → PPL (on build where KRW works) → bootstrap design |
| KRW on 22H311 | **Open** — literature negative; **lab not yet attempted** |
| PPL | Literature map only until `SUCCESS_KRW` on any build ([PPL.md](PPL.md)) |
| Entry | **Open decision** E1–E4 — see [ENTRY.md](ENTRY.md) |
| Harness | **Lumina** app (`Lumina/`) + `src/krw` + real DS-K link when `third_party` cloned |
| Bundle ID | `com.kolbymaxx.lumina` |
| Fake backends | **Forbidden** — no pretend `kread`/`kwrite` success |

### Open questions (must answer with lab or operator choice)

1. **Entry method** for first DS-K host (E1 / E2 / E3 / E4)?  
2. Is PE alive or dead **on-device** for our XR @ 22H311?  
3. Do we need a **pre-18.7.2** disposable test build/device (H3 sandbed)?

### Single next human action

**On a Mac:** `./scripts/clone_darksword_kexploit.sh` → `cd Lumina && xcodegen generate` → sign/sideload **Lumina** (`com.kolbymaxx.lumina`) → **Run DS-K** → paste log + pick LAB result code.

Also reply with entry choice if not already decided:

| Code | Choice |
|------|--------|
| **E1** | Free sideload / personal team provisioning |
| **E2** | Paid Apple Developer signing |
| **E3** | Freeze 18.7.5 host work; prepare DS-K against a **pre-18.7.2** test build/device |
| **E4** | Other (specify) |

## Docs map

| Doc | Role |
|-----|------|
| [DARKSWORD.md](DARKSWORD.md) | DS-Full vs DS-K, CVE/patch table, public repos |
| [KRW.md](KRW.md) | Integration + lab result taxonomy |
| [ENTRY.md](ENTRY.md) | Ranked ways to run a host binary |
| [LAB_DSK.md](LAB_DSK.md) | On-device experiment protocol |
| [BUILD_22H311.md](BUILD_22H311.md) | Daily driver build identity |
| [BUILD_vulnerable_target.md](BUILD_vulnerable_target.md) | Pre-18.7.2 sandbed plan (H3) |
| [PPL.md](PPL.md) | Blocked until KRW_SUCCESS |
| [JB_SHAPE.md](JB_SHAPE.md) | Design-only Dopamine-shaped flow |
| [ATTRACT_DEVS.md](ATTRACT_DEVS.md) | Repro + ask |
| [../Lumina/README.md](../Lumina/README.md) | Sideloadable DS-K test host (XcodeGen) |
| [../scripts/export_ipa.md](../scripts/export_ipa.md) | Archive → IPA on Mac |
| [../third_party/README.md](../third_party/README.md) | How we vendor DS-K (local clone; no LICENSE) |

## Lab result log (append only)

| Date | Build | Entry | Result code | Notes | Hypothesis |
|------|-------|-------|-------------|-------|------------|
| — | 22H311 | — | *not run* | Awaiting E1–E4 | — |

Result codes: `SUCCESS_KRW` / `FAIL_PATCHED` / `FAIL_OFFSETS` / `FAIL_ENTRY` / `FAIL_PANIC` / `UNKNOWN`  
(see [LAB_DSK.md](LAB_DSK.md)).

## Historical note (out of scope for this track)

Phase A tethered ramdisk inventory (2026-08-01) remains factual under older commits / research notes.  
**It is not the priority of this override** and must not divert DS-K milestones.

## Attract (one line)

Looking for A12 PPL notes or DS-K / PE help applicable to **22H311** `n841` (or a pre-18.7.2 sandbed); we are exhausting public DarkSword kexploit ports with reproducible lab logs — literature patch landmarks acknowledged, on-device proof required.
