# B006 — Trustcache stub hit / consultation (after B005)

**Date:** 2026-08-02  
**Device:** iPhone XR (N841AP / T8020) · ECID `00117540340B002E` · 18.7.5 / 22H311  
**Scope:** Host/docs + offline kernelcache strings + minimal live RO.  
**Not this pass:** mass lib append, `ldid -S`, B008 boot-args, CVE PoCs, DFU re-cycle.

**B005 reminder:** dpkg-only build-time TC append → exit **134** (was **137**); dyld rejects `libz-ng.2.dylib` (code signature invalid).

---

## Phase 1 — Boot chain TC map

| Item | Value |
|------|--------|
| Boot script | `ICH_A12_plus_Ramdisk/boot.sh` |
| Load site | `irecv -f "$BOOTCHAIN/trustcache.img4"` then `irecv -c firmware` **before** ramdisk/kernel/`bootx` |
| Artifact B005 modified | `bootchain/n841ap-18.7.5-22H311-ramdisk/trustcache.img4` |
| Type | IMG4 · fourcc **`rtsc`** (RestoreTrustCache) · size 17821 |
| Append method | Extract → `tools/darwin/trustcache append …/dpkg` → re-wrap `img4 -A -T rtsc -M resources/IM4M_0x8020` |
| Entry count | **469** → **470** |
| dpkg CDHash in boot TC | **yes** (`f223c26287b8acc9057ef74d109a07b171857dc2` at blob offset 9748) |
| Pre-B005 backup | `work/lumina-b005/trustcache.img4.pre-b005` / `trustcache.bin` |
| Second TC? | No separate loadable-TC img4 in this chain. Live `num_loadable: 0`. Static/`rtsc` is the only boot-loaded TC blob. |

**Sanity:** The file `boot.sh` sends is the same path B005 overwrote. Pre-boot verify (B005) confirmed CDHash in that img4 before `bootx`.

### Membership contrast (binary blob search)

| CDHash (sha256 trunc) | In pre-B005 TC? | In post-B005 TC? | Role |
|------------------------|-----------------|------------------|------|
| `27a45d02…` (`/bin/bash` from prior lab) | **yes** | **yes** | Explains stock bash living without append |
| `f223c262…` (`dpkg`) | **no** | **yes** | B005-only addition |

---

## Phase 2 — Offline kernelcache / AMFI / stubs

**Kernelcache used:** `/Users/kolby/Projects/firmware-22H311/kernelcache.payload` (stock 22H311 extract; **not** the ICH-patched on-device image). Honest limit: patch sites live in the **booted** `kernelcache.img4` built with `kpf_set=ios18`.

### Strings present (stock payload — presence only)

- Trust-cache load / check messaging: `PID %d is requesting a trust cache load`, `checking if a cdhash is in the trust cache`, `loading trust caches disallowed by system state`, `unable to load trust cache`
- AMFI surface: `AMFI Trust Cache Interface`, `can-execute-cdhash`, cdhash mismatch strings
- REM: `code is not present in any trustcache`
- PMAP_CS family (code-signing monitor / association)

### ICH KPF (booted chain — from tree, not re-verified byte-by-byte this pass)

- `kpf_set=ios18` patches **`AMFIIsCDHashInTrustCache`** → `MOV X0,#1` + store/ret (claimed “always in cache”)
- Does **not** patch `launch_constraints_func` (ios27-class only)
- `txm=0` → no TXM `pmap.load-trust-cache` stubs

### Prior live probes (amfi memo / session)

- `num_static: 1`, `num_engineering: 0`, `num_loadable: 0`
- LC enforced; CSM monitor on
- Same platform ents on bash vs dpkg; different CDHashes

### Mechanism sketch (best-effort)

```text
Exec /var/jb/.../Mach-O
  → CS blob / CDHash extracted
  → AMFI / trustcache consultation:
       • static RestoreTrustCache (rtsc loaded at Recovery) — membership list
       • loadable TC path exists in kernel strings but num_loadable=0 here
       • ios18 KPF may stub AMFIIsCDHashInTrustCache (claimed always-true)
  → If main binary accepted enough to map/start: dyld loads @rpath deps
  → Each dep: code-signature / library-validation check
       • missing/invalid CS or not authorized → dyld "code signature invalid"
       • historically: missing main CDHash → SIGKILL (137) before useful dyld
```

**Tension kept:** If the AMFI TC stub were complete for all CS paths, B005 append should be irrelevant. Empirical **137→134** after adding only dpkg’s hash to the **same** `rtsc` boot loads argues that **static TC membership still matters for the main binary path** (stub incomplete / alternate consult), while **dep CS** is a separate gate.

---

## Phase 3 — Minimal live RO (B005 boot still up)

| Check | Result |
|-------|--------|
| SSH | **yes** |
| `/var/jb/usr/bin/dpkg` | present |
| `libz-ng.2.dylib` | present (173216 bytes) |
| `num_static` | 1 |
| `num_loadable` | **0** |
| `codesigning.monitor` | 1 |
| `launch_constraints_enforced` | 1 |
| Re-ran dpkg? | **no** (not required) |

---

## Phase 4 — Interpret B005 under B006

| Question | Answer |
|----------|--------|
| Which TC file did boot load? | `…/bootchain/n841ap-18.7.5-22H311-ramdisk/trustcache.img4` (`rtsc`) via `boot.sh` / Recovery continue |
| Was dpkg CDHash present in that file post-append? | **yes** |
| Static vs loadable TC in this chain? | **Static `rtsc` only** at boot; live `num_loadable=0` (no live inject slot) |
| Why 137 → 134 is consistent with TC hit | Main binary CDHash newly in static TC → process reaches **dyld**; prior kill was earlier (SIGKILL). |
| Why libz-ng CS invalid fits | Dep not in TC / signature not accepted by library validation; dyld Abort 6 — expected if only dpkg was appended. |
| Safe next step | **Scoped one-dep append** (`libz-ng.2.dylib` CDHash only) — Option A. Not mass libs. Not “fix load path” first. |

### Verdict

**TC hit likely** for the main `dpkg` CDHash on the static boot `rtsc` path.

- Boot script and appended file match.  
- Hash absent→present correlates with failure-mode change.  
- Stock bash hash already in pre-B005 TC.  
- Loadable TC empty; append was never about `num_loadable`.

**Stub note:** ios18 `AMFIIsCDHashInTrustCache` patch remains a claimed always-hit; B005/B006 do **not** prove the stub is complete. They do support that **static `rtsc` membership is on a consulted path** for these jb binaries.

`dpkg` still does **not** run. No Sileo claim.

---

## Deliverables / next

**NEXT=A_scoped_libz_ng**

One controlled follow-up (new card, not this pass): CDHash of exact `/var/jb/usr/lib/libz-ng.2.dylib` → append → rebuild TC → re-pwn → one `dpkg --version`. Stop if a different dep fails; do not spam the catalog.
