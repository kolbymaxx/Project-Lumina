# Public primitive matrix — A12X / iPadOS 26.5

**Status line (locked until contradicted by evidence):**  
**No matching public primitive for A12X / iPadOS 26.5.**

Docs only. Not wired into `boot/`. Filter: [FILTER.md](FILTER.md).

| Row | Class | Applies to A12X + 26.5? | Notes |
|-----|-------|-------------------------|-------|
| usbliter8 BootROM | Entry | **Not implemented** for t8027 | Path C deferred; DFU identity only |
| XR ramdisk / `boot/` | Lab | **No** | Different board (`n841ap`); do not reuse |
| checkm8 / palera1n | BootROM tooling | **No** as drop-in | A8–A11 teachers |
| Dopamine installer | Userspace JB | **No** | Needs KRW+PPL; architecture study only |
| DarkSword / LARA | Third-party | **Outside / unproven** | Do not port without 26.5 evidence |
| CVE-2026-64747 AVE | Advisory watch | **Watch** | Kernel privileges language; no PoC here |
| CVE-2026-64751 Kernel write | Advisory watch | **Watch** | UAF → write language; no PoC here |
| CVE-2026-43805 IOKit | Advisory watch | **Watch** | Race → write language; no selectors invented |
| CVE-2026-64749 / 43778 Kernel corrupt | Advisory watch | **Watch** | Path B-shaped; control unknown |
| CVE-2026-64709 Kernel disclose | Advisory watch | **Watch** | Leak companion only |
| CVE-2026-43723 MediaRemote | Advisory watch | **Watch** | Root ≠ KRW ≠ PPL |
| Sandbox / libc (64740 / 28973) | Advisory watch | **Note only** | Chain-stage, not entry |
| Public A12/A12X PPL bypass | — | **Absent** | `pattern_F_` recovery rejected |

Update rows when FILTER-pass cards change Result; do not upgrade status line from screenshots.
