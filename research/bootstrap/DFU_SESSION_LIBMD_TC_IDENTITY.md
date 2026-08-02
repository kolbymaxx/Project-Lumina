# libmd TC identity — boot path + entry encoding (E1/E3/E4)

**Date:** 2026-08-02  
**Device context:** XR · 18.7.5 / 22H311 · ECID `00117540340B002E`  
**Scope:** Host-only. No DFU, no new deps, no `ldid -S`, no mass append.

---

## E1 / E3 — Boot path identity

`boot.sh` loads exactly:

```bash
irecv -f "$BOOTCHAIN/trustcache.img4"
irecv -c firmware
```

With `env.sh` / `.last_bootchain`:

| Field | Value |
|-------|--------|
| `BOOTCHAIN_NAME` | `n841ap-18.7.5-22H311-ramdisk` |
| Absolute path | `/Users/kolby/Projects/ICH_A12_plus_Ramdisk/bootchain/n841ap-18.7.5-22H311-ramdisk/trustcache.img4` |
| Symlink? | **no** |
| Size | **17909** bytes |
| mtime | **2026-08-02 16:53:07** (libmd Phase-1 wrap) |
| img4 sha256 | `c50982fda063a0903daad1af139a119cd6b58bd37015f4cf9ceb339ef954575b` |
| Type | IMG4 · **rtsc** |
| Payload entry count | **474** |
| `ff08beac17621c17bf5f1dca0ccb1cf696f24fd5` present? | **Y** |

Last diag boot log: `Booting: n841ap-18.7.5-22H311-ramdisk` → `Loading trustcache...` → `bootx`.

### Stale / alternate paths (not booted)

| Path | Role |
|------|------|
| `bootchain/trustcache.after.bin` | Leftover raw blob under `bootchain/` — **not** referenced by `boot.sh` |
| `work/lumina-b005-*/trustcache*.bin` | Lab backups / intermediates only |
| Other `trustcache.img4` under Projects | **none** found |

**E1/E3 conclusion:** Boot path is correct. No stale-img4 mismatch to fix. The file we parse is the file `boot.sh` sends.

---

## E4 — Entry encoding vs cleared lib

Payload layout (trustcache **v1**):

```text
u32 version = 1
16-byte uuid = 1E71BE81-D3CC-4388-BC0B-C1CC28EBD664
u32 count = 474
474 × entries of 22 bytes = { 20-byte CDHash, u8 flags=0x02, u8 cat=0x00 }
```

`trustcache info` shows all of these as `HASH [none] [2]`.

| Entry | Index | Hash | Trailer (`rest`) |
|-------|-------|------|------------------|
| libzstd (cleared) | 10 | `09087fa3…` | `02 00` |
| liblzma (cleared) | 138 | `50569d20…` | `02 00` |
| libz-ng (cleared) | 209 | `75f20eb6…` | `02 00` |
| dpkg (cleared) | 445 | `f223c262…` | `02 00` |
| **libmd (fails)** | **473 (last)** | `ff08beac…` | `02 00` |

Trailer histogram: **all 474 entries** use `0200`. Flags/category encoding for libmd **matches** cleared libs.

### Difference that matters: sort order

Hash list is sorted **except one inversion**:

```text
[472] ff7a1a0c0ebe4d4a98400bad6da6ca01415e66c
[473] ff08beac17621c17bf5f1dca0ccb1cf696f24fd5   ← out of order (should be before ff7a…)
```

| Check | Result |
|-------|--------|
| Full-list inversions | **1** (only libmd) |
| libmd actual index | 473 |
| libmd sorted index | **472** |
| dpkg / libz-ng / liblzma / libzstd | each at correct sorted index, locally ordered |

`trustcache append` left libmd at the **tail** instead of inserting in sort order. Cleared appends landed sorted.

Kernel static-TC lookup is consistent with **binary search** on a sorted CDHash array → an unsorted last entry is a **lookup miss** even though a linear scan of the file finds the bytes.

---

## Conclusion

| Question | Answer |
|----------|--------|
| Which `trustcache.img4` is booted? | `…/bootchain/n841ap-18.7.5-22H311-ramdisk/trustcache.img4` (only img4; path correct) |
| Hash present in that payload? | **Y** |
| Entry flags/type vs cleared lib? | **Identical** (`02 00`) |
| Encoding/layout bug? | **Yes — sort order** (sole inversion = libmd) |

**Recommendation: fix entry encoding (sort order)** — re-insert/re-sort so `ff08beac…` sits at sorted index 472, rebuild `rtsc`, one DFU, one `dpkg --version`.  
Not “fix boot path.” Not “move to CS-blob/page-hash (F)” until after a sorted-TC retest.

**Do not** append more deps until this retest.

---

## Sort fix — Phase 1 host (2026-08-02)

| Field | Before | After |
|-------|--------|-------|
| Entry count | 474 | **474** |
| Inversions | 1 | **0** |
| `ff08beac…` index | 473 (tail) | **472** |
| Neighbors | `ff7a…` then `ff08…` | `fee4…` · **`ff08…`** · `ff7a…` |
| Trailer bytes | unchanged (`02 00`) | unchanged |
| img4 size | 17909 | **17909** |
| Backup | — | `work/lumina-b005-libmd-sort/trustcache.img4.pre-sort` |
| New img4 sha256 | `c50982fd…` | `8d6dec53c8557bca12cac38ce0b2369085a1d3a2e73892fb51e9dd8a306017c0` |

**Status:** Phase 1 ready — ping PWND for libmd retest.
