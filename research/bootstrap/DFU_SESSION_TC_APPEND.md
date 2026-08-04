# DFU session — B005 TC append (best next)

**Goal:** falsify “TC membership vs post-TC gate” for staged `dpkg`.  
**Not a jailbreak session.** One binary, one exec check.

## Preconditions
- [ ] Closed cards B001–B004 accepted (do not re-run)
- [ ] Exact on-device `dpkg` path known (e.g. `/var/jb/usr/bin/dpkg`)
- [ ] Mac can rebuild `trustcache.img4` with an appended CDHash
- [ ] Phone ready for full usbliter8 re-pwn

## Steps
1. **Host:** `ldid -h` (or project hash tool) on the **same bytes** that will
   land in `/var/jb/.../dpkg`. Record CDHash.
2. **Host:** append CDHash → rebuild trustcache → rebuild payload set.
3. **DFU:** pwn → boot known-good chain with new TC.
4. **SSH:** confirm foothold; remap `/var/jb` (B001-safe).
5. **One shot:**
   ```sh
   /var/jb/usr/bin/dpkg --version; echo exit:$?
   ```
6. Fill [experiments/B005_tc_append_dpkg_cdhash.md](experiments/B005_tc_append_dpkg_cdhash.md) Result.

## Outcomes
| Exit | Meaning | Next |
|------|---------|------|
| `dpkg` prints version | TC membership was necessary and **sufficient** for this check | Document; still ≠ Sileo |
| still **137** | Post-TC gate (LC/CSM/stub) | Run [B006](experiments/B006_amfi_tc_stub_hit.md) + offline RE |
| boot/SSH broken | Build/TC packaging regression | Diff TC vs last known-good |

## Optional same session
- [B007](experiments/B007_live_cs_counters.md) counters around the failed/successful exec  
- Do **not** start B008 (bootargs) in the same build unless B005 packaging is clean

## Explicit non-claims
- No kernel r/w, no PPL bypass, no package-manager bootstrap claim
- No mass fakesign ([B000](experiments/B000_fakesign_bash_copy.md))
