# AMFI / trustcache on ICH A12 ramdisk (iOS 18.7.5 / 22H311)

**Scope:** tethered ICH SSH ramdisk session only (n841ap). Not DarkSword, not A12X, not SpringBoard JB.  
**Date measured:** 2026-08-02.  
**Verdict:** **NO-GO** for running Procursus `$JBROOT` binaries (`dpkg`) via `ldid` or any *live* trustcache inject in this session.

---

## 1. How enforcement looks in this session

### Measured process death
| Experiment | Result |
|------------|--------|
| `/bin/bash` (ramdisk) | runs |
| `cp /bin/bash /mnt2/tmp/b1` (CDHash unchanged) | runs |
| same copy after any `ldid -S` / `-P` / `-Cadhoc` | **Killed: 9** |
| `/var/jb` → `/mnt2/root/jb` (tmpfs + symlink) | path OK; dpkg still **137** |
| batch `ldid` + `platform.plist` on JBROOT | still **Killed: 9** |

So AMFI (or a peer CS policy) is **not** “missing entitlements.” Rewriting the code signature changes the CDHash; the new hash is rejected and the process is SIGKILL’d.

### Live sysctls (ramdisk SSH)
```text
security.codesigning.trustcaches.num_static: 1
security.codesigning.trustcaches.num_engineering: 0
security.codesigning.trustcaches.num_loadable: 0
security.codesigning.monitor: 1
security.mac.amfi.trust_cache_interface: 3
security.mac.amfi.developer_mode_status: 0
security.mac.amfi.launch_constraints_enforced: 1
security.mac.amfi.launch_constraints_3rd_party_allowed: 0
kern.bootargs: rd=md0 -v debug=0x2014e
```

Implications:
- **No loadable trustcache slot** (`num_loadable: 0`) → nothing in-session can `load` a new trustcache blob the way newer “loadable TC” paths do.
- **Launch constraints enforced** on this kernel; ICH `kpf_set=ios18` does **not** patch `launch_constraints_func` (that set is `ios27` only).
- Boot-args have **no** `amfi_get_out_of_my_way` / `cs_enforcement_disable`.

### Boot-time policy (ICH chain)
| Piece | Role |
|-------|------|
| `trustcache.img4` (`rtsc`) | RestoreTrustCache + **build-time** append of SSH payload CDHashes (`resources/sshtarlist.txt`); loaded in Recovery via `irecovery` + `firmware` **before** `bootx` |
| `kpf_set=ios18` | Patches `PE_i_can_has_debugger` + stubs `AMFIIsCDHashInTrustCache` → always “in cache” |
| `txm=0` | No TXM cdhash-loader / `pmap.load-trust-cache` stubs (those are TXM-era) |

Built chain `n841ap-18.7.5-22H311-ramdisk`: `entry count = 469` in trustcache; **dpkg CDHashes are not among them** (expected — bootstrap was added later on Data).

**Tension (document, don’t hand-wave):** if the ios18 `AMFIIsCDHashInTrustCache` stub were sufficient by itself, `ldid` on a working bash copy should still run. It does not. So either the stub is incomplete / wrong site on 22H311, or a **later** gate (launch constraints, CSM/`codesigning.monitor`, library validation) kills fakesigned images even when the TC lookup is forced true. Empirically, **fakesign ≠ executable** on this ramdisk.

---

## 2. Primitives inventory (ICH + usbliter8)

| Primitive | Present? | Where | Usable from live SSH? |
|-----------|----------|-------|------------------------|
| SecureROM pwn → DFU | YES | usbliter8 / Pico | N/A (pre-boot) |
| Kernel r/w | **NO** | — | **NO** |
| Live trustcache inject / loadable TC | **NO** | `num_loadable: 0`; no device tool | **NO** |
| Build-time `trustcache append` + reboot | YES | `ICH…/tools/darwin/trustcache` + `build.sh` | Only after **rebuild + re-pwn + boot** |
| Boot-time TC load | YES | `boot.sh` → `trustcache.img4` | Pre-SSH only |
| ios18 AMFI TC stub | YES (claimed in patched kernel) | `patch/apply_kernel_patches.py` | Already in running kernel; **insufficient** for `ldid`’d bins |
| ios18 launch_constraints patch | **NO** | only in `kpf_set=ios27` | — |
| TXM cdhash / pmap TC entitlements | **NO** | `txm=0` | — |

usbliter8 remains **BootROM/DFU only** — not a post-boot AMFI or trustcache primitive.

---

## 3. Prototype decision

**No live CDHash inject prototype.** Missing primitive is explicit:

> **Missing:** a *runtime* way to authorize new CDHashes (loadable trustcache inject and/or kernel r/w to patch AMFI/CSM/launch-constraints), **or** a proven stronger pre-boot KPF (e.g. launch-constraints + verified TC stub) that makes Data-volume fakesign actually runnable.

Build-time `trustcache append` of `dpkg` + dylibs is available on the Mac host but:
1. Requires bootchain rebuild + device reboot (breaks this SSH session by definition).
2. Is **not clearly sufficient** given that TC stub + `ldid` still yields SIGKILL — so appending hashes without fixing the post-TC gate risks a wasted rebuild.

Do **not** “just ldid harder.”

---

## 4. Success criteria status

```text
/var/jb/usr/bin/dpkg --version
→ Killed: 9   (exit 137)
```

`/var/jb` mapping and SSH survival after tmpfs are solved separately; they are **not** the remaining AMFI gate.

### Reconfirm (2026-08-02 PM, ICH SSH)
Fresh usbliter8 DFU → `ICH_A12_plus_Ramdisk/boot.sh` → `mount_ich`:
- Identity: **18.7.5 (22H311)** / `N841AP` / `xnu-11417…/RELEASE_ARM64_T8020`
- `num_loadable: 0`, `launch_constraints_enforced: 1`, `codesigning.monitor: 1`, `developer_mode_status: 0`
- `/mnt2/root/jb/usr/bin/dpkg --version` → **Killed: 9** (exit 137)
- `cp /bin/bash /mnt2/tmp/b1` → runs (unchanged CDHash)
- `/var/jb` absent until tmpfs remap (not remounted this pass)

Local log (gitignored): `artifacts/xr-18.7.5/session-2026-08-02-pm.txt`

---

## 4b. Comparative teacher — Relaxin on A14 / 17.3 (not an XR path)

Live SSH on iPhone 12 mini (`iPhone13,1`, 17.3 / 21D50) with Relaxin **0.3.8** (RootHide):

| Fact | Relaxin 17.3 A14 | ICH XR 18.7.5 |
|------|------------------|---------------|
| `dpkg --version` | **runs** | **SIGKILL / 137** |
| `launch_constraints_enforced` | 1 | 1 |
| `codesigning.monitor` | 1 | 1 |
| `developer_mode_status` | 1 | 0 |
| `security.codesigning.trustcaches.num_*` | **not present** in `sysctl -a` | `num_loadable: 0` |
| Runtime CDHash API | `jbctl trustcache add <physical-macho>` (**works** with real `.jbroot-*` path) | **none** |
| `jbctl trustcache info` | exit 0, **0 lines** (this build) | n/a |
| Aftercare stack | `jailbreakd` + `libjailbreak` + hooks under `.jbroot-4F9D77E378C71AE3` | ICH TC stub + build-time `trustcache.img4` only |

**Teacher lesson (not a port):** a working package manager under LC+CSM correlates with a **live jailbreak trustcache authorizer** (`jbctl`/`libjailbreak`), not with “ldid harder.” ICH still lacks that class of primitive.

---

## 5. Next real work (ordered, no fantasy)

1. **Explain the residual kill** after the claimed `AMFIIsCDHashInTrustCache` stub (launch constraints / CSM / wrong patch site) — static RE of the 22H311 patched kernelcache vs live `SIGKILL` path.
2. **Either** extend KPF for 18.7.5 (launch constraints / whatever RE names) and rebuild bootchain, **or** obtain kernel r/w / loadable TC inject for live authorization.
3. Only then re-test full-path `/var/jb/usr/bin/dpkg --version` without treating `ldid` as the fix.

---

## Refs (trees)

- ICH build TC append: `ICH_A12_plus_Ramdisk/build.sh`, `tools/darwin/trustcache`, `resources/sshtarlist.txt`
- ICH boot TC load: `ICH_A12_plus_Ramdisk/boot.sh`
- ICH KPF: `ICH_A12_plus_Ramdisk/patch/{apply_kernel_patches.py,kernel_patchfinder.py}`
- Lab bootstrap /var/jb shim: `lumina/scripts/bootstrap/fix_exec.sh`
