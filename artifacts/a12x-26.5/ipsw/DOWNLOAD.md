# IPSW downloads (local / cloud VM — do not commit .ipsw)

Board family: iPad Pro 12.9" 3rd gen A12X/A12Z — shared restore:
`iPad_Pro_A12X_A12Z_*_Restore.ipsw` (covers iPad8,5–8,8).

## Lab unit (clear About photo 2026-08-07) — locked

| Field | Value |
|-------|--------|
| Name | Kolby's iPad |
| ProductVersion | **26.5** |
| Model Name | iPad Pro (12.9-inch) (3rd generation) |
| Model Number | **MTHN2LL/A** |
| Serial | **DLXYF04EKC48** |
| Identifier (from order#) | **iPad8,7** (Wi‑Fi + Cellular, 64 GB / A2014 Space Gray) |
| ProductBuildVersion | **not yet locked** — tap the “26.5” line in About; marketing 26.5 → candidate **23F77** (26.5.2 would show as 26.5.2 / **23F84**) |

Discarded OCR from blurry earlier photo: MTJD2LL/A / DLXYP0A6KUA6.

DFU identity from prior Mac capture (ECID/CPID) remains in
`docs/research/usbliter8-t8027-bringup.md` — do not invent ECID from serial.

## Files

| Version | Build | Signed | Expected size | File |
|---------|-------|--------|---------------|------|
| 26.5 | 23F77 | **No** (offline RE only) | 10154609992 | `iPad_Pro_A12X_A12Z_26.5_23F77_Restore.ipsw` |
| 26.6 | 23G71 | Yes | 10222057161 | `iPad_Pro_A12X_A12Z_26.6_23G71_Restore.ipsw` |

CDN (ipsw.me / Apple):
- 26.5: `https://updates.cdn-apple.com/2026SpringFCS/fullrestores/122-38979/783ABF88-C9D6-48FA-8A80-F962B49D2F98/iPad_Pro_A12X_A12Z_26.5_23F77_Restore.ipsw`
- 26.6: `https://updates.cdn-apple.com/2026SummerFCS/fullrestores/140-57189/B665260C-B9E0-4355-9A08-F93FB8FDC17C/iPad_Pro_A12X_A12Z_26.6_23G71_Restore.ipsw`

Do **not** use unsigned 26.5 IPSW to invent a restore/downgrade path.
