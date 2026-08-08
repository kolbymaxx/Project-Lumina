# Lumina Repo — ma6x9x username fix

Cloud agents for **Project-Lumina** cannot push to
[`ma6x9x/lumina-repo`](https://github.com/ma6x9x/lumina-repo) (`cursor[bot]` 403).
This folder holds ready patches.

## Target

| Item | Value |
|------|--------|
| Display name | **Lumina Repo** |
| GitHub / Sileo slug | `lumina-repo` (lowercase — Sileo-safe) |
| Username | `ma6x9x` |
| Sileo URL | `https://raw.githubusercontent.com/ma6x9x/lumina-repo/main/` |
| Pages | `https://ma6x9x.github.io/lumina-repo/` |

Open rebrand PR (KDotz → Lumina): https://github.com/ma6x9x/lumina-repo/pull/55

## Files

- `ma6x9x-username-on-pr55.patch` — apply on `cursor/sileo-dopamine-repo-harden-d520`
- `apply-on-lumina-repo.sh` — clone that branch, apply, commit
- `Music27-standalone-ma6x9x.patch` — optional fix for legacy `ma6x9x/Music27`

## Apply (needs write access to lumina-repo)

```bash
./artifacts/lumina-repo-ma6x9x/apply-on-lumina-repo.sh
# KEEP=1 ./artifacts/lumina-repo-ma6x9x/apply-on-lumina-repo.sh  # keep workdir
```

Or start a Cursor Cloud agent **on** https://github.com/ma6x9x/lumina-repo and ask it to apply this patch / finish the username rename.

## Policy

- Updates URLs, Author/Maintainer, landing page, publish script, APT Description
- **Does not** change package IDs (`com.kolby.*`, `com.music27.tweak`)
- Leaves “remove old KDotz source” migration notes for users
