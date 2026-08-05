# `src/krw` — DS-K harness

Auditable KRW API for Lumina’s **DarkSword-class** main line.

| File | Role |
|------|------|
| `krw.h` / `krw.c` | Default: `KRW_ERR_NO_BACKEND` |
| `krw_backend_darksword.c` | DS-K adapter — `KRW_ERR_NOT_LINKED` until upstream ABI wired |
| `offsets_n841_22H311.h` | All TODO — no invented immediates |
| `test_plan.md` | Read-first policy |
| `ATTRIBUTION.md` | Upstream URL + commit (after clone) |

## Build notes

```bash
# Default stub (any host compiler):
cc -c src/krw/krw.c -o /tmp/krw.o

# DS-K adapter shape check (still returns NOT_LINKED):
cc -DKRW_BACKEND_DARKSWORD=1 -c src/krw/krw_backend_darksword.c -o /tmp/krw_ds.o
```

Device builds: Mac + iphoneos SDK, **arm64e**, after entry E1/E2 and local
`third_party/darksword-kexploit` clone.

**Do not** set `DARKSWORD_EXPLOIT_LINKED=1` until real symbols from the local
clone are wired — that flag currently `#error`s on purpose.
