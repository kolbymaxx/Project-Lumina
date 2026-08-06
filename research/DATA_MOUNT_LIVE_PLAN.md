# Data mount — minimal live test plan (Fork 1)

**Date:** 2026-08-05  
**Scope:** tethered ramdisk SSH lab only. Not a kexploit. Not Fork 2.  
**Do not change** `boot/` or replace the known-good 15.1 payload until a session
proves a better Data result.

Background: [`DATA_MOUNT_SSHRD.md`](DATA_MOUNT_SSHRD.md), Phase A
[`../artifacts/xr-18.7.5/phase-a-2026-08-01.md`](../artifacts/xr-18.7.5/phase-a-2026-08-01.md)
— `disk0s1s2` / `disk0s1s8` exit **76** (`Program version wrong`) on **15.1**
`mount_apfs`.

---

## Which generation first?

| Step | Ramdisk / `mount_apfs` | Why |
|------|------------------------|-----|
| **A (do this first)** | **Current known-good 15.1** (`19B5042h`) via `./boot/lumina-boot.sh` | Reconfirm exit 76 + inventory tools. **Zero boot-path change.** |
| **B (only after A)** | **16.0 n841 restore** SSH ramdisk (HFS-era, newer APFS userspace) | Smallest documented step up per `DATA_MOUNT_SSHRD.md`. Boot as a **separate** payload experiment — do **not** overwrite `usbliter8-xr-ramdisk` defaults until proven. |
| C (later) | 18.x APFS restore | Only if B still exits 76. Larger host/build change. |
| D (later) | `seputil` / Preboot / xART staging | Only if errno is **no longer** “Program version wrong”. |

**Do not** run SEP/gigalocker/keybag steps in session A.  
**Do not** `mount_apfs` Data read-write. RO only.

---

## Session A — known-good path (run now)

### Mac (boot + SSH)
```bash
cd /Users/kolby/Projects/lumina
# Phone already PWND:[usbliter8] DFU, direct cable
./boot/lumina-boot.sh
./boot/lumina-ssh.sh
```

### Exact SSH commands (paste as one block or one-by-one)

```sh
# 0) identity — expect 18.7.5 / 22H311
cat /mnt1/System/Library/CoreServices/SystemVersion.plist

# 1) tool inventory
ls -l /sbin/mount_apfs 2>&1
ls -l /System/Library/Filesystems/apfs.fs/Contents/Resources/mount_apfs 2>&1
ls -l /System/Library/Filesystems/apfs.fs/Contents/Resources/apfs.util 2>&1
which seputil apfs.util mount_apfs 2>&1
ls /usr/sbin/seputil /sbin/seputil 2>&1

# 2) node presence (no write)
ls -l /dev/disk0s1s2 /dev/disk0s1s8 2>&1

# 3) Data + s8 RO mount attempts — expect exit 76 today
mkdir -p /mnt2 /mnt8
mount_apfs -o rdonly /dev/disk0s1s2 /mnt2; echo DATA_RC:$?
mount_apfs -o rdonly /dev/disk0s1s8 /mnt8; echo S8_RC:$?

# 4) optional role probe if apfs.util exists (read-only)
apfs.util -p /dev/disk0s1s2 2>&1; echo APFS_UTIL_S2:$?
apfs.util -p /dev/disk0s1s8 2>&1; echo APFS_UTIL_S8:$?
```

Via host one-shot (optional):
```bash
./boot/lumina-ssh.sh 'cat /mnt1/System/Library/CoreServices/SystemVersion.plist; ls -l /sbin/mount_apfs; ls -l /dev/disk0s1s2 /dev/disk0s1s8; mkdir -p /mnt2 /mnt8; mount_apfs -o rdonly /dev/disk0s1s2 /mnt2; echo DATA_RC:$?; mount_apfs -o rdonly /dev/disk0s1s8 /mnt8; echo S8_RC:$?'
```

### Success vs fail (Session A)

| Outcome | Meaning | Next |
|---------|---------|------|
| System still **18.7.5 / 22H311**; Data/`s8` **DATA_RC:76** / **S8_RC:76** with `Program version wrong` | Baseline **reconfirmed** | Proceed to plan Session B (16.0 tooling) offline; do not touch `boot/` |
| Data or s8 mounts (**RC:0**) RO | **New evidence** — paste full log; date `STATUS.md` / this plan | Stop; document; only then consider SEP staging as a *separate* RO plan |
| Different errno/string (not 76 / not “Program version wrong”) | Tooling vs keybag signal may have shifted — still not a claim of “unlocked Data” | Paste log; do **not** invent seputil steps until we write a Session B+/C plan |
| System identity wrong / SSH broken / known-good mounts missing | Lab regression | Stop; restore known-good path; do not continue Data trials |

### What to paste back
Full stdout/stderr of the SSH block, especially:
1. SystemVersion ProductVersion / ProductBuildVersion  
2. `ls -l` lines for `mount_apfs` / `apfs.util` / `seputil` (or “No such file”)  
3. `DATA_RC:` and `S8_RC:` lines + any `mount_apfs:` error text  
4. `apfs.util -p` output if the binary exists  

Save locally as e.g. `artifacts/xr-18.7.5/data-mount-session-A-YYYY-MM-DD.txt` (gitignored `*.txt` at that level is fine).

---

## Session B — 16.0 restore tools (gated; do not run until A is pasted)

**Goal:** retry Data RO with a **newer** `mount_apfs` while keeping the current
15.1 tree as the fallback known-good path.

1. Build/adapt a **16.0 n841** restore SSH ramdisk in a **separate directory**
   (do not replace `~/Projects/usbliter8-xr-ramdisk` in place).
2. Boot that payload only via an explicit one-off command (document the exact
   `usbliter8ctl` / image paths used) — **leave** `./boot/lumina-boot.sh`
   pointing at known-good until B succeeds.
3. On SSH, re-run the **same** mount block as Session A (nodes may become
   `disk1s*` on ≥16 ramdisks — re-probe with `ls /dev/disk*` and
   `apfs.util -p` before mounting; **do not** hardcode today’s `disk0s1s*`
   if the layout changed).
4. **Still no** `seputil` until errno leaves the version-skew class.
5. If B still **76** → document; next candidate is **18.x APFS** restore (Session C), not SEP folklore.

### Success vs fail (Session B)

| Outcome | Meaning |
|---------|---------|
| Data RO mounts (RC:0) | Tool-version gate cleared — date STATUS; *then* design RO SEP staging |
| Still 76 | 16.0 insufficient; need newer than 16.0 |
| New errno | Paste string; plan SEP/keybag A/B only after write-up |
| Boot/SSH fails | Abandon B payload; return to `./boot/lumina-boot.sh` known-good |

---

## Explicit non-goals this plan
- No kexploit, no panic PoCs, no Fork 2 / surrealra1n  
- No RW mounts, no user-data scrape claims  
- No wiring into `boot/` until a dated successful Data RO session exists  
- No claim of working A12 / 18.7.5 Data mount until Session A or B produces RC:0

---

## Session A result (2026-08-05) — **incomplete / wrong precondition**

Paste from live SSH (operator). Interpretation:

| Observation | Meaning |
|-------------|---------|
| `/mnt1/.../SystemVersion.plist` missing | **System not mounted** — not Phase A inventory state |
| `/dev/disk0s1s2` / `s8` missing | NAND nodes not at Phase A names (or not enumerated yet) |
| `DATA_RC:66` / `S8_RC:66` — `No such file or directory` | **Not** the Phase A exit **76** (`Program version wrong`) |
| `mount_apfs` symlink → `apfs.fs/mount_apfs` | Binary present |
| `apfs.util` / `seputil` missing at probed paths | Matches “absent on this ramdisk” class |

**Verdict:** Session A Data trial did **not** reconfirm exit 76. Lab is at bare ramdisk SSH without the Phase A mount map. Next: **Session A0** inventory below, then mount System RO only, then retry Data.

### Session A0 — disk / mount inventory (run next; RO)

```sh
mount
ls -la /dev/disk* 2>&1
ls -la /mnt1 /mnt2 /mnt3 /mnt4 /mnt5 /mnt6 /mnt7 /mnt8 2>&1
ls -l /System/Library/Filesystems/apfs.fs/mount_apfs 2>&1
/System/Library/Filesystems/apfs.fs/mount_apfs 2>&1 | head -5
```

### Session A1 — restore Phase A System mount only (RO; stop if fails)

Only after A0 shows a plausible System device (historically `/dev/disk0s1s1`):

```sh
mkdir -p /mnt1
mount_apfs -o rdonly /dev/disk0s1s1 /mnt1; echo SYS_RC:$?
cat /mnt1/System/Library/CoreServices/SystemVersion.plist
ls -la /dev/disk0s1s* 2>&1
```

If `disk0s1s*` are absent, **do not guess** — paste A0 `ls /dev/disk*` and stop.  
If System mounts and shows **18.7.5 / 22H311**, re-run Session A Data/s8 block from above.

### Session A0 result (2026-08-05) — NAND is `disk1s*`

Live paste: root `/dev/md0` **APFS** RO; devices `disk0`/`disk0s1`, **`disk1s1`–`disk1s8`**, `disk2`.  
No `disk0s1s*`. Phase A node names do **not** apply to this session.

### Session A1′ — System on `disk1s1` (RO only; run next)

```sh
mkdir -p /mnt1
mount_apfs -o rdonly /dev/disk1s1 /mnt1; echo SYS_RC:$?
cat /mnt1/System/Library/CoreServices/SystemVersion.plist
ls /mnt1 2>&1 | head
```

| SYS_RC / content | Next |
|------------------|------|
| 0 + **18.7.5 / 22H311** | Proceed A2′ Data RO on `disk1s2` (and note `disk1s8`) |
| 0 + other version | Paste plist — stop Data trials until identity clear |
| non-zero | Paste error — **do not** spray-mount all slices |

### Session A2′ — Data / s8 on `disk1s*` (only after A1′ OK)

```sh
mkdir -p /mnt2 /mnt8
mount_apfs -o rdonly /dev/disk1s2 /mnt2; echo DATA_RC:$?
mount_apfs -o rdonly /dev/disk1s8 /mnt8; echo S8_RC:$?
```

Expect for “same blocker, new nodes”: **76** + `Program version wrong`, or a **new** errno (paste exact string).  
Still **no** `seputil`. RO only.

### A2′ live result (2026-08-05) — Data **hung**

- System `disk1s1` → `/mnt1` **OK** (18.7.5 / 22H311).
- Data `disk1s2` → `/mnt2` **hung** until Ctrl-C; no `DATA_RC`.
- Not the Phase A fail-fast **76**. Treat as a **different** failure class pending short `s8` probe + later SEP/keybag plan.
- **Do not** leave `mount_apfs` on Data running indefinitely.
