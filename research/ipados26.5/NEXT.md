# NEXT — single action pointer

Updated: 2026-08-07  
Rule: [CONTINUITY.md](CONTINUITY.md).

## Current

**Try Step 4 (P001 lead):** Reachability of **`AppleAVE2UserClient`** on iPadOS 26.5 /
A12X — from binary strings + public headers / VideoToolbox / entitlements docs.
Answer: third-party app reachable? **yes / no / unknown** with citation.

| | Signal |
|---|--------|
| **Success** | Cited path (or explicit entitlement gate) written into P001 / a reachability note → design Step 5 fail-closed hyp **or** demote if entitled-only |
| **Fail** | No public surface found → mark Unknown/blocked on app reachability; try **P002** kernel write cluster next |

## Device lock

- ProductVersion **26.5** · Model **MTHN2LL/A** (`iPad8,7`) · Serial **DLXYF04EKC48**
- IPSW delta: **23F77 ↔ 23G71**

## Backup

If AVE reachability is hard-blocked (entitled-only): **P002** offline cluster on kernel UAF/write CVEs (still no triggers).

## Done / parked

- Step 1–2: IPSWs + extract
- Step 3: [`experiments/DIFF_NOTES_23F77_23G71.md`](experiments/DIFF_NOTES_23F77_23G71.md) — AppleAVE2 **905.36.1 → 905.40.1** + size-validation string delta
