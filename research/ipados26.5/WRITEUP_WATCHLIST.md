# Writeup watchlist — A12X / iPadOS 26.5

Public artifacts that would **change** [PUBLIC_PRIMITIVE_MATRIX.md](PUBLIC_PRIMITIVE_MATRIX.md) status or unblock lab.

## PPL / Dopamine status line (locked wording)

**Public A12/A13 PPL (momentarius) through 18.7.1 and 26.0.1; not 18.7.5; not 26.5.**  
**A12X:** same CPU family as A12 in Dopamine (`VORTEX_TEMPEST` → `momentarius_init_A12`); treat as **in-scope for that ≤26.0.1 teacher**, not as a 26.5 installer.

Former “no public A12 PPL” line is **obsolete** for ≤26.0.1 — replace with the line above.  
Our matrix status for **this lab OS** stays: **no matching public primitive for A12X / iPadOS 26.5**.

## Sharp questions (not hopium)

| Device / window | Question |
|-----------------|----------|
| XR **18.7.5** | What between **18.7.1 → 18.7.5** breaks ClearSword and/or momentarius (or their kexp deps)? Label XR track. |
| iPad **26.5** | What between **26.0.1 → 26.5** breaks the Dopamine 3.0 gates — and what overlaps our **26.6** scoreboard (AVE / kernel / MediaRemote)? |
| A12X | Confirmed in-tree as A12 family for momentarius; still **unproven** on **26.5**. |

## Watches

| Watch | Why it matters | Action if found |
|-------|----------------|-----------------|
| Kernel exp with clear **26.5-compatible** / **fixed-in-26.6** bounds + A12/A12X plausibility | May become FILTER-pass Path A/B candidate | New P00N card; Lab only after (1)(2)(3) |
| Public **A12/A12X PPL** past **26.0.1** | Path A stage 2 on **26.5** after KRW | momentarius today stops at 26.0.1 — teacher only ([P007](experiments/P007_dopamine3_teacher_not_installer.md)) |
| ClearSword / KRW with clear **26.5** bounds | Unblocks Path A entry | Stops at **26.0.1** in Dopamine 3.0 — watch forks |
| Detailed writeup: CVE-2026-64747 (AVE), 64751, 43805, 43723 | Sink/reachability | Audit card; still fail-closed |
| 26.5 IPSW hashes | Offline diff | **Done** (23F77 / 23G71) |
| usbliter8 t8027 `PWND` | Path C | Label device/OS; ≠ PE |

## Ignore as status movers
- YouTube / Discord “iOS 26 jailbreak” on **26.0.1** as if **26.5**
- Editing Dopamine plists to claim 26.5 without new primitives
- `pattern_F_` recovery
- XR 18.7.x notes mixed into A12X 26.5 without a device/OS label
