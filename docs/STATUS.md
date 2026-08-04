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

## Phase A — 2026-08-01 (live XR ramdisk SSH) — **inventory locked**

Tethered usbliter8 → XR ramdisk → root SSH (`alpine`, `iproxy 2222`).
Ramdisk env: iOS **15.1** restore (`19B5042h`), root `/dev/md0` HFS **RO**.

### Locked volume inventory

| Node | Mount | Result | Notes |
|------|-------|--------|-------|
| `disk0s1s1` | `/mnt1` | **OK** RO sealed | **System** — ProductVersion **18.7.5**, ProductBuildVersion **22H311** |
| `disk0s1s5` | `/mnt4` | **OK** | **Update** — ota-result success → **22H311** |
| `disk0s1s6` | `/mnt6` | **OK** | **Cryptex** — see cryptex detail below |
| `disk0s1s3` | `/mnt3` | **OK** RO | **Preboot** (minimal) |
| `disk0s1s4` | `/mnt5` | **OK** RO | **bbfs** |
| `disk0s1s7` | `/mnt7` | **OK** RO | **FactoryData** / MobileActivation / Pearl |
| `disk0s1s2` | — | **FAIL** exit **76** | **Data** — `mount_apfs -o rdonly` → `Program version wrong` |
| `disk0s1s8` | — | **FAIL** exit **76** | same as Data |

**Cryptex (`/mnt6`) detail (locked):**
- `active` → `E66645393AB5A31AE432195F142B705037F78B2AAD76DBADC4C66682285578663DC2BC9C05C6C84346C3ED69D7B91C51`
- `cryptex1/current`: `os.dmg` (~4GB), `app.dmg`, trustcaches, `apticket.n841ap.117540340B002E.im4m`
- SystemVersion **18.7.5 / 22H311**; RestoreVersion **22.8.311.0.0**

### Interpretation (locked)
Ramdisk `mount_apfs` incompatible with Data/`s8` APFS generation (and/or unlock).
**System + Update + Cryptex path works.** Full write-up:
[../research/kexploit/22H311_NOTES.md](../research/kexploit/22H311_NOTES.md),
[../research/DATA_MOUNT_SSHRD.md](../research/DATA_MOUNT_SSHRD.md).

### Blockers (hard gates for later work)
1. **Data volume** — 15.1 ramdisk `mount_apfs` cannot mount iOS 18 Data/`s8` (exit 76)
2. **Kernel exploit for 18.7.5 / A12** — not present; study only under `research/kexploit/`
3. **Userspace bootstrap / AMFI** — staged `dpkg` still **SIGKILL (137)**; TC-membership
   vs post-TC gate under test — see [`research/bootstrap/`](../research/bootstrap/)

### Not claimed
- Not a working jailbreak; no kexploit; no Data R/W; no Sileo
- No claim beyond tethered SSH + the RO mounts in the inventory above
- No kexploit wired into `boot/`

Theory/RE roadmap added under [ROADMAP_THEORY.md](ROADMAP_THEORY.md) and
`research/` (mitigations, kexploit theory, checkm8/palera1n notes). **No new
live capability** — docs only; boot path unchanged.

Offline Stage C artifact noted (Mac only): see
[../research/kexploit/22H311_NOTES.md](../research/kexploit/22H311_NOTES.md)
(`kernelcache.release.iphone11b` / `kernelcache.payload`). **Not** a kexploit
claim — documentation of an extract for later RE probes.

Public tool applicability (2026-08-01): only **usbliter8 + ramdisk** applies as
a real public capability on A12/18.7.5; Dopamine/palera1n are not drop-in for
this chip+build. See [RESEARCH.md](RESEARCH.md#public-tool-applicability-2026-08-01).

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
- [x] Phase A volume inventory **locked** (System/Update/Cryptex/… + Data/`s8` exit 76)
- [x] Offline kernelcache artifact noted (Mac `22H311_NOTES.md`)
- [x] Research newer restore-ramdisk / SSHRD staging docs (`research/DATA_MOUNT_SSHRD.md`)
- [ ] Unblock Data mount in a live session (newer `mount_apfs` ± `seputil` — **not done**)

### B — Lumina monorepo
- [x] Repo layout, STATUS, boot wrappers, UDID fix, mount stubs, artifacts

### C — Kexploit / legacy BootROM study (isolated)
- [x] `research/kexploit/` index
- [x] `research/checkm8/` + `research/palera1n/` notes (knowledge only)
- [x] RE priority + public primitive matrix (`RE_PRIORITY.md`, `PUBLIC_PRIMITIVE_MATRIX.md`)
- [x] Hunt loop + filter + intakes (`HUNT_LOOP.md`, `FILTER.md`, `experiments/`)
- **No matching public primitive for A12 / 18.7.5** — teachers, not installers
- Open **candidate watches** (docs only): **primary** T008 CVE-2026-28972 +
  T009 CVE-2026-28951; secondary/side T005–T007 — see
  [`INTAKE_2026-08-02c.md`](../research/kexploit/experiments/INTAKE_2026-08-02c.md)
- Pre-lab theory pack: **T010–T012** — checklist
  [`DEVICE_SESSION_01.md`](../research/kexploit/experiments/DEVICE_SESSION_01.md)
- **No kexploit implementation wired into boot**

### D — Bootstrap / AMFI–trustcache (ramdisk track — isolated)
- [x] Local session closed cards recorded: remap OK; remap≠dpkg; ents≠cause;
  `num_loadable` stays 0; fakesign skip — [`research/bootstrap/`](../research/bootstrap/)
- [ ] **B005** build-time TC append of `dpkg` CDHash → rebuild → re-pwn → one exec
- [ ] B006 stub-hit / B007 counters / B008 bootargs (after or beside B005)
- **Still:** `dpkg` **137**; not a package-manager bootstrap

## Next
1. **DFU — B005:** append `dpkg` CDHash → rebuild TC → boot → one
   `dpkg --version` — [`DFU_SESSION_TC_APPEND.md`](../research/bootstrap/DFU_SESSION_TC_APPEND.md)
2. **Kernel hunt (parallel):** citable writeups for **T008/T009**;
   [`HUNT_LOOP.md`](../research/kexploit/HUNT_LOOP.md)
3. Offline Stage C probes on `kernelcache.payload` (see `22H311_NOTES.md`);
   pair with B006 if TC append still dies
4. **Data mount live trials** (see `research/DATA_MOUNT_SSHRD.md`) — still exit 76
   on `s2`/`s8` with 15.1 tools
5. Keep bootstrap + kexploit notes isolated from silent `boot/` wiring
