# Lumina — DS-K sideload test host

Minimal iOS app (**not a jailbreak**) that runs DarkSword-class **DS-K** via `krw_*`
and shows results on screen.

| Field | Value |
|-------|--------|
| Display name | Lumina |
| Bundle ID | `com.kolbymaxx.lumina` |
| Arch | arm64 + arm64e |
| Deployment | iOS 15.0+ (must run on 18.7.5) |

## Mac build (quick)

```bash
# repo root
./scripts/clone_darksword_kexploit.sh
brew install xcodegen   # once
cd Lumina
xcodegen generate
open Lumina.xcodeproj
```

Sign with your Apple ID (E1) or paid team (E2). IPA steps: [../scripts/export_ipa.md](../scripts/export_ipa.md).

## Layout

| Path | Role |
|------|------|
| `Sources/` | UIKit host UI |
| `../src/krw/` | `krw_*` + `darksword_lib` + backend (excludes stub `krw.c`) |
| `../third_party/darksword-kexploit/` | gitignored upstream (patched locally) |

## Honesty

- No fake `kread` success if exploit fails  
- Offsets remain upstream’s (often 15.x) — expect `FAIL_OFFSETS` on 22H311  
- Private entitlements from upstream will not apply under stock sideload  

Lab protocol: [../docs/LAB_DSK.md](../docs/LAB_DSK.md).
