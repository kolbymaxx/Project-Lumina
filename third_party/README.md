# third_party — public DS-K checkout (local only)

## Chosen tree

| Field | Value |
|-------|--------|
| URL | https://github.com/opa334/darksword-kexploit |
| Role | Primary **DS-K** implementation (ObjC, `src/main.m`) |
| LICENSE | **None published** (GitHub API `license: null` as of 2026-08-05) |
| Build product | `darksword-pe` (`Makefile`: arm64 + arm64e, `ldid -Sentitlements.plist`) |

Attribution / leak provenance (upstream note):  
https://github.com/htimesnine/DarkSword-RCE — also **no LICENSE**; teacher only.

## Vendor method: **local gitignored clone** (not submodule)

Because there is **no LICENSE**, we **must not** commit or redistribute the
exploit sources inside Lumina’s git history.

Prefer:

```bash
# From repo root (Mac lab machine):
mkdir -p third_party
git clone --depth 1 https://github.com/opa334/darksword-kexploit.git \
  third_party/darksword-kexploit

# Record for ATTRIBUTION (do not commit the tree):
git -C third_party/darksword-kexploit rev-parse HEAD
```

`third_party/darksword-kexploit/` is listed in `.gitignore`.

### Why not submodule / subtree?

| Method | Problem here |
|--------|----------------|
| Submodule | Propagates no-license sources to every clone with `--recursive` |
| Subtree / vendor copy in git | Same redistribution issue |
| **Local clone (gitignored)** | Operator obtains sources themselves; Lumina keeps adapters + docs only |

If upstream later adds an OSI license, revisit submodule.

## How Lumina calls it

1. **Binary-first lab (recommended for attempt #1):** build upstream `darksword-pe` on Mac with iphoneos SDK; embed/run via `src/host` under entry E1/E2.  
2. **Library adapter (later):** compile `src/krw/krw_backend_darksword.c` with `-DKRW_BACKEND_DARKSWORD=1` and `-DDARKSWORD_ROOT=...` once callable symbols are extracted from upstream (today the tree is a monolithic `main.m` — do not invent a fake API).

Never reimplement PE logic from news articles inside Lumina.

## LICENSE gate checklist

- [x] Confirmed no LICENSE file on opa334/darksword-kexploit  
- [x] Do not `git add` third_party/darksword-kexploit  
- [ ] Operator clone + record commit hash in `src/krw/ATTRIBUTION.md`  
- [ ] Entry E1–E4 chosen before signing experiments  

## Related

- [../docs/DARKSWORD.md](../docs/DARKSWORD.md)
- [../docs/KRW.md](../docs/KRW.md)
- [../src/krw/krw_backend_darksword.c](../src/krw/krw_backend_darksword.c)
- [../src/host/README.md](../src/host/README.md)
