# DFU session — B005-family scoped dep TC append (libzstd)

**Date:** 2026-08-02  
**Device:** iPhone XR (N841AP / T8020) · ECID `00117540340B002E`  
**Expected OS:** 18.7.5 / 22H311  

## Hypothesis

Append `libzstd.1.dylib` CDHash to the same static `rtsc` → dyld passes that load; either `dpkg` runs or the next `@rpath` jb lib fails the same way.

## Falsifier

Still dies on `libzstd` after append (wrong hash/bytes/path), or regress to **137**.

## Scope lock

- Allowlist this pass: **`libzstd.1.dylib` only**
- Keep prior: dpkg + libz-ng + liblzma
- **Not:** mass `/usr/lib`, `ldid -S`, B008, CVE

---

## Phase 1 — Host append

| Field | Value |
|-------|--------|
| Source path (device) | `/mnt2/root/jb/usr/lib/libzstd.1.dylib` |
| Host copy | `ICH…/work/lumina-b005-libzstd/libzstd.1.dylib` |
| Size | **546480** bytes |
| File SHA-256 | `9c4737762397d13d63300c6bd91231a362fad7b0dbf05bec27f0f2d72524c66d` |
| CDHash sha256 | `09087fa384fbb2ab96f020e785483b2c661dc6ef` |
| TC file | `bootchain/n841ap-18.7.5-22H311-ramdisk/trustcache.img4` |
| Kept | dpkg + libz-ng + liblzma |
| Appended | **libzstd only** |
| Entry count | **472 → 473** |
| Backup | `work/lumina-b005-libzstd/trustcache.img4.pre-libzstd` |
| Wrap | bootchain size **17887** |

---

## Phase 2 — DFU re-pwn

| Field | Value |
|-------|--------|
| DFU PWND | **yes** — `PWND: usbliter8` · ECID `0x00117540340b002e` |
| Boot | `boot.sh` → trustcache → `bootx` OK |
| SSH | **yes** |
| mount_ich | **yes** |
| tmpfs `/private/var` | **yes** |
| `/var/jb` → | `/mnt2/root/jb` |
| SSH after remap | **yes** |

---

## Phase 3 — one shot

```text
/var/jb/usr/bin/dpkg --version
dyld[89]: Library not loaded: @rpath/libmd.0.dylib
  Referenced from: …/mnt2/root/jb/usr/bin/dpkg
  Reason: tried: '/var/jb/usr/lib/libmd.0.dylib' (code signature invalid …)
Abort trap: 6
exit:134
```

| Field | Value |
|-------|--------|
| exit code | **134** |
| New error | **`libmd.0.dylib` code signature invalid** (libzstd cleared) |
| Next RO CDHash | `libmd.0.dylib` → `ff08beac17621c17bf5f1dca0ccb1cf696f24fd5` |

---

## Result table

| Field | Value |
|-------|--------|
| Hashes appended | dpkg + libz-ng + liblzma + **libzstd** |
| Rebuild + DFU | **yes** |
| exit code | **134** |
| New error | `libmd.0.dylib` CS invalid |
| Verdict | **Expected next dep** — libzstd TC hit. Stop this session. Still ≠ Sileo. |

## Interpretation

- libzstd authorized; failure mode advanced.
- Next scoped pass (later): append **`libmd.0.dylib`** CDHash `ff08beac17621c17bf5f1dca0ccb1cf696f24fd5` only.
