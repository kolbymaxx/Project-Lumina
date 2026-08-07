# INTAKE — iOS/iPadOS 26.6 security content (2026-07-27)

**Date:** 2026-08-07  
**Source:** https://support.apple.com/en-ca/128066  
**Device filter:** rows that list **iPad Pro 12.9-inch 3rd generation** (A12X lab unit).  
**OS intent:** issues fixed in **26.6** are the delta surface for devices still on **26.5.x**.

Advisory impact text = **priority ranking only**. No PoCs. No invented triggers.

## Tier 1 — open as P00N watches (Pass, Lab = No)

| Priority | Component | CVE | Impact (short) | Card |
|----------|-----------|-----|----------------|------|
| 1 | AVEVideoEncoder | CVE-2026-64747 | App → kernel privileges (buffer overflow / size validation) | [P001](P001_ave_cve_2026_64747_watch.md) |
| 2 | Kernel | CVE-2026-64751 | App → write kernel memory (UAF) | [P002](P002_kernel_cve_2026_64751_write_watch.md) |
| 3 | IOKit | CVE-2026-43805 | App → write kernel memory (race) | [P003](P003_iokit_cve_2026_43805_watch.md) |
| 4 | Kernel | CVE-2026-64749 | App → corrupt kernel memory | [P004](P004_kernel_cve_2026_64749_corrupt_watch.md) |
| 4b | Kernel | CVE-2026-43778 | App → corrupt kernel memory (UAF) | (same cluster as P004; cite in P004) |

## Tier 2 — companion / Path B staging

| Priority | Component | CVE | Impact (short) | Card |
|----------|-----------|-----|----------------|------|
| 5 | Kernel | CVE-2026-64709 | App → disclose kernel memory | [P005](P005_kernel_cve_2026_64709_disclose_watch.md) |
| 6 | MediaRemote | CVE-2026-43723 | App → root privileges (path handling) | [P006](P006_mediaremote_cve_2026_43723_watch.md) |

## Tier 3 — note only (not entry)

| Component | CVE | Note |
|-----------|-----|------|
| Game Center | CVE-2026-64740 | Sandbox breakout — chain-stage |
| libc | CVE-2026-28973 | Sandbox breakout — chain-stage |
| Kernel crash-heavy / OOB | CVE-2026-43739, 43816, … | Path B only if reachability appears in diff |
| Kernel NFS | CVE-2026-28931 | Remote / NFS — demoted for installed-app Path A |
| WebKit batch | multiple | Out of primary scoreboard unless chained after kernel foothold |

## One-line rejects (examples)

- WebKit-only UI spoof / link visited → reject as Path A entry  
- “Port DarkSword to 26.5” without evidence → reject  
- XR T008/T009 (18.7.9 window) → **different track**; do not auto-import  

## Next after intake

1. Lock 26.5 build string on device  
2. Obtain 26.5 + 26.6 IPSW artifacts for offline diff  
3. Do **not** run on-device trigger tests until a card has binary evidence + hypothesis (1)(2)(3)
