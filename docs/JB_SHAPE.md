# Jailbreak product shape (design only)

**Status:** design sketch. **Do not implement bootstrap / Sileo until `SUCCESS_KRW`.**

## Plug-in order (Dopamine-shaped)

```text
DS-K (public kexploit backend)
  → Lumina krw_* API  (kread / kwrite / kbase / kslide)
  → PAC-aware primitives (arm64e)
  → PPL strategy for A12 on the build where KRW works
  → AMFI / trustcache / codesign policy
  → unsandbox + bootstrap (jailbreakd / rootless patterns)
  → optional package manager UX  (LAST)
```

References for architecture only: Dopamine, RootHide-style kexploit plugs, Relaxin stage vocabulary — **teachers, not installers** for 22H311.

## What we will not do yet

- Sileo / Zebra UI packaging  
- Claiming PPL bypass in prose  
- Shipping DS-Full WebKit kits as the product  

## Gate

| Gate | Required |
|------|----------|
| Open this doc for implementation | `SUCCESS_KRW` logged in STATUS on some build |
| Start PPL experiments | Same |
| Bootstrap code | KRW + written PPL test plan |

Until then, engineering effort stays on **entry + DS-K lab + offsets honesty**.

## Related

- [STATUS.md](STATUS.md)
- [KRW.md](KRW.md)
- [PPL.md](PPL.md)
- [DARKSWORD.md](DARKSWORD.md)
