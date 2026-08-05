# Entry — running the Lumina DS-K host on XR hardware

**Goal:** sideload the **Lumina** app and run **DS-K** via `krw_*`.  
**Daily driver:** iPhone XR · **18.7.5 (22H311)** · arm64e.  
**Not assumed:** that 22H311 is PE-viable (see STATUS hypotheses).

## App identity (final)

| Field | Value |
|-------|--------|
| Display name | **Lumina** |
| Bundle ID | `com.kolbymaxx.lumina` |
| Sources | [`Lumina/`](../Lumina/) (XcodeGen) |
| KRW API | [`src/krw/`](../src/krw/) |
| Upstream DS-K | `third_party/darksword-kexploit` (**gitignored**, no LICENSE) |

Change bundle ID only in `Lumina/project.yml` if signing conflicts; keep this doc in sync.

## Bottom line

**TrollStore is unavailable on 18.7.5.**  
Lumina ships **sideload entitlements** (`Lumina/Lumina.entitlements`) — not the full upstream private set. On stock 18.7.5, first runs may be `FAIL_ENTRY` before PE logic matters. That is still a useful lab result.

**DS-Full** Safari chains are **not** an entry path we implement.

## Build + sideload (Mac)

```bash
# 1) Clone + patch upstream (required — sources not in git)
./scripts/clone_darksword_kexploit.sh

# 2) Generate Xcode project
brew install xcodegen   # once
cd Lumina && xcodegen generate && open Lumina.xcodeproj
```

3. In Xcode: select your Team (E1 free / E2 paid), destination **Any iOS Device**.  
4. **Product → Run** on XR, **or** Archive → IPA per [`scripts/export_ipa.md`](../scripts/export_ipa.md).  
5. Open **Lumina** → **Run DS-K** → copy log → classify in [`LAB_DSK.md`](LAB_DSK.md).

If third_party is missing, the Xcode pre-build script **fails the build** on purpose (no fake KRW).

## Ranked options (legal, own-device)

| Rank | Code | Path | Fit for Lumina IPA |
|------|------|------|--------------------|
| 1 | **E1** | Free Apple ID sideload (Xcode / AltStore / Sideloadly) | Primary path for this IPA |
| 2 | **E2** | Paid Apple Developer signing | Same IPA; stabler signing |
| 3 | **E3** | Freeze 18.7.5; use **pre-18.7.2** sandbed | Same app, different OS — see [`BUILD_vulnerable_target.md`](BUILD_vulnerable_target.md) |
| — | **E4** | Other (specify) | Record in STATUS |

Out of policy: stolen certs, DS-Full watering-hole packaging.

### Citations

- [opa334/TrollStore](https://github.com/opa334/TrollStore) — 17.0.1+ never  
- [ios.cfw.guide — Installing TrollStore](https://ios.cfw.guide/installing-trollstore/)

## Entitlements

### What Lumina uses for E1/E2 (`Lumina.entitlements`)

| Key | Purpose |
|-----|---------|
| `get-task-allow` | Dev debugging |
| `com.apple.security.network.client` | Standard network client |

### What upstream DS-K wants (not applied on stock sideload)

See [`Lumina/Lumina.research.entitlements`](../Lumina/Lumina.research.entitlements) (copy of opa334 `entitlements.plist`):
`platform-application`, `no-sandbox`, IOKit exceptions, etc. — **private**; require TrollStore-class bypass (unavailable on 18.7.5).

## Decision (OPEN)

- [ ] **E1** — free sideload / personal team provisioning  
- [ ] **E2** — paid Apple Developer signing  
- [ ] **E3** — freeze 18.7.5 host work; prepare **pre-18.7.2** test build/device  
- [ ] **E4** — other: _______________________  

Building the IPA does **not** by itself lock E1 — pick one and record in STATUS before claiming a lab session.

## Related

- [STATUS.md](STATUS.md)
- [LAB_DSK.md](LAB_DSK.md)
- [../Lumina/README.md](../Lumina/README.md)
- [../scripts/export_ipa.md](../scripts/export_ipa.md)
- [../third_party/README.md](../third_party/README.md)
