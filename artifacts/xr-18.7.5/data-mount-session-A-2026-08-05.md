# Data mount Session A — 2026-08-05

**Status:** **CLOSED** (2026-08-05, Prompt C)  
**Not** a successful Data mount. **Not** exit-76 reconfirm.

## Closed verdict (Prompt C)

- SSH worked; System path usable (`disk1s1` → `/mnt1`, **18.7.5 / 22H311**).
- Data mount **hung** (no `DATA_RC`); interrupted (Ctrl-C).
- On-device `disk1s8` check **skipped** — session closed; Mac host commands are invalid for this probe.
- **Not** exit **76**. Data = **block / SEP-keybag class**, not “retry `mount_apfs`.”
- **No more mounts this pass.** No `seputil` / RW / 16.0 tonight.

## Observed (ramdisk SSH)

- SSH eventually as `root@localhost` (password retries noted)
- `/mnt1/System/Library/CoreServices/SystemVersion.plist` — **missing** (System not mounted)
- `mount_apfs` present: symlink → `../System/Library/Filesystems/apfs.fs/mount_apfs`
- `apfs.util` at Contents/Resources path — **missing**
- `seputil` — **missing**
- `/dev/disk0s1s2`, `/dev/disk0s1s8` — **missing**
- Data/s8 mount attempts → **RC 66** (`volume could not be mounted: No such file or directory`)

## Interpretation

Bare ramdisk session without Phase A NAND mount map. RC **66** ≠ Phase A RC **76**.

Next: Session A0/A1 in [`../../research/DATA_MOUNT_LIVE_PLAN.md`](../../research/DATA_MOUNT_LIVE_PLAN.md).

## A0 partial (same session)

- `/mnt1`…`/mnt7`: empty mountpoint dirs only (`/mnt1/private` present; no System tree)
- `mount_apfs` binary: `/System/Library/Filesystems/apfs.fs/mount_apfs` (72960 bytes)
- Note: a later paste accidentally re-entered prior `ls` output as shell commands (`total:` / `drwx…` → command not found). Ignore; re-run the two inventory commands only.

## A0 complete (2026-08-05)

```
mount:
  /dev/md0 on / (apfs, local, read-only, journaled, noatime)
  devfs on /dev

/dev/disk*:
  disk0, disk0s1
  disk1, disk1s1 .. disk1s8
  disk2
```

**Layout note:** NAND looks like **≥16-style `disk1s*`** (SSHRD naming), **not** Phase A `disk0s1s*`.  
Root ramdisk is **APFS** `/dev/md0` (Phase A note said 15.1 HFS — this session may be a newer/different payload; record, do not assume 19B5042h).

Missing nodes `disk0s1s2`/`s8` → RC66 explained. Next: mount **`disk1s1` → `/mnt1` RO** and identify roles before Data.

## A1′ result — System OK on `disk1s1`

- `mount_apfs -o rdonly /dev/disk1s1 /mnt1` → **SYS_RC:0**
- ProductVersion **18.7.5**, ProductBuildVersion **22H311**

## A2′ result — Data hang (not exit 76)

- `mount_apfs -o rdonly /dev/disk1s2 /mnt2` → **hung** (no `DATA_RC:`; operator **Ctrl-C** ×2)
- `disk1s8` mount **not observed** (blocked behind hung `s2` command)
- Distinct from Phase A **exit 76** (`Program version wrong` on `disk0s1s*` / 15.1 tools)

Interpretation: on this ramdisk/`disk1s*` map, Data RO did not fail-fast with version skew; it **blocked**. Closed as **SEP/keybag-class blocker** (not tool-version retry). System RO still OK.

**Session closed** — s8 deferred; no further mounts / seputil / RW / 16.0 in this pass.
