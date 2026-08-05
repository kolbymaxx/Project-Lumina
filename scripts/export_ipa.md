# Export sideloadable IPA — Lumina (Mac)

Cloud/Linux cannot produce a signed IPA. Run these on a **Mac** with Xcode.

## Prerequisites

```bash
# From repo root
./scripts/clone_darksword_kexploit.sh
brew install xcodegen   # once
cd Lumina && xcodegen generate
open Lumina.xcodeproj
```

- Apple ID (E1 free) or paid Developer account (E2) selected in Xcode signing
- Physical iPhone XR (or any arm64e device) optional for Run; Archive works without device attached if identities exist

## Bundle ID

Default: `com.kolbymaxx.lumina`  
Change in `Lumina/project.yml` → `PRODUCT_BUNDLE_IDENTIFIER` if needed; mirror in `docs/ENTRY.md`.

## Archive → IPA (Xcode GUI)

1. Select target **Lumina**, destination **Any iOS Device (arm64)**.  
2. **Product → Archive**.  
3. Organizer → **Distribute App** → **Ad Hoc** or **Development** (sideload).  
4. Export IPA to disk.

### Alternate: Development install

**Product → Run** on a connected XR with automatic signing (E1/E2). No IPA file required for lab.

## Archive → IPA (CLI sketch)

```bash
cd Lumina
xcodegen generate
xcodebuild -project Lumina.xcodeproj -scheme Lumina \
  -configuration Release -sdk iphoneos \
  -archivePath build/Lumina.xcarchive archive \
  CODE_SIGN_STYLE=Automatic DEVELOPMENT_TEAM=YOUR_TEAM_ID

# Then export with an ExportOptions.plist (Development / AdHoc)
xcodebuild -exportArchive \
  -archivePath build/Lumina.xcarchive \
  -exportPath build/ipa \
  -exportOptionsPlist ExportOptions.plist
```

Example `ExportOptions.plist` (Development):

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>method</key><string>development</string>
  <key>signingStyle</key><string>automatic</string>
  <key>teamID</key><string>YOUR_TEAM_ID</string>
</dict>
</plist>
```

## Sideload tools

- Xcode Run / Devices window  
- AltStore / SideStore / Sideloadly — install the exported IPA (E1)  
- Expect upstream **private** entitlements to be stripped; see `docs/ENTRY.md`

## After install — lab

1. Open **Lumina** → **Run DS-K**.  
2. Copy on-screen log (or Console.app).  
3. Classify per `docs/LAB_DSK.md` and paste into `docs/STATUS.md`.

## Build failure: missing third_party

```text
error: run ./scripts/clone_darksword_kexploit.sh
```

That is intentional — we do not commit no-LICENSE upstream sources.
