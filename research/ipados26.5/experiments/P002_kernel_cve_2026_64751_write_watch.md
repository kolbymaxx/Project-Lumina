# P002 — Kernel CVE-2026-64751 write watch

Target: **A12X / iPadOS 26.5**.

## Claim
26.6 fixed a kernel **use-after-free** described as app → unexpected termination **or write kernel memory**. Strong Path A interest **if** controllable; until binary clustering + reachability, this is a **watch** only (Path B panic possible later). No invented trigger.

## Source
- https://support.apple.com/en-ca/128066 — Kernel / CVE-2026-64751 (N.M.Praveen Nawarathne)
- Available for includes iPad Pro 12.9-inch 3rd generation
- Watchlist poll (2026-08-08, docs only) — secondary cites with confirmed bounds:
  - NVD: https://nvd.nist.gov/vuln/detail/CVE-2026-64751 — CWE-416 UAF; fixed 26.6 train; CISA-ADP CVSS 9.8 (AV:N) **conflicts** with vendor "app" wording — treat as **local-app**, not remote
  - Armis: https://cve.armis.com/CVE-2026-64751 — "use-after-free in an unspecified kernel-adjacent component"; affected = all Apple OS **< 26.6**; **no active exploitation reported**
  - GitHub Advisory: https://github.com/advisories/GHSA-7fmj-p4g6-w228 — CWE-416
  - stack.watch: https://stack.watch/vuln/CVE-2026-64751/ — bounds: before 26.6

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

## Watchlist poll note (2026-08-08)
Bounds confirmed (affected < 26.6; fixed 26.6; A12X in scope). Component is **unspecified** in all
secondary sources — no named sink, no PoC, no active-exploitation report. NVD network vector is
**misleading** vs vendor "app" wording; treat as local-app. Advisory impact text = **priority only**.
Lab stays **No**; status line unchanged. Next: P003 poll.

## Status impact
matrix: **candidate watch**  
status line: **no matching public primitive for A12X / iPadOS 26.5**
