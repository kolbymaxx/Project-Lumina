# B002 — Remap alone makes `dpkg` run?

## Claim
Once `/var/jb` is remapped/staged, `/var/jb/usr/bin/dpkg` (or equivalent)
would execute without further trustcache / AMFI work.

## Result
- [x] Supported (**No** — still exit **137** / SIGKILL)
- [ ] Contradicted
- [ ] Unknown

**Evidence (local session):** remap succeeded (B001) but `dpkg` still killed.

## Lab test?
- [x] No — closed; do not re-run

## Status impact
Remap is necessary staging at best, **not sufficient**. Next falsifier: **B005**.
