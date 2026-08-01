# Lumina Jailbreak — Project Status (2026-08-01)

## Goal
Research tethered → semi-untethered style jailbreak path for A12/A13 on modern iOS,
starting from usbliter8 BootROM. Codename: **Lumina**.

**Not a jailbreak.** No Sileo / package-manager claim on 18.7.5.

## Devices
| Device | SoC | iOS | Role |
|--------|-----|-----|------|
| iPhone XR (n841ap) | A12 | **18.7.5 (22H311)** | Primary research — **LIVE** |
| iPhone 11 Pro Max | A13 | TBD | Second target (usbliter8 supports A13) |

XR UDID: `00008020-00117540340B002E`  
ECID: `00117540340B002E`  
Serial (Recovery): `F2LZJAE1KXKQ`

## Phase A — 2026-08-01 (live XR ramdisk SSH)

### Works
| Step | Detail |
|------|--------|
| BootROM entry | usbliter8 Pico → Pwned DFU |
| Ramdisk boot | usbliter8 → XR ramdisk → root SSH (`alpine`, `iproxy 2222`) |
| Identity | UDID `00008020-00117540340B002E`, ECID `00117540340B002E` |
| Ramdisk env | iOS **15.1** restore (`19B5042h`), root `/dev/md0` HFS **RO** |
| System mount | `disk0s1s1` → `/mnt1` **OK** |
| Real device OS | `/mnt1` SystemVersion = **iOS 18.7.5 (22H311)** |
| Preboot-ish | `disk0s1s5` → `/mnt4` OK |

### Fails
| Step | Detail |
|------|--------|
| Data mount | `disk0s1s2` → **FAIL** `mount_apfs: Program version wrong` |
| Kernel under `/mnt1` | `Caches` / `Kernels` not found this session |

### Blockers (hard gates for later work)
1. **Data volume** — 15.1 ramdisk `mount_apfs` cannot mount iOS 18 Data
2. **Kernel exploit for 18.7.5 / A12** — not present; study only under `research/kexploit/`
3. **Userspace bootstrap** — no Dopamine-like install path until (2) and related primitives exist

### Not claimed
- Not a working jailbreak
- No Sileo / tweak injection / persistence
- No kexploit wired into `boot/`

Theory/RE roadmap added under [ROADMAP_THEORY.md](ROADMAP_THEORY.md) and
`research/` (mitigations, kexploit theory, checkm8/palera1n notes). **No new
live capability** — docs only; boot path unchanged.

Offline Stage C artifact noted (Mac only): see
[../research/kexploit/22H311_NOTES.md](../research/kexploit/22H311_NOTES.md)
(`kernelcache.release.iphone11b` / `kernelcache.payload`). **Not** a kexploit
claim — documentation of an extract for later RE probes.

Host note: Mac clone `boot/config.env` is already correct for this XR; keep docs in sync with UDID above.

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

## Research map (short)
| Project | Role |
|---------|------|
| usbliter8 | A12/A13 **BootROM entry only** (live) |
| XR ramdisk | Tethered SSH + volume inspection (live; 15.1 tooling) |
| checkm8 / palera1n | **A8–A11 knowledge only** — does not apply as a drop-in on A12/18.7.5 |
| DarkSword / LARA / Dopamine | Isolated study for future k r/w + bootstrap — **not wired to boot** |

Full index: [RESEARCH.md](RESEARCH.md)

## Phases
### A — Device ground truth
- [x] Dated works / fails / blockers (this section)
- [ ] Locate kernelcache (deeper search and/or host IPSW extract)
- [ ] Unblock Data mount (newer ramdisk / `mount_apfs`)

### B — Lumina monorepo
- [x] Repo layout, STATUS, boot wrappers, UDID fix, mount stubs, artifacts

### C — Kexploit / legacy BootROM study (isolated)
- [x] `research/kexploit/` index
- [x] `research/checkm8/` + `research/palera1n/` notes (knowledge only)
- **No kexploit implementation wired into boot**

## Next
1. Host-extract or locate kernelcache for 22H311
2. Newer restore ramdisk / `mount_apfs` for iOS 18 Data
3. Keep checkm8/palera1n/kexploit notes isolated from `boot/`
