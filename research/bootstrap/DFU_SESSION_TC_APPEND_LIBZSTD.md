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

## Phase 1 — Host append (done; waiting PWND for Phase 2)

| Field | Value |
|-------|--------|
| Source path (device) | `/mnt2/root/jb/usr/lib/libzstd.1.dylib` (= `/var/jb/…`) |
| Host copy | `ICH…/work/lumina-b005-libzstd/libzstd.1.dylib` |
| Size | **546480** bytes |
| File SHA-256 | `9c4737762397d13d63300c6bd91231a362fad7b0dbf05bec27f0f2d72524c66d` |
| CDHash sha256 | `09087fa384fbb2ab96f020e785483b2c661dc6ef` (reconfirmed) |
| TC file | `bootchain/n841ap-18.7.5-22H311-ramdisk/trustcache.img4` |
| Kept | dpkg `f223c262…`, libz-ng `75f20eb6…`, liblzma `50569d20…` |
| Appended | **libzstd only** |
| Entry count | **472 → 473** |
| Backup | `work/lumina-b005-libzstd/trustcache.img4.pre-libzstd` |
| Wrap | bootchain size **17887** |
| Round-trip | dpkg + libz-ng + liblzma + libzstd present |

### `otool -L` libzstd (notes for *following* pass — not appended)

- `@rpath/libiosexec.1.dylib` (jb)
- `/usr/lib/libSystem.B.dylib` (system)

**Status:** Phase 1 ready — ping PWND for Phase 2.

---

## Phase 2 — DFU re-pwn

| Field | Value |
|-------|--------|
| DFU PWND | *(pending)* |
| Boot | |
| SSH / remap | |

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
