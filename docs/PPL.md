# PPL — A12 (blocked on missing KRW)

**Rule (M5):** do not expand PPL **implementation** before `SUCCESS_KRW` on any build.

Until then this file is a literature map + blocker statement.

| Fact | State |
|------|--------|
| SoC | A12 — **PPL** (not SPTM) |
| Daily driver | 18.7.5 / 22H311 |
| Public iOS 18 PPL bypass | **None** (public catalogs) |
| Prerequisite | Demonstrated KRW via **DS-K** (or other) on some build |
| Status | **Blocked on missing KRW** |

## Literature map (short)

| Era | Public A12-relevant note | On 18.7.x |
|-----|--------------------------|-----------|
| Dopamine + dmaFail | GFX/DMA → PPL memory write | Fixed **16.6** |
| iOS 18 catalogs | No public PPL/SPTM bypass | Blocked |
| Relaxin `ppl-dma-a12` | Teacher vocabulary; confirm windows earlier | Not an installer here |

Deep notes: [../research/ppl/](../research/ppl/).

## When KRW_SUCCESS lands

1. Re-target PPL research to **the build that has KRW** (may be sandbed, not 22H311).  
2. Observational RO probes only until a cited mechanism exists (`src/ppl/` stubs).  
3. Update STATUS — never “essay = bypass.”

## Related

- [STATUS.md](STATUS.md)
- [KRW.md](KRW.md)
- [JB_SHAPE.md](JB_SHAPE.md)
