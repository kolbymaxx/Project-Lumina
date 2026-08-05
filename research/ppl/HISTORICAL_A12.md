# Historical A12 PPL approaches → 18.7.x changes

Map of **public** A12-relevant PPL techniques and what broke them by the time
of **iOS 18.7.5 (22H311)**. Study only. No bypass claim.

## Timeline (high level)

| Era | A12 PPL situation (public) | Implication for XR 22H311 |
|-----|----------------------------|---------------------------|
| iOS 15.0–15.1 | App JB often without separate modern PPL gate (pre–15.2 hardening era) | Historical only |
| iOS **15.2+** | PPL bypass becomes a hard requirement for app-based A12+ JBs | Still the model on 18.x A12 |
| iOS 15.x–16.5.x | **dmaFail**-class GFX/DMA → PPL memory write used in Dopamine 2.x | Dead — see below |
| iOS **16.6** | dmaFail properly fixed | A12 dmaFail path closed |
| iOS 17.0–17.3.1 | Research / closed kits (Coruna, Relaxin-class) discuss later PPL paths; public confirm windows in this band for some tools | Outside our OS; still teachers |
| iOS **18.x** | Public catalogs: **no** PPL/SPTM bypass available | **Our build sits here — blocked** |

Sources: [PPL/SPTM Bypasses](https://theapplewiki.com/wiki/PPL/SPTM_Bypasses),
[dmaFail](https://theapplewiki.com/wiki/DmaFail),
[Dopamine](https://theapplewiki.com/wiki/Dopamine),
project notes under `research/kexploit/`.

## dmaFail (primary historical A12 public PPL)

| Field | Note |
|-------|------|
| Mechanism (public) | Undocumented AGX/GFX debug/DMA path → overwrite cachelines for PPL-protected phys → flush → DRAM write; page-table mutation → PPL bypass |
| SoCs | A12+ in Dopamine’s dmaFail table (A12 `hw.cpufamily` `0x07D34B9F` in public `dmaFail.c`) |
| Used in | Dopamine 2.x (with kfd-era kernel entry) |
| Apple fix | **iOS 16.6** (dmaFail page); A15/A16 additionally unexploitable earlier on 16.5.1 via debug-register disable |
| On 22H311 | **Patched** — do not attempt as live path |

Teacher takeaway for A12: PPL defeat historically looked like **DMA/GFX-assisted
physical write into PPL memory after KRW**, not “patch a userspace flag.”
Relaxin 0.4.2’s `ppl-dma-a12` naming is the same *family of idea* (DMA/dbgwrap),
not proof the same bug is live.

## Dopamine-shaped post-exploit (architecture only)

On A12 during the public Dopamine window, the rough order was:

```text
kernel entry (kfd-class / later plugs)
  → PAC-aware primitives (arm64e)
  → PPL bypass (dmaFail-era)
  → AMFI / trustcache / sandbox
  → rootless bootstrap (jailbreakd, ElleKit, …)
```

For Lumina on 22H311:

- Keep this as a **component checklist**
- Do **not** port offsets or assume dmaFail/kfd still apply
- RootHide / Relaxin-style tools that “plug a kexploit” still need a **live**
  entry + PPL story for this build — architecture ≠ installer

Viability: [../kexploit/viability/dopamine_bootstrap_arch.md](../kexploit/viability/dopamine_bootstrap_arch.md).

## Coruna / Relaxin (later teachers)

| Project | What public/static notes give us | Not granted |
|---------|----------------------------------|-------------|
| Coruna (disclosure) | Later-iOS kit research; claim vs proof | XR 18.7.5 installer |
| Relaxin 0.3.4 / RelaxinPPL | A14/PPL gate static analysis method | A12 path |
| Relaxin 0.4.2 | First-class `ppl-dma-a12` backend vocabulary | Live on 18.7.5; confirm still 17.0–17.3.1; early entry still DarkSword |

Cards: [T003](../kexploit/experiments/T003_relaxinppl_teacher_not_installer.md),
[T013](../kexploit/experiments/T013_relaxin_042_a12_dma_teacher.md).

## What changed by 18.7.x (summary)

1. **dmaFail-class public A12 PPL** — gone since 16.6.
2. **kfd-class public KRW** — gone well before 18.7.5 ([T001](../kexploit/experiments/T001_kfd_dead_on_1875.md)).
3. **DarkSword kernel PE pair** — fixed 18.7.2; XR is 18.7.5 ([T004](../kexploit/experiments/T004_darksword_kernel_dead_on_1875.md)).
4. **iOS 18 public PPL/SPTM catalog** — empty.
5. **A12 still PPL, not SPTM** — mitigations model unchanged; do not import A15+ SPTM narratives as the XR plan.

## Open research questions (needs kernelcache / lab — unknown)

Mark **unknown** until probes land; do not invent answers.

- Exact PPL call gates / trampoline layout in **22H311** vs 16.x dmaFail-era kernels
- Whether any **non-public** or advisory-adjacent phys write still touches PPL memory on A12 18.7.5 (no claim)
- How 18.7.x AMFI/trustcache interacts with a hypothetical post-PPL bootstrap

Offline probe list remains in [../kexploit/22H311_NOTES.md](../kexploit/22H311_NOTES.md).

## Explicit non-claims

- Historical success on A12 ≠ path on 22H311
- No invented gadgets, MMIO bases, or “it still works” statements
- No merge of Dopamine/Relaxin exploit sources into `boot/`
