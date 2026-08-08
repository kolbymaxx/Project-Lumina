# P003 — IOKit CVE-2026-43805 watch

Target: **A12X / iPadOS 26.5**.

## Claim
26.6 fixed an IOKit **race / state handling** issue with impact app → termination **or write kernel memory**. Promising for user-client adjacent research. **Explicit anti-pattern:** do not invent selectors from the word “IOKit.”

## Source
- https://support.apple.com/en-ca/128066 — IOKit / CVE-2026-43805
- Available for includes iPad Pro 12.9-inch 3rd generation
- Watchlist poll (2026-08-08, docs only) — secondary cites with confirmed bounds:
  - NVD: https://nvd.nist.gov/vuln/detail/CVE-2026-43805 — CWE-362 race; fixed 26.6 train; CISA-ADP CVSS 9.8 (AV:N) **inconsistent** with vendor "app" wording → treat as **local-app**
  - Armis: https://cve.armis.com/CVE-2026-43805 — "race in OS state management"; affected = all Apple OS **< 26.6**; **no active exploitation**
  - SentinelOne: https://www.sentinelone.com/vulnerability-database/cve-2026-43805/ — most technical: "shared kernel state … synchronization primitives"; still **no named user-client / selector**
  - OpenCVE: https://app.opencve.io/cve/CVE-2026-43805 — EPSS < 1%, **no KEV listing** → no public exploit code known

## Filter
- [x] Pass — kernel write language; A12X available-for; fixed 26.6; citable
- [ ] Reject — reason:

## Lab test?
- [x] No (docs only) — list changed IOKit families from IPSW diff before any external method calls
- [ ] Yes — (1)(2)(3):

## Result
- [ ] Supported
- [ ] Contradicted
- [x] Unknown

## Watchlist poll note (2026-08-08)
Bounds confirmed (affected < 26.6; fixed 26.6; A12X in scope). CWE-362 race in shared kernel-state
handling — SentinelOne localizes to "synchronization primitives" but **no named IOKit user-client or
external method** in any source. **No PoC, no KEV, EPSS < 1%.** Anti-pattern holds: do **not** invent
selectors from "IOKit." Lab stays **No**; status line unchanged.

## Status impact
matrix: **candidate watch**  
status line: **no matching public primitive for A12X / iPadOS 26.5**
