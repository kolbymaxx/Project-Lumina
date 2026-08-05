# Vulnerable-target sandbed (H3) — pre-18.7.2 DS-K

**When to use:** after `FAIL_PATCHED` / `FAIL_OFFSETS` on daily **22H311**, or if operator chooses **E3** up front.

**Rationale:** literature places DarkSword kernel PE fixes at **iOS 18.7.2**.  
A disposable device (or restore) on **18.4–18.6.x / any 18.x < 18.7.2** is the rational **DS-K** jailbreak sandbed — not the daily 18.7.5 phone.

## Goals

1. Get a device/build where public DS-K has a **chance** to demonstrate KRW.  
2. Record exact ProductVersion / ProductBuildVersion.  
3. Create `docs/BUILD_<build>.md` for that identity (copy structure from `BUILD_22H311.md`).  
4. Re-run [LAB_DSK.md](LAB_DSK.md) there.

## Constraints

- Own device / legal restore only.  
- Prefer disposable hardware — do not brick the daily driver casually.  
- Still **no TrollStore** on 17.0.1+ / 18.x — entry limits from [ENTRY.md](ENTRY.md) remain.  
- No DS-Full packaging.  
- No invented offsets — derive for **that** build or mark TODO.

## Suggested window (literature)

| Window | Why |
|--------|-----|
| **18.4 – 18.6.x** | Inside public DarkSword kit support narrative; before 18.7.2 PE fix |
| **18.7.0 – 18.7.1** | Still before 18.7.2 PE fix (**literature**) — verify on device |
| **≥ 18.7.2** | Expect PE dead (**literature**) — only useful as negative control |

Exact IPSW choice is operator-owned; do not commit IPSW/firmware blobs.

## Checklist

- [ ] Hardware identified (model / SoC — prefer A12 `n841` if possible for transferability)  
- [ ] Build < 18.7.2 confirmed on-device  
- [ ] `docs/BUILD_<id>.md` created with hashes when kernelcache available  
- [ ] DS-K tree cloned; offsets policy applied for **that** build  
- [ ] Entry E1/E2 chosen for sandbed  
- [ ] LAB_DSK run → STATUS row  

## Success

`SUCCESS_KRW` on the sandbed → PPL research targets **that** build ([PPL.md](PPL.md)).  
Daily 18.7.5 remains a separate “needs different PE” problem.

## Related

- [STATUS.md](STATUS.md)
- [DARKSWORD.md](DARKSWORD.md)
- [LAB_DSK.md](LAB_DSK.md)
- [BUILD_22H311.md](BUILD_22H311.md)
