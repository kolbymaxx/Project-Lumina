# P005 — Kernel disclose CVE-2026-64709 watch

Target: **A12X / iPadOS 26.5**.

## Claim
26.6 fixed a kernel issue: app may **disclose kernel memory**. Useful as a **companion** to a write primitive (Path A support), **not** as entry alone. Do not label leak as KRW.

## Source
- https://support.apple.com/en-ca/128066 — CVE-2026-64709
- Available for includes iPad Pro 12.9-inch 3rd generation

## Filter
- [x] Pass — kernel entry; disclose impact; fixed 26.6; citable; honest Path A-support role
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
