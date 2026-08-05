# Lumina — DS-K sideload test host

Minimal iOS app (**not a jailbreak**) that runs DarkSword-class **DS-K** via `krw_*`
and shows results on screen.

| Field | Value |
|-------|--------|
| Display name | **Lumina** |
| Bundle ID | `com.kolbymaxx.lumina` |
| Arch | arm64 + arm64e |
| Deployment | iOS 15.0+ (must run on 18.7.5) |

## Mac build (copy-paste)

**Must be inside the Project Lumina git clone** — not `~/Downloads`, not KDotz-Repo.

```bash
# 0) Get the branch that contains Lumina/ (once)
cd ~/Projects/Project-Lumina   # ← change to YOUR clone path
git fetch origin
git checkout cursor/a12-krw-ppl-research-f891
git pull origin cursor/a12-krw-ppl-research-f891

# 1) One-shot: clone DS-K + xcodegen + open Xcode
./scripts/mac_open_lumina.sh
```

Manual equivalent:

```bash
cd /path/to/Project-Lumina
./scripts/clone_darksword_kexploit.sh
brew install xcodegen   # once
cd Lumina
xcodegen generate
open Lumina.xcodeproj
```

If you see `no such file or directory: ./scripts/...` or `cd: Lumina`, you are in the wrong directory (`pwd` to confirm).

Sign with Apple ID (E1) or paid team (E2). IPA: [../scripts/export_ipa.md](../scripts/export_ipa.md).

## Layout

| Path | Role |
|------|------|
| `Sources/` | UIKit host UI |
| `../src/krw/` | `krw_*` + `darksword_lib` + backend |
| `../third_party/darksword-kexploit/` | gitignored upstream (patched locally) |

## Honesty

- No fake `kread` success if exploit fails  
- Offsets remain upstream’s (often 15.x) — expect `FAIL_OFFSETS` on 22H311  
- Private entitlements from upstream will not apply under stock sideload  

Lab protocol: [../docs/LAB_DSK.md](../docs/LAB_DSK.md).
