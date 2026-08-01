# NOTES_NEXT — newer ramdisk for iOS 18 Data

**Research checklist only.** No working A12 / 18.7.5 Data mount claimed.

## Why 15.1 is a dead end for Data
| Observation | Implication |
|-------------|-------------|
| `mount_apfs` Data/`s8` → exit **76** `Program version wrong` | APFS userspace too old for on-disk iOS 18 Data |
| Drop-in newer `mount_apfs` → missing **`_malloc_type_malloc`** | 15.1 **libSystem** too old |
| `DYLD_LIBRARY_PATH` / binary transplants | **HARD RULE: do not pursue** |

SSH + System at `/mnt1` remains useful for inventory. **Data needs a new ramdisk generation.**

## What to replace
- [ ] `/sbin/mount_apfs` from a closer restore (try **16.0**, then **18.x**)
- [ ] `apfs.fs` tools (`apfs.util`, helpers under `/System/Library/Filesystems/apfs.fs/`)
- [ ] **libSystem / dyld shared cache generation** matching those binaries
- [ ] Optional later: `seputil` / keybag staging — only after exit 76 is gone
- [ ] Boot objects (iBSS/iBEC/ramdisk/kernel/DeviceTree/trustcache) still load via usbliter8 → Recovery — do not break known-good SSH while experimenting

## Host packaging
| Topic | Mac | Windows |
|-------|-----|---------|
| Extract restore ramdisk | `img4` / `hdiutil` / existing xr-ramdisk scripts | WSL2 or extract on Mac |
| HFS restore (≤16.0) | Familiar edit path | Prefer Mac |
| APFS restore (16.1+) | Mac `hdiutil` | Not practical without Mac |
| Live boot test | Pico-pwn → `usbliter8ctl` → `irecovery` | Prefer Mac |

## Ordered experiments
1. Inventory current ramdisk tools (`mount_apfs`, `apfs.util`, `seputil`).
2. **16.0 n841** restore SSH ramdisk — retry Data **before** seputil.
3. If still 76 → **18.x** APFS restore ramdisk.
4. When errno leaves “Program version wrong”, document it; then Preboot/xART/`seputil`.

## Exit criteria
Live session where Data `mount_apfs -o rdonly` succeeds **or** clear evidence the blocker is keybag/SEP (not tool version). **Neither is done.**

## Non-claims
- Not SSHRD_Script drop-in on A12
- Not Data R/W, not Sileo, not a jailbreak
