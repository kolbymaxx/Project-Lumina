# Lumina Jailbreak — Project Status (2026-08-05)

## Goal
Research tethered → semi-untethered style jailbreak path for A12/A13 on modern iOS,
starting from usbliter8 BootROM. Codename: **Lumina**.

**Not a jailbreak.** No Sileo / package-manager claim on iOS **18.7.5**.

## Devices
| Device | SoC | iOS | Role |
|--------|-----|-----|------|
| iPhone XR (n841ap) | A12 | **18.7.5 (22H311)** | Primary research — **LIVE** |
| iPhone 11 Pro Max | A13 | TBD | Second target (usbliter8 supports A13) |

XR UDID: `00008020-00117540340B002E`  
ECID: `00117540340B002E`  
Serial (Recovery): `F2LZJAE1KXKQ`

---

## KRW + PPL track (userspace / kernel) — v0 research

**Hypothesis:** DarkSword-class (or successor) **KRW** → **PPL** research → Dopamine-shaped bootstrap later.  
**v0 window:** this XR / **22H311** only. Separate from Pico / iBEC track.

| Item | State |
|------|--------|
| Target | iPhone XR · A12 (`t8020`) · **18.7.5 (22H311)** |
| KRW evidence level | **literature** (public PE **patched**); lab **none** |
| PPL evidence level | **literature** (present in kernel; **no** public iOS 18 bypass) |
| Harness | `src/krw/` stubs only — backend **none** |
| Entry (SpringBoard) | **Blocked on stock for TrollStore-style hosts** (see below) |

### DarkSword viability (literature)

| Piece | Landmark | On 22H311 |
|-------|----------|-----------|
| Kernel PE (`CVE-2025-43510`, `CVE-2025-43520`) | Fixed **iOS 18.7.2** (Apple/NVD/GTIG) | **Patched — not a KRW path** |
| Full chain WebKit/ANGLE stages | Fixed **18.7.3** (GTIG table) | **Patched** |
| Public kexploit ports claiming broad iOS support | README ≠ advisory | Treat as **dead** until lab contradicts Apple |

Card: [../research/kexploit/experiments/T004_darksword_kernel_dead_on_1875.md](../research/kexploit/experiments/T004_darksword_kernel_dead_on_1875.md).  
Write-up: [KRW.md](KRW.md).

**Pivot:** KRW section is **not** “integrate DarkSword and win.” Next candidates are advisory watches (e.g. CVEs fixed in **18.7.7 / 18.7.9** that might still apply on 18.7.5) — still **unknown / not demonstrated**. If no live public kexploit appears, this track stays docs-only and the **usbliter8** track remains the only proven capability.

### Entry reality (M1)

**On stock iOS 18.7.5 XR, TrollStore (arbitrary-entitlement sideload) is unavailable.**  
Developer-signed apps are possible with limited entitlements; WebKit full-chain packaging is **not** our product path.

Details: [ENTRY.md](ENTRY.md).

### Blockers (KRW / PPL)

1. **No matching public KRW primitive** proven on A12 / 18.7.5 (DarkSword PE dead; kfd-era dead).  
2. **Stock entry blocked** for TrollStore-class kexploit hosts.  
3. **PPL blocked** for known public techniques on iOS 18 (dmaFail dead since 16.6).  
4. Kernelcache hashes / filled offsets for 22H311 still **TODO** in [BUILD_22H311.md](BUILD_22H311.md).  
5. Operator has not yet chosen SpringBoard test-host signing path (default: docs/offline).

### Docs map (this track)

| Doc | Role |
|-----|------|
| [BUILD_22H311.md](BUILD_22H311.md) | Build identity + kernelcache hash placeholders |
| [KRW.md](KRW.md) | Primitive choice, harness, tests |
| [ENTRY.md](ENTRY.md) | How a binary can run |
| [PPL.md](PPL.md) | PPL options / blocked conclusion |
| [ATTRACT_DEVS.md](ATTRACT_DEVS.md) | Repro, panic format, ask for help |
| [../src/krw/](../src/krw/) | Thin KRW API stubs |
| [../research/ppl/](../research/ppl/) | Deep PPL notes |

### Single next human task

**Confirm SpringBoard entry plan on the XR:** reply with **A** (will developer-sign a minimal test host), **B** (no SpringBoard host — KRW stays docs/offline), or **C** (other, described).  
Until then, maximize offline value: paste **SHA-256** of `kernelcache.payload` into [BUILD_22H311.md](BUILD_22H311.md).

---

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
2. **Kernel exploit for 18.7.5 / A12** — not present; study only under `research/kexploit/` + `src/krw/` stubs
3. **Userspace bootstrap** — no Dopamine-like install path until (2) and related primitives exist

### Not claimed
- Not a working jailbreak; no kexploit; no Data R/W; no Sileo
- No claim beyond tethered SSH + the RO mounts in the inventory above
- No kexploit wired into `boot/`
- No DarkSword / PPL success on 22H311

Theory/RE roadmap under [ROADMAP_THEORY.md](ROADMAP_THEORY.md) and
`research/` (mitigations, kexploit theory, checkm8/palera1n notes). **No new
live capability** from docs-only work; boot path unchanged.

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
| DarkSword / LARA / Dopamine | Isolated study — DarkSword PE **patched** on this build; harness stubs in `src/krw/` |

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
- [x] KRW/PPL research skeleton (`docs/KRW.md`, `docs/PPL.md`, `src/krw/`, …)

### C — Kexploit / legacy BootROM study (isolated)
- [x] `research/kexploit/` index
- [x] `research/checkm8/` + `research/palera1n/` notes (knowledge only)
- [x] RE priority + public primitive matrix (`RE_PRIORITY.md`, `PUBLIC_PRIMITIVE_MATRIX.md`)
- [x] Hunt loop + filter + intakes (`HUNT_LOOP.md`, `FILTER.md`, `experiments/`)
- [x] DarkSword kernel PE → **reject** on 18.7.5 ([T004](../research/kexploit/experiments/T004_darksword_kernel_dead_on_1875.md))
- [x] PPL track docs (`research/ppl/`, `docs/PPL.md`) — conclusion **blocked** for public techniques
- **No matching public primitive for A12 / 18.7.5** — teachers, not installers
- Open **candidate watches** (docs only): **primary** T008 CVE-2026-28972 +
  T009 CVE-2026-28951; secondary/side T005–T007 — see
  [`INTAKE_2026-08-02c.md`](../research/kexploit/experiments/INTAKE_2026-08-02c.md)
- Pre-lab theory pack: **T010–T012** — checklist
  [`DEVICE_SESSION_01.md`](../research/kexploit/experiments/DEVICE_SESSION_01.md)
- **No kexploit implementation wired into boot**

## Next
1. **Human:** entry plan A/B/C + optional kernelcache SHA-256 paste ([BUILD_22H311.md](BUILD_22H311.md))
2. **Device session 01 (RO):** T011 → T010 → T012 per
   [`DEVICE_SESSION_01.md`](../research/kexploit/experiments/DEVICE_SESSION_01.md)
3. **Kernel hunt:** citable writeups for **T008/T009**; continue
   [`HUNT_LOOP.md`](../research/kexploit/HUNT_LOOP.md)
4. Offline Stage C probes on `kernelcache.payload` (see `22H311_NOTES.md`)
5. **Data mount live trials** (see `research/DATA_MOUNT_SSHRD.md`) — still exit 76 on 15.1 tools
6. Keep checkm8/palera1n/kexploit notes isolated from `boot/`
