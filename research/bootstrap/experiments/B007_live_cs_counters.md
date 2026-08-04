# B007 — Cheap live probes (SSH after remap, no resign)

## Claim
Read-only / evidence probes can characterize the kill without clearing it:
CS defer counters and CDHash membership story via `ldid -h`.

## Lab test?
- [ ] No (docs only)
- [x] Yes — live SSH; **does not** clear SIGKILL

## Experiment steps
1. After remap (B001-safe), before a failed `dpkg`:
   - snapshot `sysctl` for `vm.cs_defer_to_csm*` / `cs_force_*` (exact names as
     present on this ramdisk kernel — record what exists).
2. Run one failing `dpkg` (expect 137).
3. Re-read the same sysctls — did counters move?
4. `ldid -h` on a **known TC’d** ramdisk binary vs the staged `dpkg`.
5. Record hashes / output; no resign; no mass `ldid`.

## Result
- [ ] Supported (useful counter/hash evidence captured)
- [ ] Contradicted
- [x] Unknown

## Status impact
Evidence only. Prefer after or between DFU builds; never a substitute for B005.
