# Extract inventory — 26.5 (23F77) vs 26.6 (23G71)

**Date:** 2026-08-07  
**Lab board:** iPad8,7 (MTHN2LL/A) — prefer `kernelcache.release.ipad8b` (cellular family); keep `ipad8` for contrast.  
**Tooling:** `unzip` + `ipsw kernel dec` (blacktop ipsw v3.1.707). Binaries gitignored under `extract/`.

## Paths

| Artifact | 23F77 | 23G71 |
|----------|-------|-------|
| Raw IM4P kernel (WiFi family) | `23F77/kernelcache.release.ipad8` | `23G71/kernelcache.release.ipad8` |
| Raw IM4P kernel (cellular family) | `23F77/kernelcache.release.ipad8b` | `23G71/kernelcache.release.ipad8b` |
| Decompressed Mach-O | `…/kernelcache.release.ipad8b.macho/*.decompressed` | same under 23G71 |
| AVE firmware IM4P | `AppleAVE2FW_H11G.im4p` | same name (byte-differs; same length 2417833) |

## Sizes (decompressed Mach-O)

| Kernel | 23F77 | 23G71 | Δ |
|--------|------:|------:|--:|
| ipad8 | 60964864 | 61030400 | +65536 |
| ipad8b | 61898752 | 61964288 | +65536 |

Both are `Mach-O 64-bit arm64e` filetype=12 (kernelcache).

## Notes

- AVE **firmware** IM4P differs across builds — still not a userspace trigger; driver/kext clients live elsewhere (kernelcache / DSC). Do not invent IOKit selectors.
- Step 3 = structured diff on **ipad8b** decompressed pair first (this unit is cellular).
