# palera1n — A8–A11 reference only

**Not wired into `boot/`.** Not a drop-in jailbreak for A12 / iOS 18.7.5.

## What palera1n is
- Public tethered / semi-tethered tooling built around **checkm8-capable**
  devices (**A8–A11**)
- Useful reference for: ramdisk workflows, bootstrap packaging ideas, and
  how a full chain is staged after BootROM entry

## Stage map — palera1n-style vs Lumina

| Stage | palera1n (A8–A11) | Lumina (A12 / 18.7.5) |
|-------|-------------------|------------------------|
| BootROM | checkm8 | **usbliter8 only** |
| Patched boot objects | Their iBoot/iBSS/patch strategy | Our known-good iBSS + ramdisk payloads |
| Ramdisk SSH | Common pattern | **Works** today (15.1 restore env) |
| Data / fakefs / bind mounts | Project-specific | **Data mount blocked** on current tooling |
| Bootstrap (Sileo, etc.) | Integrated for supported devices | **Out of scope** until kernel-capable path exists |
| Persistence | Tethered / semi depending on setup | Honest default: **fully tethered** via usbliter8 |

## What to RE from open palera1n-era code
- Boot **flow orchestration** (order of loads, waits, failure handling)
- How ramdisk + bootstrap artifacts are packaged
- User-facing tether expectations (re-pwn, cable rules)
- Patch **strategy categories** (image4, AMFI-related boot patches) as *labels to investigate* — not blobs to copy onto A12

## What not to port blindly
- checkm8 dependency and A11 patch blobs
- Bootstrap packages assuming their kernel patch set
- Any assumption that their Data/fakefs approach works with our 15.1 `mount_apfs`

## SEP / passcode lessons relevant to Data
- palera1n-era docs/community knowledge often stress: unlocking / passcode state matters for useful Data
- For Lumina: first clear the **mount_apfs version** blocker; then treat SEP/file-protection as the next research gate
- Do not equate ramdisk root with plaintext of protected user files

## What we can learn
- How a project separates BootROM pwn → ramdisk → bootstrap
- Tethered-session UX (re-pwn after reboot)
- SSH ramdisk bring-up and artifact layout patterns
- Why device generation and iOS major matter at every stage after entry

## What does **not** apply on Lumina’s XR (A12 / 18.7.5)
- palera1n targets **A8–A11** via checkm8 — **not A12**
- Cannot replace usbliter8 as the BootROM entry on this phone
- Cannot be expected to mount iOS 18 Data from a 15.1 restore ramdisk
- Cannot be cited as evidence of Sileo / jailbreak on 18.7.5 A12

## Lumina policy
- usbliter8 = A12 BootROM entry only (live)
- palera1n = A8–A11 reference reading only
- Keep clones/notes under `research/palera1n/`; never mix into `boot/`

## See also
- [../checkm8/README.md](../checkm8/README.md)
- [../../docs/ROADMAP_THEORY.md](../../docs/ROADMAP_THEORY.md)
