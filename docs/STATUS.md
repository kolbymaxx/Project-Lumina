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

## Current verified state (tonight — do not regress)

On **iMac + macOS** with PR #2-era `usbliter8ctl` host path:

1. **usbliter8** Pico → Pwned DFU (`05ac:1227`, `PWND:[usbliter8]`) — works
2. **Remote iBSS boot** → Recovery `05ac:1281` — works (device **leaves** SecureROM DFU)
3. **hsbugss usbliter8-xr-ramdisk** `exploit.sh` full chain — works  
   firmwares → DeviceTree → ramdisk → trustcache → kernel → `bootx`
4. **Root SSH** on ramdisk — works (`alpine` / `root` via `iproxy 2222 22`)
5. Device appears on usbmux after `bootx` (not stuck in Recovery)

Earlier “stuck on `05ac:1227`” notes were from the patched-image / host-path
debug phase. That is **not** the current state when booting known-good
`payload/iBSS.raw` on macOS.

## Paths
- Host tool (iMac): PR #2 macOS `usbliter8ctl` remote-boot path
  - also `~/Projects/usbliter8-jailbreak/usbliter8ctl` or this repo’s `usbliter8ctl`
- Ramdisk project: `~/Projects/usbliter8-xr-ramdisk`
- IPSW-related: `iPhone11,8_18.7.5_22H311_Restore`
- This monorepo boot wrapper: `boot/lumina-boot.sh`  
  (UDID default / auto-detect for `00008020-00117540340B002E`)

## Known issues
- Upstream hsbugss `exploit.sh` historically waited on a **foreign UDID**;
  Lumina wrappers use this XR’s UDID or `idevice_id` auto-detect — do not
  copy the foreign id back into `boot/`
- `sshpass` may need `brew install sshpass`
- After `bootx`, `irecovery` fails (expected — left Recovery)
- Black screen can still be a live ramdisk (SSH is the check)
- Session is **tethered**: unplug/reboot = full re-pwn
- Phase A mount / disk ground truth not yet pasted (placeholders below)

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
### A — Device ground truth (XR ramdisk SSH) — NEXT
- [ ] `uname -a`, SystemVersion, build
- [ ] `mount`, `ls /dev/disk*`
- [ ] Mount System + Data if possible
- [ ] Pull kernelcache + note paths
- [ ] Record seal / writable reality

Collect with:
```bash
./boot/lumina-ssh.sh 'bash -s' < boot/collect-ground-truth.sh \
  | tee artifacts/xr-18.7.5/ground-truth.txt
```
Paste under **Device notes** and fill `artifacts/xr-18.7.5/*.placeholder` files.

### B — Lumina monorepo
- [x] Create Lumina repo layout in Project-Lumina
- [x] `docs/STATUS.md` = this file
- [x] `boot/` wrappers around known-good usbliter8ctl + exploit flow
- [x] Fix UDID / SSH wait for *this* XR (`00008020-00117540340B002E`)
- [x] `tools/mount_from_ramdisk.sh` stubs fed by A output
- [x] Phase A artifact placeholders under `artifacts/xr-18.7.5/`

### C — Kexploit study tree (separate, don’t break boot)
- [x] Index public darksword-kexploit / related under `research/kexploit/`
- [ ] Operator may clone study trees locally; never mix into boot path
- [x] Document claimed version windows vs **18.7.5 / 22H311**
- **No kexploit implementation in this phase**

## Device notes (operator paste)

### A1 — uname / SystemVersion / build
```
(paste here)
```
Also: `artifacts/xr-18.7.5/uname.txt`, `SystemVersion.plist`

### A2 — mount / disks
```
(paste here)
```
Also: `artifacts/xr-18.7.5/mount.txt`, `disks.txt`

### A3 — System + Data mount attempts
```
(paste here)
```
Also: `artifacts/xr-18.7.5/mount-system-data.txt`  
Then set `SYSTEM_DEV` / `DATA_DEV` for `tools/mount_from_ramdisk.sh`.

### A4 — kernelcache paths
```
(paste here)
```
Also: `artifacts/xr-18.7.5/kernelcache-paths.txt`

### A5 — seal / writable reality
```
(paste here)
```
Also: `artifacts/xr-18.7.5/writable.txt`

## Hard gates (do not skip)
- No public claim of Sileo / package manager on 18.7.5
- No claim of working kernel exploit on 18.7.5 / 22H311
- LARA public support ends at **18.7.1**; **18.7.2+ is unsupported** there
- PPL / SPTM remain open research problems after any k r/w primitive

## Success criteria (near term)
1. [x] One command re-enters ramdisk SSH on this XR → `boot/lumina-boot.sh`
2. [ ] STATUS contains real mount + build notes from the device → Phase A paste
3. [x] Repo exists; kexploit clones are isolated under `research/`
