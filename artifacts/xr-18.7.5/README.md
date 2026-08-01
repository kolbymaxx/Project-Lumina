# XR 18.7.5 (22H311) artifacts

Staging area for Phase A dumps from the live iPhone XR ramdisk.

Boot path is **working** (iBSS → Recovery → ramdisk SSH). Phase A inventory
is **locked** in `phase-a-2026-08-01.md` and `docs/STATUS.md`.

Key facts: ramdisk **15.1** (`19B5042h`); System/Update/Cryptex RO mounts
confirm on-disk **18.7.5 (22H311)**; Data/`s8` fail (`mount_apfs` exit **76**).
No kexploit / Data R/W / Sileo claim.

## Placeholders (tracked)
| Placeholder | Fill with |
|-------------|-----------|
| `uname.txt.placeholder` | `uname -a` (+ SystemVersion nearby) |
| `mount.txt.placeholder` | `mount` |
| `disks.txt.placeholder` | `ls -la /dev/disk*` |
| `mount-system-data.txt.placeholder` | System + Data mount attempts |
| `kernelcache-paths.txt.placeholder` | kernel / preboot paths |
| `writable.txt.placeholder` | seal / writable probes |

## Suggested real dumps (gitignored)
```text
artifacts/xr-18.7.5/
  boot-logs/                 # created by boot/lumina-boot.sh
  ground-truth.txt           # full collect-ground-truth.sh capture
  uname.txt
  SystemVersion.plist
  mount.txt
  disks.txt
  mount-system-data.txt
  kernelcache-paths.txt
  writable.txt
  kernelcache/               # pulled or IPSW-extracted kernel
  notes.md
```

Collect:
```bash
./boot/lumina-ssh.sh 'bash -s' < boot/collect-ground-truth.sh \
  | tee artifacts/xr-18.7.5/ground-truth.txt
```

Paste summaries into `docs/STATUS.md`. Do not commit large binaries or raw
personal dumps unless intentionally scrubbed.
