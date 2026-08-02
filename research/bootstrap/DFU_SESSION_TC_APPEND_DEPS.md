# DFU session — B005-family scoped dep TC append (libz-ng)

**Date:** 2026-08-02  
**Device:** iPhone XR (N841AP / T8020) · ECID `00117540340B002E`  
**Expected OS:** 18.7.5 / 22H311  

## Hypothesis

Authorizing **direct load deps** of `dpkg` (starting with `libz-ng.2.dylib`) in the **same static `rtsc`** lets dyld proceed past Abort 6.

## Falsifier

After append + full DFU re-pwn + remap, `dpkg` still dies before printing version (any non-zero / trap), **or** failure mode does not move past `libz-ng`.

## Scope lock

- Allowlist this pass: **`libz-ng.2.dylib`** only (host Phase 2).  
- **Not** this pass: mass `/usr/lib`, `ldid -S`, B008, CVE, Sileo, B006 redo, further appends after the one shot.

---

## Phase 1 — Exact bytes + CDHash

| Field | Value |
|-------|--------|
| Source path (device) | `/mnt2/root/jb/usr/lib/libz-ng.2.dylib` (= `/var/jb/…` via symlink) |
| Host copy | `ICH…/work/lumina-b005-deps/libz-ng.2.dylib` |
| Size | **173216** bytes |
| File SHA-256 | `4d12e14973246f3ded8b5ca192070d47d120dda26999b9f4565adf188963fba5` |
| CDHash sha256 | `75f20eb66d22dd52862f34ee25bb6a7b004730ea` |
| CandidateCDHashFull sha256 | `75f20eb66d22dd52862f34ee25bb6a7b004730eaeb8f57ef7de1a6a8b8fc4678` |
| CandidateCDHash sha1 | `1c2154ca1f4267d8ff3505cb8cd1e8df93dc92b6` |
| `otool -L` dpkg (host B005 copy) | CF, CoreServices, `@rpath/libz-ng.2.dylib`, `@rpath/liblzma.5.dylib`, `@rpath/libzstd.1.dylib`, libbz2 (system), `@rpath/libmd.0.dylib`, `@rpath/libintl.8.dylib`, `@rpath/libiosexec.1.dylib`, libSystem |
| `otool -L` libz-ng | `@rpath/libz-ng.2.dylib`, `@rpath/libiosexec.1.dylib`, `/usr/lib/libSystem.B.dylib` |
| Extra jb deps appended | **none** (`libiosexec` noted earlier; not in this allowlist) |

---

## Phase 2 — Append + rebuild (HOST ONLY)

| Field | Value |
|-------|--------|
| TC file | `bootchain/n841ap-18.7.5-22H311-ramdisk/trustcache.img4` |
| Keep dpkg hash | **yes** (`f223c262…`) |
| Appended | **libz-ng only** · `75f20eb66d22dd52862f34ee25bb6a7b004730ea` |
| Entry count before → after | **470 → 471** |
| Backup | `work/lumina-b005-deps/trustcache.img4.pre-deps` |
| Wrap / rebuild | **yes** — size **17843** |
| Sanity | round-trip: dpkg + libz-ng present |

---

## Phase 3 — DFU re-pwn

| Field | Value |
|-------|--------|
| DFU PWND | **yes** — `05ac:1227` · `PWND: usbliter8` · ECID `0x00117540340b002e` |
| Boot | `BOOTCHAIN_NAME=n841ap-18.7.5-22H311-ramdisk ./boot.sh` → trustcache → ramdisk → kernel → `bootx` OK |
| Boot-args | unchanged (`rd=md0 -v debug=0x14e serial=3 wdt=-1 keepsyms=1`) |
| SSH | **yes** (`iproxy 2222` · `root`/`alpine`) |

---

## Phase 4 — mount + `/var/jb`

| Field | Value |
|-------|--------|
| mount_ich | **yes** — `/mnt1` System, `/mnt2` Data |
| dpkg + libz-ng present | **yes** under `/mnt2/root/jb` |
| tmpfs `/private/var` | **yes** — `/sbin/mount_tmpfs -s 8M` |
| SSH dirs | `empty`, `tmp`, `root`, `run`, `log`, `db` |
| `/var/jb` → | `/mnt2/root/jb` |
| SSH after remap | **yes** |

---

## Phase 5 — one shot

```text
/var/jb/usr/bin/dpkg --version
dyld[126]: Library not loaded: @rpath/liblzma.5.dylib
  Referenced from: …/mnt2/root/jb/usr/bin/dpkg
  Reason: tried: '/var/jb/usr/lib/liblzma.5.dylib' (code signature invalid …)
Abort trap: 6
exit:134
```

| Field | Value |
|-------|--------|
| exit code | **134** |
| New error | **`liblzma.5.dylib` code signature invalid** (libz-ng no longer the blocker) |

---

## Result table

| Field | Value |
|-------|--------|
| Hashes appended | dpkg + **libz-ng** (this pass) |
| TC file | `bootchain/n841ap-18.7.5-22H311-ramdisk/trustcache.img4` |
| Rebuild + DFU | **yes** |
| exit code | **134** |
| New error (if any) | `liblzma.5.dylib` CS invalid |
| Verdict | **Expected next dep** — libz-ng TC hit; failure mode moved past libz-ng. `dpkg` still does not run. Stop append loop this session. |

## Interpretation

- Hypothesis **supported for libz-ng**: authorizing that CDHash in static `rtsc` cleared the prior Abort-6 on `libz-ng.2.dylib`.
- Falsifier for “dpkg prints version” still holds (exit 134).
- Not a TC miss on libz-ng / wrong bytes.
- Next scoped pass (later card only): append **`liblzma.5.dylib`** CDHash `50569d20f1331c3bdf5288387c1fc6941214f554` (on-device RO this session) — not mass libs. Remaining dpkg `@rpath` deps after that likely include `libzstd`, `libmd`, `libintl`, `libiosexec`.

## Explicit non-claims

- Not Sileo / not a working package manager  
- No mass `/usr/lib` TC append this session  
- No `ldid -S`  
