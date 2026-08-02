# DFU session — B005 build-time trustcache append (dpkg)

**Date:** 2026-08-02  
**Device:** iPhone XR (N841AP / T8020) · ECID `00117540340B002E`  
**Expected OS:** 18.7.5 / 22H311  

## Hypothesis
Build-time trustcache membership is why ramdisk/system bash lives and `/var/jb` `dpkg` dies.

## Falsifier
After TC append + full DFU re-pwn + `/var/jb` remap, `/var/jb/usr/bin/dpkg --version` still exits **137**.

---

## Phase 1 — CDHash of exact on-device bytes

| Field | Value |
|-------|--------|
| Source path (device) | `/mnt2/root/jb/usr/bin/dpkg` |
| Host copy hashed/appended | `ICH_A12_plus_Ramdisk/work/lumina-b005/dpkg` |
| Size | **295296** bytes |
| File SHA-256 | `05ea171c6e43ed79245c1249559c5885fb5420d0ec374af71a1d17bb9a6016f7` |
| CDHash sha256 (ldid / CS) | `f223c26287b8acc9057ef74d109a07b171857dc2` |
| CandidateCDHashFull sha256 | `f223c26287b8acc9057ef74d109a07b171857dc286b25a140fc9aa97d5b7edbe` |
| CandidateCDHash sha1 | `69a1e0b5435a21d5e55be3567cdbf4f152ba9bcd` |

## Phase 2 — Append + install into bootchain TC

| Field | Value |
|-------|--------|
| Base TC | Extracted from `bootchain/n841ap-18.7.5-22H311-ramdisk/trustcache.img4` → `work/lumina-b005/trustcache.bin` (entry count **469**) |
| Tool | `ICH…/tools/darwin/trustcache append` |
| Command | `trustcache append work/lumina-b005/trustcache.after.bin work/lumina-b005/dpkg` |
| After | entry count **470**; raw CDHash `f223c262…` present in blob |
| Wrap | `img4 -i trustcache.after.bin -o bootchain/…/trustcache.img4 -A -T rtsc -M resources/IM4M_0x8020` |
| Backup | `work/lumina-b005/trustcache.img4.pre-b005` |
| Rebuild OK | **yes** (TC artifact only; other payloads unchanged) |
| Sanity | Round-trip extract from bootchain `trustcache.img4` still contains `f223c262…` |

**TC append applied:** **yes** — `tools/darwin/trustcache append` → bootchain `trustcache.img4` (rtsc).

## Phase 3 — DFU re-pwn + boot

| Field | Value |
|-------|--------|
| DFU PWND | **yes** — `05ac:1227` · `PWND:[usbliter8]` · ECID match |
| Boot | Known-good ICH path; interrupted `boot.sh` mid-upload → continued Recovery payloads → `bootx` with B005 `trustcache.img4` |
| Boot-args | unchanged (`rd=md0 -v debug=0x14e serial=3 wdt=-1 keepsyms=1` family) |
| SSH after boot | **yes** (`iproxy 2222` · `root`/`alpine`) |

## Phase 4 — mount + `/var/jb` remap

| Field | Value |
|-------|--------|
| `mount_ich` | `/mnt1` System, `/mnt2` Data |
| Bootstrap | `.procursus_strapped` + `dpkg` present |
| tmpfs `/private/var` | **yes** (`mount_tmpfs -s 8M`) |
| SSH dirs | `empty`, `tmp`, `root`, `run`, `log`, `db` |
| `/var/jb` | → `/mnt2/root/jb` |
| SSH after remap | **yes** |

## Phase 5 — one shot

```text
/var/jb/usr/bin/dpkg --version
dyld[…]: Library not loaded: @rpath/libz-ng.2.dylib
  Referenced from: …/mnt2/root/jb/usr/bin/dpkg
  Reason: tried: '/var/jb/usr/lib/libz-ng.2.dylib' (code signature invalid …)
Abort trap: 6
exit:134
```

| Field | Value |
|-------|--------|
| dpkg exit code | **134** (Abort trap 6 / dyld) |
| Prior baseline (pre-B005) | **137** (Killed: 9) |

### Optional B007 (read-only, after shot)
Not fully re-captured this pass; failure already shows dyld CS reject on `libz-ng.2.dylib`.

---

## Result table

| Field | Value |
|-------|--------|
| CDHash used | `f223c26287b8acc9057ef74d109a07b171857dc2` |
| TC file updated | `bootchain/n841ap-18.7.5-22H311-ramdisk/trustcache.img4` |
| Rebuild OK | yes |
| DFU PWND | yes |
| SSH after boot | yes |
| `/var/jb` mapped | yes |
| dpkg exit code | **134** |
| Hypothesis | **inconclusive** (not 137; not 0) |

## Interpretation

- **Not falsified by the stated falsifier** (exit was not 137).
- **Not supported** as “dpkg runs” (exit not 0; no version banner).
- Failure mode **changed**: process gets past immediate SIGKILL into **dyld**, then dies because **`libz-ng.2.dylib` has invalid code signature** (dependency not in build-time TC / still rejected).
- Do **not** mass-append libraries in this session (hard limit). Next deliberate step (if pursued) would be a **scoped** follow-up card for required dylib CDHashes — not blind spam.
- Missing-primitive language for full Procursus still stands until `dpkg --version` prints cleanly; B005 alone did not deliver a package manager.

## Explicit non-claims

- Not Sileo / not a jailbreak  
- No mass `ldid`  
- No B008 boot-args change  
- No CVE / panic PoC  
