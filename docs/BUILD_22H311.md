# Build identity — iPhone XR / 22H311

**Daily driver** for Lumina DS-K work. **Not assumed PE-viable** (literature: PE fixed 18.7.2).  
Lab must classify H1/H2/H3 — see [STATUS.md](STATUS.md). Sandbed plan: [BUILD_vulnerable_target.md](BUILD_vulnerable_target.md).

| Field | Value | Evidence |
|-------|-------|----------|
| Device | iPhone XR | Lab / STATUS |
| Product | `n841` / `n841ap` | STATUS |
| SoC | A12 (`t8020`), CPID `8020` | STATUS + kernel strings |
| CPU arch | **arm64e** | Kernelcache Mach-O |
| iOS | **18.7.5** | `/mnt1` SystemVersion (Phase A) |
| Build | **22H311** | Phase A locked |
| UDID (this XR) | `00008020-00117540340B002E` | STATUS |
| ECID | `00117540340B002E` | STATUS |

## Kernelcache (operator-supplied — not in git)

| Role | Path (research Mac) | In repo? |
|------|---------------------|----------|
| IM4P | `/Users/kolby/Projects/firmware-22H311/kernelcache.release.iphone11b` | **No** (copyrighted IPSW content) |
| Decompressed payload | `/Users/kolby/Projects/firmware-22H311/kernelcache.payload` | **No** |

Workflow: [../scripts/fetch_kernelcache.md](../scripts/fetch_kernelcache.md).  
Probe list: [../research/kexploit/22H311_NOTES.md](../research/kexploit/22H311_NOTES.md).

### Hashes (fill when available — archival + offset derivation aid)

If `kernelcache.payload` is available, record SHA-256 here. Useful if we later
derive offsets for a DS-K port. **No offset fanfiction** from hashes alone.

| Artifact | Algorithm | Digest | Date | Operator |
|----------|-----------|--------|------|----------|
| `kernelcache.release.iphone11b` | SHA-256 | `/* TODO verify */` | — | — |
| `kernelcache.payload` | SHA-256 | `/* TODO verify */` | — | — |

```bash
# On the Mac that holds the artifacts (optional):
shasum -a 256 /Users/kolby/Projects/firmware-22H311/kernelcache.release.iphone11b
shasum -a 256 /Users/kolby/Projects/firmware-22H311/kernelcache.payload
```

Paste digests into the table above. **Do not commit the kernelcache binaries.**

### Identity strings (literature / operator survey)

- Fileset Mach-O, arm64e, ~54 MB payload (operator report)
- `xnu-11417…T8020` class strings observed
- Full paste-back still TODO for Probe 3 in `22H311_NOTES.md`

## Offsets header

Skeleton (all fields TODO until derived):  
[`../src/krw/offsets_n841_22H311.h`](../src/krw/offsets_n841_22H311.h)

**Policy:** offsets only from (a) public tables for **this** build, (b) derivation from our kernelcache, or (c) `/* TODO verify */` + symbol name. Never invent numbers.

## Related

- [STATUS.md](STATUS.md)
- [KRW.md](KRW.md)
- [PPL.md](PPL.md)
