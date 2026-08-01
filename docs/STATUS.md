# Lumina Jailbreak — Project Status (2026-08-01)

## Goal
Research tethered → semi-untethered style jailbreak path for A12/A13 on modern iOS,
starting from usbliter8 BootROM. Codename: **Lumina**.

Not a claim of public Sileo-on-18.7.5 today. Phased research with hard gates.

## Devices
| Device | SoC | iOS | Role |
|--------|-----|-----|------|
| iPhone XR (n841ap) | A12 | **18.7.5 (22H311)** | Primary research — **LIVE** |
| iPhone 11 Pro Max | A13 | TBD | Second target (usbliter8 supports A13) |

XR UDID: `00008020-00117540340B002E`  
ECID: `00117540340B002E`  
Serial (Recovery): `F2LZJAE1KXKQ`

## Current verified state (do not regress)

On **iMac + macOS** with PR #2-era `usbliter8ctl` host path:

1. **usbliter8** Pico → Pwned DFU (`05ac:1227`, `PWND:[usbliter8]`) — works
2. **Remote iBSS boot** → Recovery `05ac:1281` — works
3. **hsbugss usbliter8-xr-ramdisk** full chain → `bootx` — works
4. **Root SSH** on ramdisk — works (`alpine` / `root` via `iproxy 2222 22`)
5. Device appears on usbmux after `bootx`

## Phase A — 2026-08-01 (XR ramdisk SSH) — PARTIAL

| Item | Result |
|------|--------|
| Boot | usbliter8 → hsbugss xr-ramdisk → root SSH (`alpine`, `iproxy 2222`) |
| UDID | `00008020-00117540340B002E` |
| Ramdisk identity | **iOS 15.1 restore (`19B5042h`)**, root `/dev/md0` HFS **RO** |
| System | `disk0s1s1` → `/mnt1` **OK** |
| Real device OS | `/mnt1` SystemVersion = **iOS 18.7.5 (22H311)** |
| Data | `disk0s1s2` → **FAIL** `mount_apfs: Program version wrong` |
| Preboot-ish | `disk0s1s5` → `/mnt4` OK (`mobile/Library` present) |
| Kernel under `/mnt1` | not yet located (`Caches` / `Kernels` empty or missing) |

**Blocker:** the 15.1 ramdisk `mount_apfs` cannot mount the iOS 18 Data volume.

Implications:
- System volume is readable → can inspect on-disk 18.7.5 userspace from `/mnt1`
- Data volume is **not** mountable with this ramdisk tool — need a newer
  `mount_apfs` / newer restore ramdisk, or another read path
- Kernelcache for 22H311 may need IPSW extract on host if not under `/mnt1`

## Paths
- Host tool (iMac): PR #2 macOS `usbliter8ctl` remote-boot path
- Ramdisk project: `~/Projects/usbliter8-xr-ramdisk` (15.1-based payloads)
- IPSW-related: `iPhone11,8_18.7.5_22H311_Restore`
- Lumina boot wrapper: `boot/lumina-boot.sh`

## Known issues
- Upstream hsbugss `exploit.sh` historically used a foreign UDID; Lumina
  wrappers use this XR’s UDID / auto-detect
- `sshpass` may need `brew install sshpass`
- After `bootx`, `irecovery` fails (expected — left Recovery)
- Black screen can still be a live ramdisk (SSH is the check)
- Session is **tethered**: unplug/reboot = full re-pwn
- **Data mount blocked** by 15.1 `mount_apfs` vs iOS 18 APFS

## Research map (other codebases)
| Project | Use for Lumina |
|---------|----------------|
| Dopamine (opa334) | Bootstrap / rootless / jailbreakd **architecture** after k r/w |
| Relaxin | iOS 17.x Dopamine-family — study only, wrong major for 18.7.5 |
| Coruna | ≤~17.2.1 chains; **PPL RE reference**, not drop-in |
| DarkSword + opa334/darksword-kexploit | **Kernel r/w research**; PPL/SPTM still called out as missing |
| LARA (toolbox on DarkSword kexploit) | Reference for userspace tooling patterns |

Lumina stack intent:
  usbliter8 → ramdisk/SSH → (research) kernel r/w → (hard) PPL → Dopamine-like bootstrap

## Phases
### A — Device ground truth (XR ramdisk SSH)
- [x] Ramdisk identity / root mount noted (15.1 / `19B5042h`, `/dev/md0` HFS RO)
- [x] System mount `disk0s1s1` → `/mnt1`; SystemVersion **18.7.5 (22H311)**
- [x] Data mount `disk0s1s2` attempted — **FAIL** (program version wrong)
- [x] Preboot-ish `disk0s1s5` → `/mnt4`
- [ ] Locate kernelcache under `/mnt1` or pull from IPSW on host
- [ ] Record fuller seal / writable reality beyond volume mounts
- [ ] Unblock Data mount (newer ramdisk / `mount_apfs`)

### B — Lumina monorepo
- [x] Repo layout, STATUS, boot wrappers, UDID fix, mount stubs, artifacts

### C — Kexploit study tree (separate, don’t break boot)
- [x] Index under `research/kexploit/`
- [ ] Operator may clone study trees locally; never mix into boot path
- [x] Document claimed version windows vs **18.7.5 / 22H311**
- **No kexploit implementation in this phase**

## Device notes (Phase A)

### A1 — uname / SystemVersion / build
```
Ramdisk: iOS 15.1 restore identity (19B5042h)
Root FS: /dev/md0 HFS read-only
On-disk System (/mnt1) SystemVersion: iOS 18.7.5 (22H311)
UDID: 00008020-00117540340B002E
```

### A2 — mount / disks
```
/ (ramdisk) = /dev/md0 HFS RO
disk0s1s1 → /mnt1  (System) OK
disk0s1s2 → Data   FAIL mount_apfs: Program version wrong
disk0s1s5 → /mnt4  (preboot-ish; mobile/Library present) OK
```

### A3 — System + Data mount attempts
```
SYSTEM_DEV=/dev/disk0s1s1  → /mnt1 OK
DATA_DEV=/dev/disk0s1s2    → FAIL (15.1 mount_apfs vs iOS 18 Data)
PREBOOT_DEV=/dev/disk0s1s5 → /mnt4 OK
```

### A4 — kernelcache paths
```
Under /mnt1: Caches/Kernels empty or missing — not located yet.
Next: search /mnt1 more thoroughly and/or extract from
iPhone11,8_18.7.5_22H311_Restore IPSW on the Mac host.
```

### A5 — seal / writable reality
```
Ramdisk root is HFS RO.
System (/mnt1) mounted (readable; write/seal not fully characterized).
Data not mounted — no Data writable assessment yet.
```

## Next (after Phase A partial)
1. Find kernelcache (host IPSW extract and/or deeper `/mnt1` + `/mnt4` search)
2. Research newer restore ramdisk / `mount_apfs` that can mount iOS 18 Data
3. Keep kexploit study isolated — do not block boot path on Data mount

## Hard gates (do not skip)
- No public claim of Sileo / package manager on 18.7.5
- No claim of working kernel exploit on 18.7.5 / 22H311
- LARA public support ends at **18.7.1**; **18.7.2+ is unsupported** there
- PPL / SPTM remain open research problems after any k r/w primitive

## Success criteria (near term)
1. [x] One command re-enters ramdisk SSH on this XR
2. [x] STATUS contains real mount + build notes from the device (partial; Data blocked)
3. [x] Repo exists; kexploit clones are isolated under `research/`
