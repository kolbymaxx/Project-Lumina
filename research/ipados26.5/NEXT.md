# NEXT — single action pointer

Updated: 2026-08-07  
Rule: [CONTINUITY.md](CONTINUITY.md).

## Current

**Try Step 3:** Structured diff of decompressed **`kernelcache.release.ipad8b`**
Mach-Os: `artifacts/a12x-26.5/extract/23F77/…decompressed` vs `23G71/…`.
Produce a short patch-cluster note (≤10 interesting symbol/hunk themes) —
**no triggers**.

| | Signal |
|---|--------|
| **Success** | Diff note committed under `research/ipados26.5/experiments/` or `artifacts/…/DIFF_NOTES.md` with cited symbols → **Step 4 reachability** |
| **Fail** | Diff tooling inadequate → install/use `ipsw macho` / bindiff alternative; retry Step 3 |

## Device lock

- ProductVersion **26.5** (tap version for build; IPSW **23F77** used for delta)
- Model **MTHN2LL/A** → **iPad8,7** / Serial **DLXYF04EKC48**

## Backup

If kernel diff blocked: diff AVE IM4P payloads only (P001 firmware side) — still no triggers.

## Done / parked

- Step 1: About identity + IPSWs downloaded/hashed
- Step 2: kernelcaches + AVE extracted; ipad8b Mach-Os decompressed (`extract/EXTRACT.md`)
