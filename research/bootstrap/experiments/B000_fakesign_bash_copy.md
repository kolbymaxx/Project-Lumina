# B000 — Single controlled fakesign (bash copy)

## Claim
Fakesigning a **single** known-good bash copy is fatal for exec under this
chain (already proven). Mass `ldid` is out of policy.

## Result
- [x] Supported (fatal / skip)
- [ ] Contradicted
- [ ] Unknown

**Evidence (local session):** already proven fatal. Re-run only if documenting a
**new** bootchain with a fresh timestamp — not for progress on dpkg 137.

## Lab test?
- [x] No — skip unless new bootchain
- [ ] Yes

## Status impact
Do not re-run. Prefer **B005** (TC membership) over resign games.
