# Entry — running a DS-K host on XR hardware

**Goal:** execute a **DS-K** binary (opa334 `darksword-kexploit` / Lumina host) on a device we own.  
**Daily driver:** iPhone XR · **18.7.5 (22H311)** · arm64e.  
**Not assumed:** that 22H311 is PE-viable (see hypotheses in STATUS).

## Bottom line

**TrollStore is unavailable on 18.7.5** (CoreTrust install window ends at 17.0; 17.0.1+ unsupported).  
That means we **cannot** install a permanently fakesigned IPA with arbitrary private entitlements on the daily driver.

Public DS-K trees still ship an `entitlements.plist` full of private keys (see below). On stock 18.7.5 those entitlements **will not apply** under normal Apple signing — first attempts may hit **`FAIL_ENTRY`** before PE logic matters. That is still a useful lab result.

**DS-Full** Safari chains are **not** an entry path we implement.

## Ranked options (legal, own-device)

| Rank | Code | Path | Works on 18.7.5 XR? | Entitlements reality | Fit for first DS-K attempt |
|------|------|------|---------------------|----------------------|----------------------------|
| 1 | **E1** | Free Apple ID sideload (Xcode / AltStore / Sideloadly) — 7-day resign | Yes | Profile-limited; private keys stripped/ignored | Fastest; likely `FAIL_ENTRY` or sandbox-only run — still logs H1/H2 signal |
| 2 | **E2** | Paid Apple Developer Program signing | Yes | Same entitlement ceiling as E1 for private keys; stabler identities | Better for repeat lab sessions; still not TrollStore |
| 3 | **E3** | Freeze 18.7.5 host work; prepare DS-K on a **pre-18.7.2** disposable device/build | N/A (different build) | If that build also lacks TrollStore, same signing limits — but PE may still be live (**H3**) | Rational sandbed if literature is right about 18.7.2 |
| — | **E4** | Other (operator specifies) | ? | Must stay legal / own-device | Record in STATUS |

Out of policy: stolen/enterprise certs, other people’s devices, DS-Full watering-hole packaging.

### Citations

- [opa334/TrollStore](https://github.com/opa334/TrollStore) — 17.0.1+ never  
- [ios.cfw.guide — Installing TrollStore](https://ios.cfw.guide/installing-trollstore/)

## Entitlements from public DS-K host

From upstream [`entitlements.plist`](https://github.com/opa334/darksword-kexploit/blob/main/entitlements.plist) (opa334/darksword-kexploit):

| Key | Present upstream | Obtainable via E1/E2 on stock 18.7.5? |
|-----|------------------|----------------------------------------|
| `platform-application` | yes | **No** (private) |
| `com.apple.private.security.no-sandbox` | yes | **No** |
| `proc_info-allow` | yes | **No** |
| `com.apple.private.persona-mgmt` | yes | **No** |
| `com.apple.private.tcc.allow` / storage exemptions | yes | **No** |
| `com.apple.private.mobileinstall.allowedSPI` | yes | **No** |
| IOKit user-client exceptions (AGX, IOSurface, …) | yes | **No** (private exceptions) |
| `com.apple.developer.kernel.extended-virtual-addressing` | yes | Maybe (public developer entitlement — if requested in App ID) |
| `com.apple.developer.kernel.increased-memory-limit` | yes | Maybe (public developer entitlement) |
| `com.apple.security.network.client` | yes | Yes (standard) |

Makefile signs with `ldid -Sentitlements.plist` — that assumes a bypass (historically TrollStore) or a research-signed environment. **On stock 18.7.5, plan for missing private entitlements.**

Whether CVE-2025-43520’s trigger still works from a **default app sandbox** with only public entitlements is **unknown** until lab — Apple’s advisory text says “malicious application,” which does not require TrollStore, but the public port may assume the richer plist.

## Decision (OPEN — overrides prior B)

Prior “docs-only / no test host” decision is **void** under the DarkSword OVERRIDE.

Pick one for the first DS-K attempt:

- [ ] **E1** — free sideload / personal team provisioning  
- [ ] **E2** — paid Apple Developer signing  
- [ ] **E3** — freeze 18.7.5 host work; prepare **pre-18.7.2** test build/device  
- [ ] **E4** — other: _______________________  

Record the choice in [STATUS.md](STATUS.md).

## After entry is chosen

1. Clone DS-K per [../third_party/README.md](../third_party/README.md).  
2. Build upstream `darksword-pe` **or** Lumina `src/host` wrapper (Mac + iphoneos SDK).  
3. Deploy via the chosen signing path.  
4. Run [LAB_DSK.md](LAB_DSK.md) and paste the result code into STATUS.

## Related

- [STATUS.md](STATUS.md)
- [DARKSWORD.md](DARKSWORD.md)
- [KRW.md](KRW.md)
- [LAB_DSK.md](LAB_DSK.md)
- [BUILD_vulnerable_target.md](BUILD_vulnerable_target.md)
