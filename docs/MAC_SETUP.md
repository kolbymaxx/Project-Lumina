# Full Mac setup — Lumina DS-K host (iPhone XR)

Lab harness only. **Not a jailbreak.**  
Target phone: iPhone XR · A12 · iOS **18.7.5 / 22H311**.

Paste **one Terminal line at a time**. Do not put comments on the same line as `cd`.

---

## 0) What you need

- Mac with **Xcode** installed (App Store), opened once (accept license)
- Terminal
- Apple ID (free = E1) or paid Developer account (E2)
- iPhone XR on USB, unlocked, Trust This Computer
- Homebrew (`brew`). If missing: https://brew.sh

Check Xcode:

```bash
xcodebuild -version
```

```bash
xcrun -sdk iphoneos --show-sdk-version
```

---

## 1) Get Project Lumina

### First time

```bash
mkdir -p ~/Projects
```

```bash
git clone https://github.com/kolbymaxx/Project-Lumina.git ~/Projects/Project-Lumina
```

```bash
cd ~/Projects/Project-Lumina
```

```bash
pwd
```

**Must print** a path ending in `Project-Lumina`.  
If it still says `Downloads`, you are in the wrong folder — run only:

```bash
cd ~/Projects/Project-Lumina
```

```bash
pwd
```

### Already cloned

```bash
cd ~/Projects/Project-Lumina
```

```bash
pwd
```

---

## 2) Checkout the Lumina branch

```bash
git fetch origin
```

```bash
git checkout cursor/a12-krw-ppl-research-f891
```

```bash
git pull origin cursor/a12-krw-ppl-research-f891
```

```bash
ls Lumina/project.yml scripts/mac_open_lumina.sh
```

Both paths must exist.

---

## 3) Clone DS-K + generate Xcode project + open

```bash
./scripts/mac_open_lumina.sh
```

What this does:

1. Clones `opa334/darksword-kexploit` into `third_party/` (not committed to git)
2. Applies Lumina library patch
3. Installs `xcodegen` via brew if needed
4. Generates `Lumina/Lumina.xcodeproj`
5. Opens Xcode

### If the script fails

Missing third_party / patch:

```bash
./scripts/clone_darksword_kexploit.sh
```

```bash
brew install xcodegen
```

```bash
cd ~/Projects/Project-Lumina/Lumina
```

```bash
xcodegen generate
```

```bash
open Lumina.xcodeproj
```

---

## 4) Sign in Xcode

1. Wait for Xcode to finish opening / indexing.
2. Left sidebar → select blue project **Lumina**.
3. Target **Lumina** → **Signing & Capabilities**.
4. Enable **Automatically manage signing**.
5. **Team** → your Apple ID team (add account under Xcode → Settings → Accounts if needed).
6. Bundle ID should be `com.kolbymaxx.lumina`.  
   If Xcode says it’s taken, change to e.g. `com.kolbymaxx.lumina.lab` and note it.

Connect the XR with USB. Unlock phone. Trust computer if asked.

Top bar destination → your **iPhone XR** (not a Simulator).

---

## 5) Build and install on the phone

Menu: **Product → Run** (or ▶).

First run may ask to enable Developer Mode on the phone:

- Settings → Privacy & Security → Developer Mode → On → reboot if asked

If install fails with “Untrusted Developer”:

- Settings → General → VPN & Device Management → trust your developer app

App icon name: **Lumina**.

---

## 6) Run DS-K on device

1. Open **Lumina** on the XR.
2. Tap **Run DS-K**.
3. Wait (UI may freeze during the race — normal).
4. Read the on-screen log:
   - `krw_init => …`
   - `kbase => …`
   - `kslide => …`
   - hint line (`FAIL_*` / candidate success)

Optional: Mac **Console.app** → select the iPhone → filter `Lumina` while running.

---

## 7) What to send back (paste into chat)

```text
### DS-K session
- Device: iPhone XR n841
- Build: 18.7.5 / 22H311 (confirm in Settings → General → About)
- Entry: E1 or E2
- Bundle ID: com.kolbymaxx.lumina
- Full on-screen log:
(paste everything)
- Panic? yes/no (if yes, paste panic text)
- Result code (pick one):
  SUCCESS_KRW | FAIL_PATCHED | FAIL_OFFSETS | FAIL_ENTRY | FAIL_PANIC | UNKNOWN
```

Honest expectations on **18.7.5**: literature says PE was fixed in **18.7.2**. A clean fail is still progress. Do not invent success.

---

## 8) Optional — export an IPA (instead of Run)

Only if you want a `.ipa` file for AltStore / Sideloadly:

1. Destination: **Any iOS Device (arm64)**
2. **Product → Archive**
3. Organizer → **Distribute App** → Development or Ad Hoc → export

Details: [export_ipa.md](../scripts/export_ipa.md) (path from repo: `scripts/export_ipa.md`).

---

## Common errors

| Symptom | Fix |
|---------|-----|
| `cd: too many arguments` | `cd` line had extra words; use only `cd ~/Projects/Project-Lumina` |
| Still in `Downloads` | `pwd` then `cd ~/Projects/Project-Lumina` |
| `not a git repository` | You are not inside the clone |
| `./scripts/mac_open_lumina.sh: No such file` | Wrong directory or wrong branch |
| Xcode can’t sign | Add Apple ID in Xcode → Settings → Accounts; pick Team |
| Build error missing `main.m` | Re-run `./scripts/clone_darksword_kexploit.sh` |
| App won’t open | Developer Mode + trust developer cert |

---

## Related

- [ENTRY.md](ENTRY.md) — E1/E2/E3/E4
- [LAB_DSK.md](LAB_DSK.md) — result codes
- [STATUS.md](STATUS.md) — living truth
- [../Lumina/README.md](../Lumina/README.md)
