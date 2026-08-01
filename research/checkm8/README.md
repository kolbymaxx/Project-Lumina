# checkm8 — knowledge only (not for A12 Lumina boot)

**Not wired into `boot/`.** Not an exploit path for the live XR (A12).

## What checkm8 is
- BootROM exploit class affecting many Apple devices **through A11**
- Foundation for tools such as checkra1n / parts of the A11 jailbreak ecosystem
- Demonstrates USB DFU race / DMA-style SecureROM compromise patterns

## Stage map — checkm8 pipeline vs Lumina

| Stage | checkm8 / checkra1n-style (≤A11) | Lumina (A12 XR) |
|-------|----------------------------------|-----------------|
| BootROM entry | checkm8 pwned DFU | **usbliter8** pwned DFU |
| Early boot load | iBSS/iBoot patches via host | Raw iBSS via CUSTOM_BOOT + known-good payloads |
| Recovery / ramdisk | Often checkra1n/palera1n ramdisk flows | hsbugss XR ramdisk (15.1 tooling) + SSH |
| Live OS kernel | Boot-time patching / subsequent chain | **Not reached** for SpringBoard JB |
| Userspace bootstrap | checkra1n ecosystem / forks | Not started — needs kernel-capable path |

## What to RE from open checkm8-era code
- DFU host sequencing and pwned-serial conventions
- How projects separate **entry** vs **boot patch** vs **bootstrap**
- Why tethered sessions expect re-pwn after reboot
- Host-tool shape (libusb/pyusb) vs Pico bit-bang entry (our case)

## What not to port blindly
- checkm8 USB race payloads — wrong SecureROM generation
- A11 patch sets / offsets onto A12 images
- Assumptions that pwned DFU implies Data decryption or SEP access

## SEP / passcode / Data lessons
- BootROM entry historically **does not** equal SEP compromise
- Even with volume mounts, **data-protection classes** may keep files opaque without passcode-derived keys
- Our live blocker today is earlier: **15.1 `mount_apfs` cannot mount iOS 18 Data at all**
- Lesson: plan Data access as (1) tooling/mount version, then (2) SEP/file-protection reality — separately

## What we can learn
- DFU host sequencing and pwned-DFU serial conventions
- Separation of BootROM entry vs later iBSS/iBoot/kernel stages
- Why “pwned DFU ≠ jailbreak”
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

## See also
- [../palera1n/README.md](../palera1n/README.md)
- [../../docs/ROADMAP_THEORY.md](../../docs/ROADMAP_THEORY.md)
