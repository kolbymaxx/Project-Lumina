# `src/krw` — DS-K harness

| File | Role |
|------|------|
| `krw.h` | Public API |
| `krw.c` | Default none-backend (not used by Lumina app target) |
| `krw_backend_darksword.c` | Real DS-K backend when `DARKSWORD_EXPLOIT_LINKED=1` |
| `darksword_lib.h` / `.m` | setjmp wrapper around `darksword_cli_main` + early KRW |
| `offsets_n841_22H311.h` | All TODO — do not invent |

## Lumina app build flags

Defined in `Lumina/project.yml`:

- `KRW_BACKEND_DARKSWORD=1`
- `DARKSWORD_EXPLOIT_LINKED=1`
- `LUMINA_DSK_LIBRARY=1`

Requires `./scripts/clone_darksword_kexploit.sh` first.

## Host smoke (Linux CI shape)

```bash
cc -DKRW_BACKEND_DARKSWORD=1 -DDARKSWORD_EXPLOIT_LINKED=0 \
  -Isrc/krw -c src/krw/krw_backend_darksword.c -o /tmp/krw_ds.o
```

Device IPA: see `Lumina/README.md` + `scripts/export_ipa.md`.
