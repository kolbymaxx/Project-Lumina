# DIFF_NOTES — ipad8b kernelcache 23F77 (26.5) ↔ 23G71 (26.6)

**Date:** 2026-08-07  
**Artifacts:** decompressed `kernelcache.release.ipad8b` + extracted `com.apple.driver.AppleAVE2`  
**Rule:** patch themes only — **no triggers / selectors invented**.

## Cluster 1 (P001) — AppleAVE2 size-validation delta — **primary**

| | 26.5 (23F77) | 26.6 (23G71) |
|---|--------------|--------------|
| Kext version | **905.36.1** | **905.40.1** |
| UUID | `EB022251-236E-37E5-A125-9D41B23031B2` | `DBB2853D-972E-398B-821D-7800EDB6107B` |
| `__TEXT_EXEC.__text` size | `0x19c58c` | `0x1a0ccc` (+~18 KiB) |
| File size | 2676216 | 2692608 |

**String evidence (new in 26.6 only — illustrative, not a PoC):**
- Many `AVE_CalcBufSizeOf*` helpers
- Log / assert themes: `size overflow`, `stride overflow`, `DPB size overflow`, `multipass index out of bounds`
- Client check helpers: `AVE_Client_Enc_Check`, `AVE_Client_MCTF_Check`, …

**Named IOKit surface (present in 26.5 binary strings — cited, not invented):**
- `AppleAVE2Driver`
- `AppleAVE2UserClient`
- `newUserClient`

Maps to advisory CVE-2026-64747 (“buffer overflow … improved size validation” / kernel privileges).  
**Still not a working exploit.** Does **not** solve PPL.

## Cluster 2 — other version bumps (secondary / Path B mapping)

From `ipsw kernel kexts --diff` (not exhaustive of every CVE):

| Kext | 26.5 → 26.6 |
|------|-------------|
| AppleAVD | 960 → 962 |
| AppleJPEGDriver | 7.7.9 → 8.1.3 |
| AppleMultitouch* | 9150.2 → 9160.1 |
| AppleH11ANEInterface | 9.511.3 → 9.512.0 |
| IOGPUFamily | 130.14 → 130.16.4 |
| IOSurface | 393.5.7 → 393.5.8 |
| apfs / hfs | patch-level bumps |
| kpi.* | 25.5.0 → 25.6.0 |

Use these as **where else to look** after AVE — do not spray on-device tests.

## What this does / does not change

| Changes | Does **not** change |
|---------|---------------------|
| P001 now has **binary+diff signal** beyond advisory text | Status line (still no public primitive) |
| Step 4 can ask: is `AppleAVE2UserClient` reachable from a 3rd-party app? | Jailbreak / KRW / PPL claims |
| Offline RE on **your** 26.5 window is unblocked | Unsigned restore fiction |

## Next (continuity)

Step 4 — reachability notes for **AppleAVE2UserClient** (entitlements / matching / public VideoToolbox paths). Lab remains **No** until a fail-closed hypothesis cites a concrete external API already documented.
