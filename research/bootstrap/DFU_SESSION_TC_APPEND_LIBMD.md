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
- Keep prior: dpkg + libz-ng + liblzma + libzstd
- **Not:** mass libs, `ldid -S`, B008

---

## Phase 1 — Host append

| Field | Value |
|-------|--------|
| Intended CDHash | `ff08beac17621c17bf5f1dca0ccb1cf696f24fd5` |
| TC file | `bootchain/n841ap-18.7.5-22H311-ramdisk/trustcache.img4` |
| Entry count | **473 → 474** |
| Hash present in boot TC | **yes** — `ff08beac…` (round-trip `from-img4.bin`) |
| Backup | `work/lumina-b005-libmd/trustcache.img4.pre-libmd` |
| Boot TC size | **17909** |

### Host-copy anomaly (post-shot diagnosis)

| Artifact | Size | CDHash (`ldid -h`) |
|----------|------|---------------------|
| On-device `/mnt2/root/jb/usr/lib/libmd.0.dylib` | **88960** | `ff08beac17621c17bf5f1dca0ccb1cf696f24fd5` |
| Host `work/…/libmd.0.dylib` (used/left after Phase 1) | **87696** (truncated) | `2b54a63e724f91a289cd9fb28c1386d49ba6b8fb` (adhoc) |
| Host `libmd.0.dylib.rescued` (fresh SCP after shot) | **88960** | `ff08beac…` |

Re-append test from host copies against `before.bin`:

- truncated → adds **`2b54a63e…`**
- rescued → adds **`ff08beac…`**

Boot `after.bin` / `from-img4` contain **`ff08beac…`**, not `2b54…`. So the booted TC matches the **on-device** CDHash even though the leftover host work file is truncated/wrong.

---

## Phase 2 — DFU + remap

| Field | Value |
|-------|--------|
| DFU PWND | **yes** — `PWND: usbliter8` · ECID `0x00117540340b002e` |
| Boot | `boot.sh` → trustcache → `bootx` OK |
| SSH | **yes** |
| mount_ich | **yes** |
| `/var/jb` → | `/mnt2/root/jb` |
| Files present | dpkg + libmd.0.dylib **yes** |

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
| New error | **still `libmd.0.dylib` CS invalid** (did **not** advance) |
| Next RO CDHash | n/a this pass — same blocker |

---

## Result table

| Field | Value |
|-------|--------|
| Hashes intended in TC | dpkg + libz-ng + liblzma + libzstd + **libmd `ff08beac…`** |
| Rebuild + DFU | **yes** |
| exit code | **134** |
| New error | still libmd CS invalid |
| Verdict | **Falsifier hit for “clears libmd”** — failure mode did **not** move past libmd. Not a simple “hash absent from TC” miss: `ff08beac…` is in the booted `rtsc` and matches live `ldid -h`. Stop append loop. |

## Interpretation

- Unlike libz-ng / liblzma / libzstd, adding this CDHash did **not** clear dyld’s CS reject.
- Host work tree has a truncated `libmd.0.dylib` (87696) that must **not** be reused for append; use `libmd.0.dylib.rescued` / re-SCP **88960** bytes.
- Safe next (new card only): re-verify bootchain TC entry + exact on-device bytes identity (size+sha256+CDHash) before any further dep; consider whether libmd’s CS blob/`flags` path differs. **Do not** mass-append remaining dpkg deps until libmd clears.

## Explicit non-claims

- Not Sileo / dpkg still does not run  
- No `ldid -S`  
- No further TC append this session  
