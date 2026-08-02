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

## Phase 1 — Host append (done; waiting PWND for Phase 2)

| Field | Value |
|-------|--------|
| Source path (device) | `/mnt2/root/jb/usr/lib/liblzma.5.dylib` (= `/var/jb/…`) |
| Host copy | `ICH…/work/lumina-b005-liblzma/liblzma.5.dylib` |
| Size | **192448** bytes |
| File SHA-256 | `b2f76be0cd76216a665fd0a3bab75a2947b83496344c74cc0c98374bcc7724eb` |
| CDHash sha256 | `50569d20f1331c3bdf5288387c1fc6941214f554` (reconfirmed on-device + append) |
| TC file | `bootchain/n841ap-18.7.5-22H311-ramdisk/trustcache.img4` |
| Kept | dpkg `f223c262…`, libz-ng `75f20eb6…` |
| Appended | **liblzma only** |
| Entry count | **471 → 472** |
| Backup | `work/lumina-b005-liblzma/trustcache.img4.pre-liblzma` |
| Wrap | `img4 -A -T rtsc -M resources/IM4M_0x8020` → bootchain size **17865** |
| Round-trip | dpkg + libz-ng + liblzma present |

### `otool -L` liblzma (notes for *following* pass — not appended)

- `@rpath/liblzma.5.dylib` (self)
- `@rpath/libiosexec.1.dylib` (jb — next-pass candidate)
- `/usr/lib/libSystem.B.dylib` (system — skip)

**Status:** Phase 1 ready — ping PWND for Phase 2.

---

## Phase 2 — DFU re-pwn

| Field | Value |
|-------|--------|
| DFU PWND | *(pending)* |
| Boot | |
| SSH | |
| mount + `/var/jb` | |

---

## Phase 3 — one shot

```text
(pending)
```

| Field | Value |
|-------|--------|
| exit code | |
| New error (if any) | |
| Verdict | |
