# P006 — MediaRemote CVE-2026-43723 root watch

Target: **A12X / iPadOS 26.5**.

## Claim
26.6 fixed MediaRemote **path handling** with impact app → **root privileges**. This is a **Path B / staging** watch: userspace root ≠ kernel r/w ≠ PPL bypass. May matter only after a separate kernel primitive, or as a temporary lab privilege if reachable from a third-party app.

## Source
- https://support.apple.com/en-ca/128066 — MediaRemote / CVE-2026-43723
- Available for includes iPad Pro 12.9-inch 3rd generation

## Filter
- [x] Pass — privilege escalation claimed; A12X available-for; fixed 26.6; citable; labeled Path B/staging not Path A KRW
- [ ] Reject — reason:

## Lab test?
- [x] No (docs only) — need framework path-validation diff + cited reachable API
- [ ] Yes — (1)(2)(3):

## Result
- [ ] Supported
- [ ] Contradicted
- [x] Unknown

## Status impact
matrix: **candidate watch** (Path B staging)  
status line: **no matching public primitive for A12X / iPadOS 26.5**
