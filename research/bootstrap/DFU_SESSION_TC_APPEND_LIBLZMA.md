# DFU session — B005-family scoped dep TC append (liblzma)

**Date:** 2026-08-02  
**Device:** iPhone XR (N841AP / T8020) · ECID `00117540340B002E`  
**Expected OS:** 18.7.5 / 22H311  

## Hypothesis

Append `liblzma.5.dylib` CDHash to the same static `rtsc` → dyld passes that load; either `dpkg` runs or the next `@rpath` jb lib fails the same way.

## Falsifier

Still dies on `liblzma` after append (wrong hash/bytes/path), or regress to **137**.

## Scope lock

- Allowlist this pass: **`liblzma.5.dylib` only**
- Keep prior: dpkg + libz-ng
- **Not:** mass `/usr/lib`, `ldid -S`, B008, CVE

---

## Phase 1 — Host append

| Field | Value |
|-------|--------|
| Source path (device) | `/mnt2/root/jb/usr/lib/liblzma.5.dylib` (= `/var/jb/…`) |
| Host copy | `ICH…/work/lumina-b005-liblzma/liblzma.5.dylib` |
| Size | **192448** bytes |
| File SHA-256 | `b2f76be0cd76216a665fd0a3bab75a2947b83496344c74cc0c98374bcc7724eb` |
| CDHash sha256 | `50569d20f1331c3bdf5288387c1fc6941214f554` |
| TC file | `bootchain/n841ap-18.7.5-22H311-ramdisk/trustcache.img4` |
| Kept | dpkg `f223c262…`, libz-ng `75f20eb6…` |
| Appended | **liblzma only** |
| Entry count | **471 → 472** |
| Backup | `work/lumina-b005-liblzma/trustcache.img4.pre-liblzma` |
| Wrap | bootchain size **17865** |
| Round-trip | dpkg + libz-ng + liblzma present |

### `otool -L` liblzma (notes for following pass — not appended)

- `@rpath/libiosexec.1.dylib` (jb)
- `/usr/lib/libSystem.B.dylib` (system)

---

## Phase 2 — DFU re-pwn

| Field | Value |
|-------|--------|
| DFU PWND | **yes** — `PWND: usbliter8` · ECID `0x00117540340b002e` · MODE DFU |
| Boot | `BOOTCHAIN_NAME=n841ap-18.7.5-22H311-ramdisk ./boot.sh` → trustcache → `bootx` OK |
| Boot-args | unchanged |
| SSH | **yes** |
| mount_ich | **yes** — dpkg + liblzma present under `/mnt2/root/jb` |
| tmpfs `/private/var` | **yes** — `/sbin/mount_tmpfs -s 8M` |
| `/var/jb` → | `/mnt2/root/jb` |
| SSH after remap | **yes** |

---

## Phase 3 — one shot

```text
/var/jb/usr/bin/dpkg --version
dyld[88]: Library not loaded: @rpath/libzstd.1.dylib
  Referenced from: …/mnt2/root/jb/usr/bin/dpkg
  Reason: tried: '/var/jb/usr/lib/libzstd.1.dylib' (code signature invalid …)
Abort trap: 6
exit:134
```

| Field | Value |
|-------|--------|
| exit code | **134** |
| New error | **`libzstd.1.dylib` code signature invalid** (liblzma cleared) |
| Next RO CDHash | `libzstd.1.dylib` → `09087fa384fbb2ab96f020e785483b2c661dc6ef` |

---

## Result table

| Field | Value |
|-------|--------|
| Hashes appended | dpkg + libz-ng + **liblzma** |
| TC file | `bootchain/n841ap-18.7.5-22H311-ramdisk/trustcache.img4` |
| Rebuild + DFU | **yes** |
| exit code | **134** |
| New error (if any) | `libzstd.1.dylib` CS invalid |
| Verdict | **Expected next dep** — liblzma TC hit. Stop append loop this session. Still ≠ Sileo / dpkg does not run. |

## Interpretation

- Hypothesis **supported for liblzma**: failure mode moved past `liblzma.5.dylib`.
- Falsifier for “still dies on liblzma” / regress-to-137: **not** triggered.
- Next scoped pass (later card): append **`libzstd.1.dylib`** CDHash `09087fa384fbb2ab96f020e785483b2c661dc6ef` only.
