# `src/krw` — thin KRW harness

Auditable API around a **future** public kexploit backend for  
**iPhone XR / 18.7.5 (22H311)**.

**Not a working exploit.** Default backend returns `KRW_ERR_NO_BACKEND`.

## Files

| File | Role |
|------|------|
| `krw.h` | `krw_init`, `kread`, `kwrite`, `kbase`, `kslide`, `krw_deinit` |
| `krw.c` | Stub implementation |
| `offsets_n841_22H311.h` | Offset skeleton — all `TODO verify` |
| `test_plan.md` | Read-known-stable first |
| `ATTRIBUTION.md` | Where upstream LICENSE/attribution goes |

## Integration plan (when a live public primitive exists)

1. Clone or vendor the **public** implementation under  
   `research/kexploit/<name>/` (often gitignored — see root `.gitignore`).  
2. Record **LICENSE**, URL, commit hash in `ATTRIBUTION.md`.  
3. Add a compile-time backend (e.g. `KRW_BACKEND_<NAME>=1`) that calls into  
   that tree from `krw.c` — do **not** copy exploit sources into `boot/`.  
4. Fill `offsets_n841_22H311.h` only from public **22H311** tables or our  
   kernelcache derivation notes (`docs/BUILD_22H311.md`).  
5. Run `test_plan.md` on device; upgrade `docs/STATUS.md` only with a  
   re-runnable command + expected output.

## DarkSword note

Public DarkSword kernel PE (`CVE-2025-43510` / `CVE-2025-43520`) is **fixed  
in iOS 18.7.2**. Do not integrate those PE stages as a live backend for  
22H311 unless lab evidence contradicts Apple/NVD/GTIG (document the  
contradiction first).

## Build (host smoke — optional)

There is no Xcode project in-tree yet (`src/app/` is reserved).  
On a Mac with an iOS toolchain, compile the stub as a static check:

```bash
# Example only — adjust SDK paths on the operator Mac:
xcrun -sdk iphoneos clang -arch arm64e -c src/krw/krw.c -o /tmp/krw.o
```

Cloud VM: docs review is enough; device USB not available.

## Related

- [../../docs/KRW.md](../../docs/KRW.md)
- [../../docs/ENTRY.md](../../docs/ENTRY.md)
- [../../docs/STATUS.md](../../docs/STATUS.md)
