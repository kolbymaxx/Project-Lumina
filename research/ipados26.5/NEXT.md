# NEXT — single action pointer

Updated: 2026-08-07  
Rule: [CONTINUITY.md](CONTINUITY.md).

## Current

**Try Step 1:** On the A12X iPad, lock **ProductVersion** + **ProductBuildVersion**
(and model). On the Mac, check whether **26.5.x** and **26.6** IPSWs for this
board are downloadable / already local.

| | Signal |
|---|--------|
| **Success** | Build string written into `docs/STATUS.md` + note here; IPSW yes/no recorded |
| **Fail** | Cannot obtain 26.5 IPSW → **hard block** on offline diff → switch to **Backup** |

## Backup (only if Step 1 IPSW = no)

**Watchlist poll for P001 (AVE CVE-2026-64747):** search for any **citable**
writeup/PoC discussion with version bounds — docs only; do not invent triggers.

| | Signal |
|---|--------|
| **Success** | Link + bounds added to P001 Source; still Lab = No until binary evidence |
| **Fail** | Nothing citable → leave P001 Unknown; try **P002** watchlist poll next |

## Done / parked

_(none yet)_
