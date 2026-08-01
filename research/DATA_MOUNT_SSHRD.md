# Data mount research — restore-ramdisk / SSHRD-style staging

**Docs only.** Process reference for unblocking `disk0s1s2` / `disk0s1s8`.
**No claim** of a working A12 / iOS **18.7.5** Data mount.

Live context (2026-08-01 XR ramdisk):
- Tooling: **iOS 15.1** restore (`19B5042h`) — HFS root `/dev/md0`
- System / Update / Cryptex / … mount OK
- Data `disk0s1s2` + `disk0s1s8`: `mount_apfs -o rdonly` → exit **76**
  (`Program version wrong`)

## What exit 76 implies here

Observed pattern (System OK, Data/s8 fail with the same string) matches public
guidance that **userspace APFS tools are version-skewed** relative to the
on-disk **iOS 16+** Data volume features — not a missing device node and not
yet a clean “crypto denied” signal.

Separately, public forensic / SSHRD writeups stress that **even with a matching
`mount_apfs`**, Data often still needs **SEP / gigalocker / keybag** staging
before a useful mount. Those steps cannot be validated on this XR until the
**tool-version** failure is cleared or replaced by a different errno.

## Public SSHRD-style flow (reference)

Sources (study only; A7–A11 / checkm8-era tooling — **not** drop-in for
usbliter8/A12 boot):

| Source | Role |
|--------|------|
| [verygenericname/SSHRD_Script](https://github.com/verygenericname/SSHRD_Script) | Build/boot SSH restore ramdisk from an IPSW version “close enough”; SEP must be compatible |
| [verygenericname/sshtars](https://github.com/verygenericname/sshtars) `usr/bin/mount_filesystems` | Canonical mount + `seputil` staging script dropped into the ramdisk |
| SSHRD issues #279 / #293 | iOS **17+** `mount_filesystems` often broken / incomplete; no clean public fix claimed |
| Elcomsoft (A11 / iOS 16) | Passcode-ever-set can hard-block Data unlock via checkm8-class paths |

### Ramdisk version notes (from SSHRD README / practice)

- Ramdisk iOS version need not equal the installed OS, but should be **close**;
  **SEP compatibility** is required.
- **≤16.0**: restore ramdisk still commonly **HFS+** (editable with classic
  hfsplus / older pipelines).
- **16.1+**: restore ramdisk switches to **APFS** — Mac `hdiutil` path; Linux
  SSHRD build path explicitly refuses 16.1+.
- Implication for Lumina: a **16.0 n841 restore** is the smallest step up that
  still resembles today’s HFS-based XR ramdisk pipeline; an **18.x APFS
  restore** is the closest tooling match but is a larger host/build change.

### `mount_filesystems` staging (sshtars, iOS ≥16 branch)

Documented logic (abbreviated; device nodes are **`disk1s*`** when the
*ramdisk’s* `sw_vers` major ≥ 16 — NAND is no longer `disk0`):

1. `mount_apfs` **System** → `/mnt1` (`disk1s1` or `disk0s1s1` on older)
2. Probe volumes with `apfs.util -p` for **Preboot** → `/mnt6`
3. Probe for **xART** → `/mnt7`, then `seputil --gigalocker-init`
4. `seputil --load` SEP firmware from `/mnt6/$(cat /mnt6/active)/…/sep-firmware.img4`
   (fallback: `/mnt1/usr/standalone/firmware/sep-firmware.img4`)
5. `mount_apfs` **Data** → `/mnt2` (`…s2`)

iOS ≤15 branch uses `disk0s1s*` and the same Preboot / xART / seputil / Data
order.

**Important:** SSHRD stages **SEP load before Data**. Our live session never
reached a useful comparison of that path for Data — direct `mount_apfs` on
`s2`/`s8` already failed with **program version wrong**.

### Manual “hello / iOS 16” variant (community issues)

Same idea, fixed node names (example from SSHRD issue threads; **disk numbering
varies**):

```text
mount_apfs -R <System>  /mnt1
mount_apfs -R <Preboot> /mnt6
mount_apfs -R <xART>    /mnt7
seputil --gigalocker-init
seputil --load $(find /mnt6 -iname sep-firmware.img4)
mount_apfs -R <Data>    /mnt2
```

Do **not** copy these node names onto the XR map blindly.

## Map against live XR 18.7.5 session

| Live node | Role this session | SSHRD analogue |
|-----------|-------------------|----------------|
| `disk0s1s1` `/mnt1` | System RO sealed **18.7.5 / 22H311** (OK) | System → `/mnt1` |
| `disk0s1s2` | Data (**exit 76**) | Data → `/mnt2` |
| `disk0s1s3` `/mnt3` | Preboot minimal (OK) | Preboot → `/mnt6` |
| `disk0s1s5` `/mnt4` | Update ota→**22H311** (OK) | (not in classic script) |
| `disk0s1s6` `/mnt6` | Cryptex active + cryptex1/current (OK) | **not** Preboot here |
| `disk0s1s7` `/mnt7` | FactoryData / Pearl (OK) | not xART |
| `disk0s1s8` | unlabeled; same exit 76 | unknown; treat as same failure class |

Phase A inventory locked 2026-08-01 — see
[../artifacts/xr-18.7.5/phase-a-2026-08-01.md](../artifacts/xr-18.7.5/phase-a-2026-08-01.md).

Live naming used `disk0s1s*` because the **15.1** ramdisk keeps the classic
layout. A **≥16** restore ramdisk would likely renumber NAND to `disk1s*` —
any future recipe must re-probe with `apfs.util -p`, not hardcode today’s
labels.

Also: our Preboot was `s3` and Cryptexes `s6`. Blindly mounting `s6` as
Preboot (as some copy-paste recipes do) is wrong for this layout.

## Public outcomes that matter (honesty)

| Claim class | Status |
|-------------|--------|
| Newer restore `mount_apfs` can clear **version-skew** failures | Plausible; **not proven** on this XR |
| SSHRD `seputil` staging required for Data after tools match | Documented for A11-era SSHRD; **not proven** on A12/18.7.5 |
| A12 + 18.7.5 Data mount via usbliter8 ramdisk | **No public working claim; we have none** |
| iOS 17+ SSHRD Data mount | Frequently broken in upstream issues; not a ready recipe |
| Passcode / keybag hard limits | Real on modern iOS forensic literature; orthogonal until exit 76 clears |

## Ordered next experiments (human / future session)

Do **not** wire into `boot/` until a session proves mounts.

1. **Inventory current tools** (still on 15.1 ramdisk):  
   `ls -l /sbin/mount_apfs /System/Library/Filesystems/apfs.fs/...`;  
   note presence/absence of `apfs.util`, `seputil`.
2. **Build a 16.0 n841 restore SSH ramdisk** (HFS-era, newer APFS userspace):  
   boot via existing usbliter8 path if images can be adapted; retry  
   `mount_apfs -o rdonly` on Data **before** any seputil steps.  
   - If still exit **76** → need newer than 16.0 (likely 18.x APFS ramdisk).  
   - If errno **changes** → record string; proceed to (3).
3. **SSHRD-style SEP staging** only after (2) leaves the version-skew class:  
   identify Preboot + xART with `apfs.util -p`, then gigalocker-init +  
   `seputil --load`, then Data again.
4. **18.x APFS restore ramdisk** (Mac host): closest `mount_apfs` to 22H311;  
   expect APFS ramdisk packaging differences vs today’s 15.1 HFS pipeline.
5. **Keybag variables** (unlock-before-DFU vs cold) only as a controlled A/B  
   after tools are new enough that the failure is no longer “Program version
   wrong”.

### Exit criteria (unchanged)

Documented session where `mount_apfs -o rdonly` on Data succeeds **or** clear
evidence the remaining blocker is keybag/SEP (not tool version).  
**Neither is done.**

## Explicit non-claims

- Not a working A12 / 18.7.5 Data mount
- Not Data R/W, not decrypted user files, not Sileo
- Not “run SSHRD_Script on XR” as a supported path
- Boot scripts remain untouched by this note

## See also

- [kexploit/22H311_NOTES.md](kexploit/22H311_NOTES.md) — live APFS map + exit-76 notes
- [../docs/ROADMAP_THEORY.md](../docs/ROADMAP_THEORY.md) — Stage A
- [../docs/STATUS.md](../docs/STATUS.md)
- [../tools/mount_from_ramdisk.sh](../tools/mount_from_ramdisk.sh) — current stub (Data gated)
