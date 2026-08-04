# B001 — `/var/jb` tmpfs remap kills SSH?

## Claim
Staging `/var/jb` via tmpfs remap would break the live SSH session (or kill
the ramdisk userspace enough to lose the foothold).

## Result
- [x] Supported (**No** — does not kill SSH)
- [ ] Contradicted
- [ ] Unknown

**Evidence (local session):** PHASE1_OK after remap. SSH remained usable.

## Lab test?
- [x] No — closed; do not re-run

## Status impact
Remap is safe enough as a staging step. Does **not** unlock `dpkg` (see B002).
