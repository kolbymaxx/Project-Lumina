# checkm8 — knowledge only (not for A12 Lumina boot)

**Not wired into `boot/`.** Not an exploit path for the live XR (A12).

## What checkm8 is
- BootROM exploit class affecting many Apple devices **through A11**
- Foundation for tools such as checkra1n / parts of the A11 jailbreak ecosystem
- Demonstrates USB DFU race / DMA-style SecureROM compromise patterns

## What we can learn
- DFU host sequencing and pwned-DFU serial conventions
- Separation of BootROM entry vs later iBSS/iBoot/kernel stages
- Why “pwned DFU ≠ jailbreak” — entry only starts the chain
- Historical host-tool shapes (ipwndfu-era) vs modern pyusb helpers

## What does **not** apply on Lumina’s XR (A12 / 18.7.5)
- checkm8 itself does **not** run on A12 SecureROM
- A12 entry for Lumina is **usbliter8**, not checkm8
- No checkm8 payload, patch, or host script belongs in `boot/lumina-boot.sh`
- Success against A11 devices does not imply anything about 18.7.5 A12 Data
  mounts, PPL, or userspace bootstrap

## Lumina policy
- Keep any local clones or notes under `research/checkm8/` only
- Document takeaways here; never claim checkm8-based jailbreak on this XR
