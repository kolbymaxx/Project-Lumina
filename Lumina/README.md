# Lumina — DS-K sideload test host

Minimal iOS app (**not a jailbreak**) that runs DarkSword-class **DS-K** via `krw_*`
and shows results on screen.

| Field | Value |
|-------|--------|
| Display name | **Lumina** |
| Bundle ID | `com.kolbymaxx.lumina` |
| Arch | arm64 + arm64e |
| Deployment | iOS 15.0+ (must run on 18.7.5) |

## Mac — paste ONE line at a time

Do **not** paste comments on the same line as `cd` (zsh will treat words as path args).
Prompt must leave `Downloads` and show a path under `Project-Lumina`.

### A) First time (no clone yet)

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

You must see `/Users/…/Projects/Project-Lumina`. If you still see `Downloads`, stop.

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
./scripts/mac_open_lumina.sh
```

### B) Already cloned

```bash
cd ~/Projects/Project-Lumina
```

```bash
pwd
```

```bash
git fetch origin && git checkout cursor/a12-krw-ppl-research-f891 && git pull origin cursor/a12-krw-ppl-research-f891
```

```bash
./scripts/mac_open_lumina.sh
```

### If clone lives elsewhere

```bash
find ~ -type d -name Project-Lumina 2>/dev/null | head
```

Then `cd` to that path (alone on its line) and run `./scripts/mac_open_lumina.sh`.

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
