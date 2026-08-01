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

## What already works (do not regress)
1. **usbliter8** Pico path → Pwned DFU (`05ac:1227`, `PWND:[usbliter8]`)
2. Host tool: `~/Projects/usbliter8-jailbreak/usbliter8ctl` (Mac)
3. **iBSS boot** → Recovery `05ac:1281`
4. **hsbugss usbliter8-xr-ramdisk** `exploit.sh` full payload chain:
   firmwares → DeviceTree → ramdisk → trustcache → kernel → `bootx`
5. **Root SSH** on ramdisk: `alpine` / `root` via `iproxy 2222 22`
   Prompt seen: `-sh-3.2#`
6. Device appears on usbmux after bootx (not stuck in Recovery)

## Paths
- usbliter8ctl: `~/Projects/usbliter8-jailbreak/usbliter8ctl` (or repo root variant)
- Ramdisk project: `~/Projects/usbliter8-xr-ramdisk`
- IPSW-related: `iPhone11,8_18.7.5_22H311_Restore`
- Windows history exists; **current working path is Mac + irecovery**
- This monorepo: Project-Lumina (`boot/lumina-boot.sh`)

## Known issues
- Upstream `exploit.sh` waits on a **hardcoded foreign UDID** — Lumina boot
  wrappers use `00008020-00117540340B002E` or `idevice_id -l`
- `sshpass` may need `brew install sshpass`
- After `bootx`, `irecovery` fails (expected — left Recovery)
- Black screen can still be a live ramdisk (SSH is the check)
- Session is **tethered**: unplug/reboot = full re-pwn

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

## Phases (execute together)
### A — Device ground truth (XR, this session or next SSH)
- [ ] `uname -a`, SystemVersion, build
- [ ] `mount`, `ls /dev/disk*`
- [ ] Mount System + Data if possible
- [ ] Pull kernelcache + note paths
- [ ] Record seal / writable reality

Paste SSH outputs under **Device notes (operator paste)** below.

### B — Lumina monorepo
- [x] Create Lumina repo layout in Project-Lumina
- [x] `docs/STATUS.md` = this file
- [x] `boot/` wrappers around known-good usbliter8ctl + exploit.sh
- [x] Fix UDID / SSH wait for *this* XR
- [x] `tools/mount_from_ramdisk.sh` stubs fed by A output

### C — Kexploit study tree (separate, don’t break boot)
- [x] Index public darksword-kexploit / related under `research/kexploit/`
- [ ] Operator may clone study trees locally; never mix into boot path
- [x] Document claimed version windows vs **18.7.5 / 22H311**

## Device notes (operator paste)

### A1 — uname / SystemVersion / build
```
(paste here)
```

### A2 — mount / disks
```
(paste here)
```

### A3 — System + Data mount attempts
```
(paste here)
```

### A4 — kernelcache paths
```
(paste here)
```

### A5 — seal / writable reality
```
(paste here)
```

## Hard gates (do not skip)
- No public claim of Sileo / package manager on 18.7.5
- No claim of working kernel exploit on 18.7.5 / 22H311
- LARA public support ends at **18.7.1**; **18.7.2+ is unsupported** there
- PPL / SPTM remain open research problems after any k r/w primitive

## Success criteria (near term)
1. One command re-enters ramdisk SSH on this XR → `boot/lumina-boot.sh`
2. STATUS contains real mount + build notes from the device → Phase A paste
3. Repo exists; kexploit clones are isolated under `research/` → done for index
