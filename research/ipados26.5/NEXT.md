# NEXT — single action pointer

Updated: 2026-08-07  
Rule: [CONTINUITY.md](CONTINUITY.md).

## Current

**Try Step 4 (P001 lead):** Reachability of **`AppleAVE2UserClient`** on iPadOS 26.5 /
A12X — entitlements / VideoToolbox / public API cite.  
Dopamine 3.0 does **not** replace this (ClearSword ends **26.0.1**).

| | Signal |
|---|--------|
| **Success** | Cited path or explicit entitlement gate → Step 5 hyp **or** demote if entitled-only |
| **Fail** | No public surface → try **P002** kernel write cluster |

## Device lock

- ProductVersion **26.5** · Model **MTHN2LL/A** (`iPad8,7`) · Serial **DLXYF04EKC48**
- IPSW delta: **23F77 ↔ 23G71**

## Backup

If AVE reachability hard-blocked: **P002** offline cluster (no triggers).

## Done / parked

- Step 1–3: IPSW + extract + AppleAVE2 diff
- **P007:** Dopamine 3.0 IPA+source ingested — **teacher / not 26.5 installer**
  ([experiments/P007_dopamine3_teacher_not_installer.md](experiments/P007_dopamine3_teacher_not_installer.md))
