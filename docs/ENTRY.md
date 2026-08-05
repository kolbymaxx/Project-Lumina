# Entry reality — running a kexploit host on stock 18.7.5 XR

**Device:** iPhone XR (`n841`) · **iOS 18.7.5 (22H311)** · **arm64e**

This document answers: *how can a kernel-exploit binary even execute?*

## Bottom line

**Stock SpringBoard entry for TrollStore-style (arbitrary entitlement) kexploit hosts is blocked on 18.7.5.**

Developer-signed sideload can run a **limited-entitlement** test app. Whether that is enough depends on the specific bug (often **unknown** until a writeup exists).  
We do **not** treat a WebKit full-chain as the Lumina product path.

## Options

| Method | Works on 18.7.5 XR? | Entitlements | Fit for public kexploit style |
|--------|---------------------|--------------|-------------------------------|
| **TrollStore** | **No** — unsupported on 17.0.1+ / iOS 18 | Would allow near-arbitrary | Historical JB tooling path — **unavailable** |
| **Apple Developer Program** signing | Yes (paid) | Profile-limited; no CoreTrust bypass | Possible for sandbox-reachable bugs |
| **Free Apple ID** sideload (AltStore / Sideloadly / Xcode) | Yes, **7-day** resign | Same entitlement limits | OK for short lab sessions only |
| **Enterprise / stolen cert** | Out of policy | — | **Refuse** |
| **Already jailbroken device** | N/A | Full | Circular — we do not have this |
| **Safari / WebKit chain** | DarkSword stages patched; others unknown | Browser sandbox → … | **Not our product path** |
| **usbliter8 ramdisk SSH** | **Yes** (proven) | Root in **restore** env | Forensic / RE — **≠** live OS KRW |

### Citations (entry tools)

- [opa334/TrollStore](https://github.com/opa334/TrollStore) — support ends **17.0**; 17.0.1+ never  
- [ios.cfw.guide — Installing TrollStore](https://ios.cfw.guide/installing-trollstore/) — matrix shows 17.0.1+ unsupported  

## Entitlements typically seen in public kexploit hosts

Exact sets vary. Common themes in Dopamine / research IPAs (historical):

- Broader sandbox escape / `task_for_pid`-class capabilities (often **TrollStore-only** on stock)
- IOKit user clients reachable from default app sandbox (bug-dependent)
- `platform-application` / research entitlements — **not** available via normal sideload

**Honest split:**

1. **Blocked on stock** for “IPA with arbitrary entitlements” hosts.  
2. **Possible with X** = Apple-signed test host **if** the chosen primitive is triggerable from that sandbox.  
3. **UNKNOWN** which 18.7.9-fixed advisory CVEs are (1) vs (2) until public writeups land.

## Implications for Lumina

```text
TrollStore arbitrary-entitlement host     → BLOCKED on 18.7.5
Developer-signed minimal test host        → POSSIBLE (operator decision)
DarkSword PE as the payload               → PATCHED (18.7.2) even if host runs
WebKit weaponization as product           → REFUSED
usbliter8 ramdisk                         → SEPARATE track (works; not SpringBoard KRW)
```

STATUS must keep the stock TrollStore/entry gate visible.  
Harness code under `src/krw/` assumes a future host; it does not create one.

## Operator decision (locked 2026-08-05)

- [ ] **A.** Lab will sideload a developer-signed `src/` test host on the XR  
- [x] **B.** No SpringBoard host — KRW track stays **docs/offline** this milestone  
- [x] **Priority C.** Human time → **usbliter8 post-pwn iBEC jump**, not Lumina app signing  

No fake `kread`/`kwrite` backends. Revisit SpringBoard hosting only if a new
public PE verified on **22H311** makes a host worth the signing cost.

## Related

- [STATUS.md](STATUS.md)
- [KRW.md](KRW.md)
- [ATTRACT_DEVS.md](ATTRACT_DEVS.md)
