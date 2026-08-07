# P002 — Kernel CVE-2026-64751 write watch

Target: **A12X / iPadOS 26.5**.

## Claim
26.6 fixed a kernel **use-after-free** described as app → unexpected termination **or write kernel memory**. Strong Path A interest **if** controllable; until binary clustering + reachability, this is a **watch** only (Path B panic possible later). No invented trigger.

## Source
- https://support.apple.com/en-ca/128066 — Kernel / CVE-2026-64751 (N.M.Praveen Nawarathne)
- Available for includes iPad Pro 12.9-inch 3rd generation

## Filter
- [x] Pass — kernel write language; not SoC-locked away from A12X in advisory text; fixed 26.6; citable
- [ ] Reject — reason:

## Lab test?
- [x] No (docs only) — need kernelcache UAF fix sites + cited local capability
- [ ] Yes — (1)(2)(3):

## Result
- [ ] Supported
- [ ] Contradicted
- [x] Unknown

## Status impact
matrix: **candidate watch**  
status line: **no matching public primitive for A12X / iPadOS 26.5**
