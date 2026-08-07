# Writeup watchlist — A12X / iPadOS 26.5

Public artifacts that would **change** [PUBLIC_PRIMITIVE_MATRIX.md](PUBLIC_PRIMITIVE_MATRIX.md) status or unblock lab.

| Watch | Why it matters | Action if found |
|-------|----------------|-----------------|
| Kernel exp with clear **26.5-compatible** / **fixed-in-26.6** bounds + A12/A12X plausibility | May become FILTER-pass Path A/B candidate | New P00N card; Lab only after (1)(2)(3) |
| Public **A12/A12X PPL bypass** with recipe | Path A stage 2 only **after** KRW | Document under mitigations cross-link; never as entry |
| Detailed writeup: CVE-2026-64747 (AVE), 64751, 43805, 43723 | Turns advisory into sink/reachability | Audit card; still fail-closed |
| Confirm 26.5 IPSW download / hashes for this board | Unblocks offline diff | Step 1–2 in RESEARCH_PLAN_26.5 |
| usbliter8 t8027 `PWND:[usbliter8]` proof | Path C foothold | Label device/OS; do not merge into PE claims |
| NVD / project-zero / conference talks citing these CVEs | Secondary cites | Intake note; FILTER again |

## Ignore as status movers
- YouTube “iOS 26 jailbreak”
- Discord screenshots
- Advisory mirrors with no technical content
- XR 18.7.x writeups unless explicitly re-FILTERED for A12X/26.5
