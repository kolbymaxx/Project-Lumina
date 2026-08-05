# third_party — public DS-K checkout (local only)

## Chosen tree

| Field | Value |
|-------|--------|
| URL | https://github.com/opa334/darksword-kexploit |
| Role | Primary **DS-K** implementation |
| LICENSE | **None published** — do **not** commit sources |
| Clone script | [`../scripts/clone_darksword_kexploit.sh`](../scripts/clone_darksword_kexploit.sh) |
| Library patch | [`patches/darksword-library.patch`](patches/darksword-library.patch) |

Pinned clone observed at script authoring: `0ee563282e7235f8355ffc1fbf23ac6fd0f98040` (record your HEAD in `src/krw/ATTRIBUTION.md`).

## One command

```bash
./scripts/clone_darksword_kexploit.sh
```

This:

1. `git clone --depth 1` into `third_party/darksword-kexploit/` (gitignored)  
2. Applies `patches/darksword-library.patch`:
   - `FAILURE` → `longjmp` when `LUMINA_DSK_LIBRARY`  
   - `main` → `darksword_cli_main` (app provides `UIApplicationMain`)

## Why not submodule?

No LICENSE → we do not redistribute upstream in Lumina’s git history.  
Operator clones locally; Lumina keeps adapters + patch + app only.

## Consumed by

- **Lumina** Xcode target (`Lumina/project.yml`) — fails build if clone/patch missing  
- `src/krw/darksword_lib.m` + `krw_backend_darksword.c`

## Related

- [../Lumina/README.md](../Lumina/README.md)
- [../docs/ENTRY.md](../docs/ENTRY.md)
- [../scripts/export_ipa.md](../scripts/export_ipa.md)
