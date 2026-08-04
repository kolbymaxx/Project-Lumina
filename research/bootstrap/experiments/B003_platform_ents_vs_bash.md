# B003 — Missing platform ents vs bash?

## Claim
`dpkg` dies because it lacks platform entitlements that bash has (ents-only
story).

## Result
- [x] Supported (**No** — same ents, different CDHash)
- [ ] Contradicted
- [ ] Unknown

**Evidence (local session):** entitlement sets matched the comparison; CDHash
differed. Points at **code-signature / trustcache membership**, not missing
platform ents.

## Lab test?
- [x] No — closed; do not re-run

## Status impact
Strengthens B005 (append dpkg CDHash to build TC) over ents editing.
