# NOTES_NEXT — ramdisk paths for iOS 18 Data

## Resolved (2026-08-01 night) — prefer this
**Mac `~/Projects/ICH_A12_plus_Ramdisk`** for `n841ap` / **22H311**:
- `build.sh --build 22H311 --with-fw --kpf-set ios18`
- `boot.sh` (direct iBEC) → SSH → `mount_ich`
- System `/mnt1`, Data `/mnt2` **mount OK**
- Empty user Data after intentional erase is expected

See [`docs/STATUS.md`](../docs/STATUS.md).

## Closed negatives (do not reopen for live Data)
| Path | Result |
|------|--------|
| 15.1 hsbugss ramdisk `mount_apfs` Data | exit **76** |
| DYLD / drop-in newer `mount_apfs` on 15.1 | `_malloc_type_malloc` — **forbidden** |
| Windows usbliter8ctl iBSS→iBEC→go | no SRTG jump — abandoned for ramdisk use |

## Still open
- Userspace bootstrap / Sileo on clean lab phone
- Kernel exploit for A12 / 18.7.5 (study only under `research/kexploit/`)
