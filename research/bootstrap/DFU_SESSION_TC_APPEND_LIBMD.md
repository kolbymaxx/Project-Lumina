# DFU session — B005-family scoped dep TC append (libmd)

**Date:** 2026-08-02  
**Device:** iPhone XR (N841AP / T8020) · ECID `00117540340B002E`  
**Expected OS:** 18.7.5 / 22H311  

## Hypothesis

Append `libmd.0.dylib` CDHash to the same static `rtsc` → dyld passes that load; either `dpkg` runs or the next `@rpath` jb lib fails the same way.

## Falsifier

Still dies on `libmd` after append (wrong hash/bytes/path), or regress to **137**.

## Scope lock

- Allowlist: **`libmd.0.dylib` only**
- Keep: dpkg + libz-ng + liblzma + libzstd
- **Not:** mass libs, `ldid -S`, B008

---

## Phase 1 — Host append (done)

| Field | Value |
|-------|--------|
| CDHash sha256 | `ff08beac17621c17bf5f1dca0ccb1cf696f24fd5` (from prior on-device `ldid -h`; size then **88960**) |
| Method | Device was **not** USB/SSH during this host pass (bootstrap tar had **different** bytes/CDHash — rejected). Appended **verified CDHash** into v1 `rtsc` blob (22-byte entry, flags `02 00` matching prior jb entries) then `img4 -A -T rtsc -M IM4M_0x8020`. |
| TC file | `bootchain/n841ap-18.7.5-22H311-ramdisk/trustcache.img4` |
| Kept | dpkg + libz-ng + liblzma + libzstd |
| Entry count | **473 → 474** |
| Backup | `work/lumina-b005-libmd/trustcache.img4.pre-libmd` |
| Wrap size | **17909** |
| Round-trip | all five hashes present; `trustcache info` lists `ff08beac…` |

**Status:** Phase 1 ready. **PWND not on bus after host work** — need fresh DFU for Phase 2.

---

## Phase 2 — DFU re-pwn

| Field | Value |
|-------|--------|
| DFU PWND | *(pending re-pwn — lost during/after Phase 1)* |
| Boot / SSH / remap | |
| one shot | |

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
