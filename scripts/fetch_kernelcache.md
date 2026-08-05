# Kernelcache workflow — 22H311 (notes only)

**Do not download copyrighted IPSW content into this git repo** unless the
operator has already obtained it locally and accepts redistribution risk.
This file is instructions only.

## Goal

Produce a decompressed `kernelcache.payload` for **iPhone XR / 22H311**,
record hashes in [`docs/BUILD_22H311.md`](../docs/BUILD_22H311.md), and
derive symbols/offsets for [`src/krw/offsets_n841_22H311.h`](../src/krw/offsets_n841_22H311.h).

## Operator-known paths (Mac)

| Role | Path |
|------|------|
| IM4P | `/Users/kolby/Projects/firmware-22H311/kernelcache.release.iphone11b` |
| Payload | `/Users/kolby/Projects/firmware-22H311/kernelcache.payload` |

If missing, extract from a user-owned IPSW for  
`iPhone11,8_18.7.5_22H311_Restore` using your usual img4/pyimg4 tools.
Keep artifacts **outside** the repo (or under gitignored
`artifacts/xr-18.7.5/kernelcache/`).

## Hash lock

```bash
shasum -a 256 /Users/kolby/Projects/firmware-22H311/kernelcache.release.iphone11b
shasum -a 256 /Users/kolby/Projects/firmware-22H311/kernelcache.payload
```

Paste into `docs/BUILD_22H311.md`.

## Identity probes

Follow the five probes in  
[`research/kexploit/22H311_NOTES.md`](../research/kexploit/22H311_NOTES.md)
(file/otool/strings). Paste stdout into STATUS or local notes.

## Symbol / offset derivation (skeleton)

1. Confirm fileset entry for the kernel (`xnu` / T8020).  
2. List symbols you care about for the **chosen** live kexploit (not DarkSword PE — patched).  
3. For each field in `offsets_n841_22H311.h`, either:  
   - fill from derivation notes + citation, or  
   - leave `/* TODO verify */` with the symbol name.  
4. Never copy another build’s immediates without a written delta.

## Legal / hygiene

- IPSW and kernelcache are Apple copyrighted — keep local.  
- Do not commit binaries.  
- Cloud agents: docs only unless the operator uploaded a local copy.

## Related

- [../docs/BUILD_22H311.md](../docs/BUILD_22H311.md)
- [../docs/KRW.md](../docs/KRW.md)
