# Lumina — Project Status (Fork 1 locked — 2026-08-05)

## Mission (Fork 1)

**Stay on iPhone XR A12 / iOS 18.7.5 (22H311).**  
Use tethered **usbliter8 + ramdisk SSH** as a **read-only lab** to map and verify
kernel reality. Later (only after a real primitive exists): port into a
Dopamine-style app/host.  

**We do NOT pursue Fork 2** (surrealra1n / downgrade).

Source of truth: [`../research/kexploit/FORK1_STRATEGY.md`](../research/kexploit/FORK1_STRATEGY.md) + this file.  
Lab snapshot: [`LAB_STATE.md`](LAB_STATE.md).

**Not a jailbreak.** No Sileo. No invented offsets. No “T008/T009 works” without citation.

## Device

| Field | Value |
|-------|--------|
| Device | iPhone XR (`n841ap`) |
| SoC | A12 (`t8020`), CPID 8020 |
| iOS / build | **18.7.5 / 22H311** |
| UDID | `00008020-00117540340B002E` |
| ECID | `00117540340B002E` |
| Serial (Recovery) | `F2LZJAE1KXKQ` |

## Already true

| Fact | State | Dated |
|------|--------|-------|
| Pwned DFU (usbliter8) | Yes | 2026-08-01 |
| iBSS → Recovery | Yes | 2026-08-01 |
| Ramdisk + root SSH (known-good Mac path) | Yes | 2026-08-01 |
| System `/mnt1` RO shows 18.7.5 / 22H311 | Yes | 2026-08-01 |
| Data mount | **FAIL** exit 76 | 2026-08-01 |
| Public kexploit for A12 / 18.7.5 | **None matching** | 2026-08-01 (matrix) |
| `research/` wired into `boot/` | **Never** | standing rule |

usbliter8 = **lab infrastructure only**, not a product JB path.

## Program state (2026-08-05)

| Item | State |
|------|--------|
| Active fork | **Fork 1** |
| Fork 2 (downgrade) | **Out of scope** |
| KRW / kexploit on 22H311 | **Missing** — hunt + RO map only |
| PPL | Blocked on missing KRW |
| Dopamine-style delivery | **Later** — after real primitive |
| Lumina IPA / DS-K sideload | Secondary scaffolding only (see `Lumina/`) — not Fork 1 priority |

### Evidence levels

| Claim | Level |
|-------|--------|
| BootROM → ramdisk SSH + System RO | **lab demonstrated** |
| No public matching kexploit | **literature** + matrix (no lab contradiction) |
| DarkSword PE fixed 18.7.2 | **literature** |
| Any live KRW on this XR | **none** |

## Phase A — volume inventory (locked 2026-08-01)

Ramdisk env: iOS **15.1** restore (`19B5042h`), root `/dev/md0` HFS **RO**.  
SSH: `alpine` via `iproxy 2222`.

| Node | Mount | Result | Notes |
|------|-------|--------|-------|
| `disk0s1s1` | `/mnt1` | **OK** RO | System — **18.7.5 / 22H311** |
| `disk0s1s5` | `/mnt4` | **OK** | Update → 22H311 |
| `disk0s1s6` | `/mnt6` | **OK** | Cryptex |
| `disk0s1s3` | `/mnt3` | **OK** RO | Preboot |
| `disk0s1s4` | `/mnt5` | **OK** RO | bbfs |
| `disk0s1s7` | `/mnt7` | **OK** RO | FactoryData |
| `disk0s1s2` | — | **FAIL** 76 | Data |
| `disk0s1s8` | — | **FAIL** 76 | same class |

Detail: [`../research/DATA_MOUNT_SSHRD.md`](../research/DATA_MOUNT_SSHRD.md),
[`../research/kexploit/22H311_NOTES.md`](../research/kexploit/22H311_NOTES.md).

## Blockers

1. **No matching public kernel primitive** for A12 / 18.7.5.  
2. **Data volume** still exit 76 on 15.1 `mount_apfs`.  
3. **PPL / bootstrap** blocked until KRW exists.  
4. Live USB lab requires **Mac + Pico + phone** (cloud = docs only).

## Docs map (Fork 1)

| Doc | Role |
|-----|------|
| [`../research/kexploit/FORK1_STRATEGY.md`](../research/kexploit/FORK1_STRATEGY.md) | Mission strategy |
| [`../research/kexploit/PUBLIC_PRIMITIVE_MATRIX.md`](../research/kexploit/PUBLIC_PRIMITIVE_MATRIX.md) | Public primitive status |
| [`../research/kexploit/HUNT_LOOP.md`](../research/kexploit/HUNT_LOOP.md) | Candidate intake process |
| [`../research/kexploit/22H311_NOTES.md`](../research/kexploit/22H311_NOTES.md) | Offline kernelcache probes |
| [`RESEARCH.md`](RESEARCH.md) | Broader index |
| [`BUILD_22H311.md`](BUILD_22H311.md) | Build identity |
| [`PPL.md`](PPL.md) | Blocked until KRW |
| `boot/lumina-boot.sh` | Known-good ramdisk re-entry (**infra**) |

DS-K / Lumina IPA docs remain in-tree for later delivery experiments; they do
**not** override Fork 1.

## Evidence log (append-only, dated)

| Date | Kind | Note |
|------|------|------|
| 2026-08-01 | lab | Phase A ramdisk inventory locked |
| 2026-08-05 | docs | **Fork 1 locked** — strategy file + STATUS rewrite; Fork 2 rejected |
| 2026-08-05 | offline RE | `probe_22h311_kernelcache.sh` dry-run + live abort — kernelcache **MISSING** on agent host; paths listed in `artifacts/xr-18.7.5/kernelcache-ro/MISSING_PATHS.txt`; **no CVE-working claim** |

## Single next human action (RO)

**Mac + Pico + XR — reconfirm identity over ramdisk SSH (read-only):**

```bash
# After known-good: Pico-pwn → phone direct to Mac → ./boot/lumina-boot.sh
./boot/lumina-ssh.sh
```

On device:

```sh
cat /mnt1/System/Library/CoreServices/SystemVersion.plist
```

Expect ProductVersion **18.7.5**, ProductBuildVersion **22H311**.  
Paste output here → we date it in this log. **No writes. No exploit attempts.**

Optional same session (still RO): offline kernelcache Probe 1–3 from
[`../research/kexploit/22H311_NOTES.md`](../research/kexploit/22H311_NOTES.md) on the Mac.

## Attract (one line)

Looking for a **citable** A12 / 18.7.5 kernel primitive (or proof none remains);
we have usbliter8→ramdisk RO lab on XR **22H311** and clean negative public-matrix results — no downgrade fork.
