# PPL strategy — A12 / 22H311 (honest)

**Device:** iPhone XR (`n841`) · **SoC:** A12 (`t8020`) · **iOS:** 18.7.5 · **Build:** 22H311  
**Mode:** research plan + blockers. **No PPL bypass claimed.**

## One-line verdict

**Blocked for v0.** A12 still has **PPL** (confirmed as strings/segments in the
22H311 kernelcache survey), and there is **no public PPL bypass for iOS 18**.
Even if a KRW primitive appeared tomorrow, PPL would remain a separate gate
with no citable A12/18.7.5 mechanism yet.

## What we know about PPL on this build

| Observation | Evidence | Confidence |
|-------------|----------|------------|
| PPL code/data still present | `__PPLTEXT`, `__PPLTRAMP`, `__PPLDATA`, `__PPLDATA_CONST` in `kernelcache.payload` strings | High (operator survey) |
| SPTM/TXM **not** observed | No SPTM/TXM hits in same probe | High for “not A12’s model” |
| PAC / arm64e still present | `pac_*_event` strings | High |
| Public catalog: no iOS 18 PPL/SPTM bypass | [PPL/SPTM Bypasses (Apple Wiki)](https://theapplewiki.com/wiki/PPL/SPTM_Bypasses) — “No PPL/SPTM bypass is publicly available on iOS 18” | High for *public* landscape |

Full mitigation table: [../mitigations/README.md](../mitigations/README.md).  
Kernel notes: [../kexploit/22H311_NOTES.md](../kexploit/22H311_NOTES.md).

## Strategy layers (order matters)

```text
0. Entry / KRW on running 22H311 kernel     [MISSING — see kexploit track]
1. Stable arbitrary kernel R/W             [blocked on 0]
2. PPL-aware phys/page-table mutation      [blocked on 1; no public iOS 18 PPL]
3. AMFI / trustcache / CS dance            [blocked on 2 for a SpringBoard JB]
4. Bootstrap (Dopamine-shaped)             [architecture only until 1–3]
```

BootROM (usbliter8) is **solved** and sits **outside** this stack. It does not
remove PPL on the installed OS. See [T002](../kexploit/experiments/T002_bootrom_ramdisk_ceiling.md).

## Candidate technique families (teachers only)

| Family | Historical A12 relevance | Live on 22H311? | Role for Lumina |
|--------|--------------------------|-----------------|-----------------|
| **dmaFail** (GFX/DMA → PPL mem write) | Yes — Dopamine 2.x A12 path; Kaspersky/Triangulation-class | **No** — fixed **iOS 16.6** | Historical mechanism study |
| **Coruna-era PPL kits** (public disclosure) | Multi-SoC claims in writeups; verify per source | **No** as XR 18.7.5 installer; public iOS 18 PPL = none | Claim-vs-proof notes |
| **Relaxin `ppl-dma-a12`** | Closed IPA; A12 DMA/dbgwrap physrw **after** early KRW | **No** — confirm window **17.0–17.3.1**; early entry DarkSword (dead on 18.7.5) | Stage vocabulary + A12-vs-A13+ backend shape |
| **SPTM/TXM paths** | Wrong SoC class for XR A12 | N/A | Contrast only — do not port |

Detail: [HISTORICAL_A12.md](HISTORICAL_A12.md),
[../kexploit/RELAXIN_042_A12_DMA.md](../kexploit/RELAXIN_042_A12_DMA.md).

## What “success” would look like (exit criteria — none met)

A credible PPL milestone on this build requires **all** of:

1. **Cited mechanism** — named bug / design flaw with public or own-lab writeup
2. **SoC match** — works on **A12 PPL**, not an SPTM-only story
3. **Build match** — not known-fixed before **18.7.5**
4. **KRW prerequisite** — demonstrated arbitrary (or sufficient) kernel R/W first
5. **Test plan** — RO probe → controlled mutation of a PPL-protected structure →
   observable effect, with panic/fail logged honestly

Until then, STATUS must say **PPL: blocked / research only**.

## Test plan without a bypass (what we *can* do now)

These are **documentation / RE** tests — not exploit claims.

| # | Test | Pass criteria | Lab? |
|---|------|---------------|------|
| P1 | Reconfirm PPL segments in 22H311 kernelcache | Strings/sections still list `__PPL*` | Mac offline |
| P2 | Confirm no SPTM/TXM cargo-cult in notes | STATUS/mitigations still say A12=PPL | Docs |
| P3 | Map historical dmaFail → Apple fix version | Cite 16.6; mark dead for 18.7.5 | Docs |
| P4 | Extract Relaxin/Dopamine **stage order** only | Written sequence: KRW → chip profile → PPL physrw → bootstrap | Docs |
| P5 | Refuse “PPL essay clears KRW gap” intakes | Filter reject per [FILTER.md](../kexploit/FILTER.md) | Hunt loop |

**Do not** run panic PoCs or closed IPA installers on the XR as a PPL “win.”

## Honest blockers

1. **No public iOS 18 PPL bypass** — catalogs agree; do not invent one.
2. **No KRW on 22H311** — PPL strategy cannot be validated end-to-end.
3. **Historical A12 PPL (dmaFail) patched years before this build.**
4. **Relaxin A12 DMA is post-entry and OS-gated to 17.0–17.3.1** — teacher, not path.
5. **Cloud VM cannot run live PPL experiments** — Mac + device only.

## Explicit non-claims

- We do **not** have a PPL bypass on 22H311
- We do **not** claim Relaxin / Coruna / Dopamine supply one for this build
- We do **not** treat BootROM pwn as PPL defeat
- We do **not** wire any PPL code into `boot/`

## See also

- [README.md](README.md)
- [HISTORICAL_A12.md](HISTORICAL_A12.md)
- [../kexploit/viability/](../kexploit/viability/)
- [../kexploit/KRW_MILESTONES.md](../kexploit/KRW_MILESTONES.md)
- [../../docs/STATUS.md](../../docs/STATUS.md)
