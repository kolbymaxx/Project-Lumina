# NEXT — single action pointer

Updated: 2026-08-08  
Rule: [CONTINUITY.md](CONTINUITY.md).

## Current

**Primary — Eng Step 1 (still the real blocker):** On the A12X iPad, lock **ProductVersion** +
**ProductBuildVersion** (and model). On the Mac, check whether **26.5.x** and **26.6** IPSWs for this
board are downloadable / already local. **Mac + hardware** — not cloud-feasible.

| | Signal |
|---|--------|
| **Success** | Build string written into `docs/STATUS.md` + note here; IPSW yes/no recorded |
| **Fail** | Cannot obtain 26.5 IPSW → **hard block** on offline diff → switch to **Backup** |

## Backup (only if Step 1 IPSW = no)

Tier 1 watchlist poll **done** (2026-08-08): P001/P002/P003 — bounds confirmed, **no PoC** in any
secondary source. See [experiments/POLL_2026-08-08_tier1.md](experiments/POLL_2026-08-08_tier1.md).
All stay **Unknown / Lab = No**; status line unchanged.

Next backup leads (lower-ranked; Path B / companion): **P004** (kernel corrupt cluster) → **P005**
(disclose) → **P006** (MediaRemote root). Docs only; do not invent triggers.

| | Signal |
|---|--------|
| **Success** | Link + bounds added to card Source; still Lab = No until binary evidence |
| **Fail** | Nothing citable → leave card Unknown; move to next |

## Done / parked

- 2026-08-08 — Tier 1 watchlist poll (P001/P002/P003): bounds confirmed, no PoC. Status line unchanged.
