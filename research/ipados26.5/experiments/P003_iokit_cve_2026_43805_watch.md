# P003 — IOKit CVE-2026-43805 watch

Target: **A12X / iPadOS 26.5**.

## Claim
26.6 fixed an IOKit **race / state handling** issue with impact app → termination **or write kernel memory**. Promising for user-client adjacent research. **Explicit anti-pattern:** do not invent selectors from the word “IOKit.”

## Source
- https://support.apple.com/en-ca/128066 — IOKit / CVE-2026-43805
- Available for includes iPad Pro 12.9-inch 3rd generation

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

## Status impact
matrix: **candidate watch**  
status line: **no matching public primitive for A12X / iPadOS 26.5**
