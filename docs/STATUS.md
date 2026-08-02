# Lumina Jailbreak — Project Status (2026-08-02 afternoon)

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

**Lab phone note (2026-08-01 night):** XR was intentionally erased (no passcode,
never set up). Empty user Data is expected — not a mount failure.

## Live path (preferred) — Mac + ICH_A12_plus_Ramdisk — **WORKS**

Measured 2026-08-01 night on Mac (USB-A, no hub):

1. Pico usbliter8 → Pwned DFU (`PWND:[usbliter8]`, `05ac:1227`)
2. `~/Projects/ICH_A12_plus_Ramdisk` → `bootchain/n841ap-18.7.5-22H311-ramdisk`
   - `with_fw`, `kpf_set=ios18`, IMG4+IM4M packaging
   - **Direct iBEC** (no separate iBSS stage) → Recovery → `bootx`
3. SSH: ICH `tools/darwin/iproxy 2222 22` → `sshpass -p alpine ssh -p 2222 root@127.0.0.1`
4. `mount_ich` → **System `/mnt1`**, **Data `/mnt2`** (and other volumes)
5. Reported **18.7.5 (22H311)** / Darwin kernel for T8020

### Reconnect (USB stays plugged)
```bash
# Terminal 1
~/Projects/ICH_A12_plus_Ramdisk/tools/darwin/iproxy 2222 22
# Terminal 2
sshpass -p alpine ssh -p 2222 root@127.0.0.1
# remount if needed
mount_ich
```

Prefer ICH’s vendored `iproxy` (brew `iproxy` can drop). Stay on **Mac/ICH** for
boot+SSH. Windows `usbliter8ctl` iBSS→go is **not** required for current ramdisk use.

### Latest lab (2026-08-02 PM)
Re-pwn → ICH `boot.sh` → SSH → `mount_ich` OK. Bootstrap tree still at
`/mnt2/root/jb` (Procursus strapped). **`dpkg` still SIGKILL (137)**;
`num_loadable: 0`; launch constraints enforced. See
[`docs/research/amfi-trustcache-ich-18.7.5.md`](research/amfi-trustcache-ich-18.7.5.md)
(includes Relaxin A14 comparative teacher — not an XR install path).

### Data partition (this erase)
| Path | Observation |
|------|-------------|
| `/mnt2/mobile` | empty (only tmp) |
| `/mnt2/root/.obliterated` | present |
| `containers/Data` | System only — no personal photos/apps |

Expected after fresh erase to remove passcode — **not** a mount bug.

## Abandoned — Windows usbliter8ctl iBSS→iBEC→go
- Bulk upload OK; device stayed on `05ac:1281` after `go` / `bootx` (no new `SRTG`)
- Stock signed iBEC.im4p also failed to jump; EP0 `setenv`/`go` pipe errors
- Mac ICH path bypasses that by loading its own patched iBoot + full ramdisk chain
- Do **not** resume Windows iBEC-go work unless returning to custom host-side iBoot experiments

## Phase A (earlier) — 15.1 hsbugss-style ramdisk — **inventory locked (historical)**

Tethered usbliter8 → **15.1** restore ramdisk → SSH. Data failed exit **76**.
Superseded for live Data access by ICH path above; keep as negative for 15.1 tools.

| Node | Mount | Result | Notes |
|------|-------|--------|-------|
| `disk0s1s1` | `/mnt1` | **OK** RO sealed | System **18.7.5 / 22H311** |
| `disk0s1s5` | `/mnt4` | **OK** | Update → **22H311** |
| `disk0s1s6` | `/mnt6` | **OK** | Cryptex |
| `disk0s1s3` | `/mnt3` | **OK** RO | Preboot (minimal) |
| `disk0s1s4` | `/mnt5` | **OK** RO | bbfs |
| `disk0s1s7` | `/mnt7` | **OK** RO | FactoryData |
| `disk0s1s2` | — | **FAIL** exit **76** | Data — 15.1 `mount_apfs` |
| `disk0s1s8` | — | **FAIL** exit **76** | same class |

**HARD RULE (15.1 only):** no `DYLD_LIBRARY_PATH` hacks for Data.

## Blockers (remaining)
1. **No kernel exploit** for A12 / 18.7.5 — study only under `research/kexploit/`
2. **Userspace bootstrap / Sileo** — not done; phone is a clean lab target for tethered JB research
3. Session is **tethered**: unplug/reboot = full re-pwn (Pico → DFU → ICH `boot.sh`)

## Not claimed
- Not a working jailbreak; no Sileo; no kexploit
- Empty Data ≠ failed Data mount (erase)
- Windows host iBEC execute path **not** solved — unused for current SSH

## Paths
| Role | Path |
|------|------|
| Preferred boot+SSH | `~/Projects/ICH_A12_plus_Ramdisk` (`build.sh` / `boot.sh`) |
| Bootchain (built) | `…/bootchain/n841ap-18.7.5-22H311-ramdisk` |
| Lumina monorepo / lab scripts | `~/Projects/lumina` |
| Legacy 15.1 payloads | `~/Projects/usbliter8-xr-ramdisk` |
| Host DFU utility | `~/Projects/lumina/host/usbliter8ctl` / root `usbliter8ctl` |
| Host handoff notes (1227/1281, boot vs send, Windows/Mac, re-pwn checklist) | [`docs/HOST_USB_HANDOFF.md`](HOST_USB_HANDOFF.md) |

## Research map (short)
| Project | Role |
|---------|------|
| usbliter8 | A12/A13 **BootROM entry** (live) |
| ICH_A12_plus_Ramdisk | **Live** tethered SSH + `mount_ich` on 18.7.5 XR |
| 15.1 hsbugss ramdisk | Historical; Data exit 76 |
| checkm8 / palera1n | Knowledge only on A12/18.7.5 |
| kexploit / Dopamine / LARA | Study only — **not wired** to boot |

Full index: [RESEARCH.md](RESEARCH.md)

## Phases
### A — Device ground truth
- [x] 15.1 inventory locked (Data exit 76)
- [x] ICH Mac path: SSH + System/Data mounts on 18.7.5 XR (2026-08-01 night)
- [ ] Userspace bootstrap / Sileo on clean lab phone — **not done**

### B — Lumina monorepo
- [x] Repo layout, STATUS, lab scripts, UDID guards

### C — Kexploit study (isolated)
- [x] Notes / matrices under `research/kexploit/`
- **No matching public primitive for A12 / 18.7.5** — teachers, not installers

## Next (user choice)
1. Treat XR as clean lab phone for bootstrap / Sileo / tethered JB research, **or**
2. Document “ramdisk SSH works on 18.7.5 XR” and pause
3. Stay on Mac/ICH for boot+SSH; do not chase Windows iBEC-go for ramdisk use
4. Kernel RE teachers remain optional background (`research/kexploit/`)
