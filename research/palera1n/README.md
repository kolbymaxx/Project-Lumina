# palera1n — A8–A11 reference only

**Not wired into `boot/`.** Not a drop-in jailbreak for A12 / iOS 18.7.5.

## What palera1n is
- Public tethered / semi-tethered tooling built around **checkm8-capable**
  devices (**A8–A11**)
- Useful reference for: ramdisk workflows, bootstrap packaging ideas, and
  how a full chain is staged after BootROM entry

## What we can learn
- How a project separates BootROM pwn → ramdisk → bootstrap
- User-facing tethered-session expectations (re-pwn after reboot)
- Patterns for SSH ramdisk bring-up and artifact layout
- Why device generation and iOS major matter for every stage after entry

## What does **not** apply on Lumina’s XR (A12 / 18.7.5)
- palera1n targets **A8–A11** via checkm8 — **not A12**
- Cannot replace usbliter8 as the BootROM entry on this phone
- Cannot be expected to mount iOS 18 Data from a 15.1 restore ramdisk
- Cannot be cited as evidence of Sileo / jailbreak on 18.7.5 A12

## Lumina policy
- usbliter8 = A12 BootROM entry only (live)
- palera1n = A8–A11 reference reading only
- Keep clones/notes under `research/palera1n/`; never mix into `boot/`
