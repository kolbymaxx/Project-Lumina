# P004 — Kernel corrupt cluster CVE-2026-64749 / CVE-2026-43778 watch

Target: **A12X / iPadOS 26.5**.

## Claim
Two 26.6 kernel entries describe app → termination **or corrupt kernel memory** (improved memory handling; UAF). Primary value is **Path B** (reproducible corruption/panic) until control is shown. Cite both CVEs as one offline diff cluster.

## Source
- https://support.apple.com/en-ca/128066 — CVE-2026-64749, CVE-2026-43778
- Available for includes iPad Pro 12.9-inch 3rd generation

## Filter
- [x] Pass — kernel entry; A12X available-for; fixed 26.6; citable
- [ ] Reject — reason:

## Lab test?
- [x] No (docs only)
- [ ] Yes — (1)(2)(3):

## Result
- [ ] Supported
- [ ] Contradicted
- [x] Unknown

## Status impact
matrix: **candidate watch**  
status line: **no matching public primitive for A12X / iPadOS 26.5**
