# PPL research — A12 / iPhone XR / 22H311

Isolated study of **Page Protection Layer** strategies for this device and
build. **Not a bypass. Not wired into `boot/`.**

| Fact | Status |
|------|--------|
| SoC | A12 (`t8020`) — **PPL present, SPTM not the A12 model** |
| Build | iOS **18.7.5 (22H311)** |
| Public PPL bypass on iOS 18 | **None** (public catalogs; see strategy doc) |
| Prerequisite for useful PPL work | Prior **kernel R/W** (or equivalent) — also **not** present |

## Start here

| Doc | Role |
|-----|------|
| [../../docs/PPL.md](../../docs/PPL.md) | Operator-facing PPL summary + blocked exit criteria |
| [STRATEGY_22H311.md](STRATEGY_22H311.md) | Explicit PPL strategy for this build (may conclude **blocked**) |
| [HISTORICAL_A12.md](HISTORICAL_A12.md) | Historical A12 PPL approaches vs what changed by 18.7.x |
| [../../src/ppl/](../../src/ppl/) | Observational stubs only (no fake success) |

## Related (other trees)

- Mitigations table: [../mitigations/README.md](../mitigations/README.md)
- KRW hunt / matrix: [../kexploit/](../kexploit/)
- Viability notes: [../kexploit/viability/](../kexploit/viability/)
- Relaxin A12 DMA teacher: [../kexploit/RELAXIN_042_A12_DMA.md](../kexploit/RELAXIN_042_A12_DMA.md)

## Rules

1. Do not claim a PPL bypass without a **cited mechanism** and a **test plan**.
2. Do not cargo-cult A15+ **SPTM/TXM** paths onto A12.
3. PPL work comes **after** a live KRW primitive — essays alone do not clear Stage C.
4. Keep clones and closed IPA analysis under `research/`; never import into `boot/`.
