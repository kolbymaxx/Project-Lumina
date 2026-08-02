# B006 — ios18 `AMFIIsCDHashInTrustCache` stub actually hits?

## Claim / hypothesis
The ios18 (ICH-tree) `AMFIIsCDHashInTrustCache` stub / patch site is
**incomplete or wrong** on **22H311**. Even with a correctly appended CDHash
(B005), the stub may not be the live gate that bash uses.

## When to run
**After B005.** If appended hash still dies → this card strengthens.

## Lab test?
- [ ] No (docs only)
- [x] Yes — pair live + offline

### Live (after B005 fail)
- Confirm the rebuilt TC is the one loaded (payload hash / boot log).
- Re-run one `dpkg --version` → still 137 strengthens “stub insufficient / post-TC.”

### Offline (host RE — not DFU)
- Compare patched vs stock kernelcache sites for the AMFI TC lookup.
- Document addresses/symbols in `research/kexploit/notes/` or a short note here —
  **no** invented 22H311 offsets in `boot/`.

## Result
- [ ] Supported
- [ ] Contradicted
- [x] Unknown

## Status impact
Separates “hash not in TC” from “TC check never consulted / wrong site.”
