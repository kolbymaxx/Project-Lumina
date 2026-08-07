# NEXT — single action pointer

Updated: 2026-08-07  
Rule: [CONTINUITY.md](CONTINUITY.md).

## Current

**Try Step 2:** Extract `kernelcache` (+ AVE / IOKit-related kexts when
identifiable) from both IPSWs under `artifacts/a12x-26.5/extract/{23F77,23G71}/`.

| | Signal |
|---|--------|
| **Success** | Decompressed kernelcaches on disk; paths + sizes noted → **Step 3 diff** |
| **Fail** | Extract tooling missing/broken → fix host tools; do not invent sinks |

## Device lock (clear About photo)

- ProductVersion **26.5** (tap version line for ProductBuildVersion; IPSW candidate **23F77**)
- Model **MTHN2LL/A** → **iPad8,7**
- Serial **DLXYF04EKC48**
- Blurry OCR discarded: MTJD2LL/A / DLXYP0A6KUA6

## Backup

If extract blocked: install/`img4`/`ipsw` tooling, then retry Step 2.

## Done / parked

- Step 1: About identity locked; both IPSWs downloaded in this VM; sizes match ipsw.me
  (`artifacts/a12x-26.5/ipsw/` — see DOWNLOAD.md / HASHES.md)
- 26.5 IPSW **unsigned** — offline RE only, not a restore path
