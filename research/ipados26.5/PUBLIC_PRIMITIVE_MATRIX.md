# Public primitive matrix — A12X / iPadOS 26.5

**Status line (locked until contradicted by evidence):**  
**No matching public primitive for A12X / iPadOS 26.5.**

Docs only. Not wired into `boot/`. Filter: [FILTER.md](FILTER.md).

| Row | Class | Applies to A12X + 26.5? | Notes |
|-----|-------|-------------------------|-------|
| usbliter8 BootROM | Entry | **Not implemented** for t8027 | Path C deferred; DFU identity only |
| XR ramdisk / `boot/` | Lab | **No** | Different board (`n841ap`); do not reuse |
| checkm8 / palera1n | BootROM tooling | **No** as drop-in | A8–A11 teachers |
| Dopamine installer | Userspace JB | **No** on **26.5** | Dopamine 3.0 + momentarius public through **26.0.1** only — teacher/delta, not drop-in |
| momentarius (public A12/A13 PPL) | PPL bypass | **No** on **26.5** | End **26.0.1**; **A12X confirmed** (same A12 init) — [P007](experiments/P007_2601_to_265_delta.md) |
| DarkSword / ClearSword / LARA | Third-party KRW | **Outside / unproven** on 26.5 | Do not port without 26.5 evidence |
| CVE-2026-64747 AVE | Advisory watch | **Watch** | Kernel privileges language; no PoC here |
| CVE-2026-64751 Kernel write | Advisory watch | **Watch** | UAF → write language; no PoC here |
| CVE-2026-43805 IOKit | Advisory watch | **Watch** | Race → write language; no selectors invented |
| CVE-2026-64749 / 43778 Kernel corrupt | Advisory watch | **Watch** | Path B-shaped; control unknown |
| CVE-2026-64709 Kernel disclose | Advisory watch | **Watch** | Leak companion only |
| CVE-2026-43723 MediaRemote | Advisory watch | **Watch** | Root ≠ KRW ≠ PPL |
| Sandbox / libc (64740 / 28973) | Advisory watch | **Note only** | Chain-stage, not entry |
| Public A12/A12X PPL bypass | — | **Absent on 26.5** | Public via momentarius through **26.0.1** only; `pattern_F_` recovery still rejected |

Update rows when FILTER-pass cards change Result; do not upgrade status line from screenshots.
