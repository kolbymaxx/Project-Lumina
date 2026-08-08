# P007 — Dopamine 3.0 teacher (not installer on 26.5)

Target: **A12X / iPadOS 26.5**.  
Filter: [../FILTER.md](../FILTER.md).

## Claim
opa334 **Dopamine 3.0** (2026-08-07) ships a public A12/A13 rootless chain:
**ClearSword** (kernel KRW) + **momentarius** (PPL; A12 codepath includes A12X/Z via
`CPUFAMILY_ARM_VORTEX_TEMPEST`). Official / plist windows end at **18.7.1** and
**26.0–26.0.1** for the 26.x train. Our lab unit is **26.5** → **outside** as a
drop-in installer. Useful as **architecture teacher** (KRW then PPL) and as a
citable public A12/A12X PPL implementation **inside its window** — not as “port to 26.5.”

## Source
- Release: https://github.com/opa334/Dopamine/releases/tag/3.0
- IPA (local): `artifacts/a12x-26.5/dopamine3/Dopamine-3.0.ipa`
  sha256 `d58dafca6dab5349594ebe8a5976bc1ce2afaa81552aba602b565670ce481f05`
- Tree: `research/ipados26.5/vendors/Dopamine` @ `3.0` (gitignored)
- UI string: `DOEnvironmentManager.m` → `iOS 15.0 - 18.7.1, 26.0 - 26.0.1 (A12/A13, PPL)`
- ClearSword `Info.plist`: ranges `15.0`–`18.7.1` + include versions `26.0`, `26.0.1`
- momentarius `Info.plist`: devices `A12`,`A13`; range `15.0`–`26.0.1`; type **PPL**
- momentarius.c: `VORTEX_TEMPEST` → `momentarius_init_A12()` (comment A12(X/Z))

## Filter
- [ ] Pass as **26.5 installer / Path A primitive**
- [x] **Reject** as installer — public last OS for 26.x train is **26.0.1** (&lt; **26.5**); FILTER reject #2 / #4 (“port Dopamine without 26.5 evidence”)
- [x] **Accept as teacher / note-only** — citable public KRW+PPL stack for A12/A12X **≤26.0.1**

## Lab test?
- [x] No — do **not** expect Dopamine 3.0 to jailbreak **26.5**; do not “bump plist End to 26.5” as a plan
- [ ] Yes — (1)(2)(3):

## Gaps this fills vs does not fill (26.5 Path A)

| Layer | Dopamine 3.0 | On our **26.5** |
|-------|--------------|-----------------|
| Kernel KRW | ClearSword (≤18.7.1 + 26.0/26.0.1) | **Missing** — need own primitive (P001 AVE track, etc.) |
| PPL | momentarius (A12/A13, End **26.0.1**) | **Not claimed** for 26.5; study only unless new evidence |
| Bootstrap | Dopamine rootless | Blocked until KRW+PPL on **this** build |
| “Push their JB higher” | Would require **new** KRW (± PPL revalidation) | Our offline 26.5↔26.6 delta hunt — not editing their plists |

## Result
- [ ] Supported as 26.5 installer
- [x] **Contradicted** as 26.5 installer (version gate)
- [x] Supported as **teacher** for Path A *shape* and public Momentarius A12 PPL ≤26.0.1

## Status impact
matrix: **note only** (Dopamine 3.0 row — outside 26.5)  
status line: **unchanged** — no matching public primitive for A12X / iPadOS **26.5**
