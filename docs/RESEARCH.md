# Lumina research index

This file indexes **study-only** codebases. Nothing here is wired into
`boot/lumina-boot.sh`. Do not claim a working kexploit or Sileo on
**iOS 18.7.5 (22H311)** from these notes.

## Intended Lumina stack

```text
usbliter8 (BootROM / Pico)
  → iBSS / Recovery
  → known-good ramdisk + SSH   [WORKS on XR]
  → (research) kernel r/w
  → (hard) PPL / SPTM
  → Dopamine-like bootstrap / jailbreakd
```

## Codebase roles

| Project | URL | Role for Lumina |
|---------|-----|-----------------|
| usbliter8 | https://github.com/prdgmshift/usbliter8 | BootROM entry; pwned DFU + CUSTOM_BOOT |
| usbliter8-xr-ramdisk | https://github.com/hsbugss/usbliter8-xr-ramdisk | Known-good XR ramdisk boot + SSH |
| Dopamine | https://github.com/opa334/Dopamine | Bootstrap / rootless / jailbreakd **architecture** after k r/w exists |
| Relaxin | Dopamine-family for iOS 17.x | Study only; wrong major for 18.7.5 |
| Coruna | older ≤~17.2.1 chains | **PPL RE reference**, not a drop-in |
| DarkSword (original) | https://github.com/htimesnine/DarkSword-RCE | Upstream exploit logic source |
| darksword-kexploit | https://github.com/opa334/darksword-kexploit | ObjC reimplementation; study k r/w |
| LARA | https://github.com/rooootdev/lara | Userspace toolbox patterns on DarkSword |

## Version matrix vs XR target (18.7.5 / 22H311)

| Source | Claimed window | Relevance to 18.7.5 |
|--------|----------------|---------------------|
| usbliter8 | A12/A13 SecureROM (silicon) | Entry works on XR |
| hsbugss XR ramdisk | XR / n841ap tethered ramdisk | Boot + SSH works |
| opa334/darksword-kexploit README | "Supposed to support iOS 15.0 - 26.0.1"; offsets hardcoded for 15.x(?) | **Not proven** for 22H311; study only |
| LARA | iOS 17.0–**18.7.1** and 26.0–26.0.1 | **18.7.2+ explicitly Not Supported** → 18.7.5 is outside LARA's matrix |
| Dopamine | packaging / bootstrap after primitives | Architecture reference only until k r/w + PPL path exists |

Hard gate: public LARA/DarkSword tooling does **not** currently authorize a
claim of kernel r/w → userspace jailbreak on **18.7.5**. Treat any kexploit
work as isolated research under `research/kexploit/`.

## Isolated study tree

Expected local layout (operator clone; optional in this repo):

```text
research/kexploit/
  README.md                 # this tree's rules
  SOURCES.md                # clone commands + notes
  darksword-kexploit/       # optional local clone (gitignored if large)
  notes/                    # operator notes from Phase A builds
```

Rules:

1. Never import kexploit sources into `boot/` or ramdisk payload scripts.
2. Do not run kexploit against the live XR until Phase A build notes exist.
3. Record claimed vs observed version windows in STATUS after any experiment.

## Phase A note (2026-08-01)

Working hsbugss XR ramdisk is a **15.1** restore environment (`19B5042h`).
It can mount System (`disk0s1s1` → `/mnt1`, on-disk **18.7.5 / 22H311**) but
**cannot** mount Data (`disk0s1s2`) — `mount_apfs: Program version wrong`.
Any Data-dependent tooling needs a newer ramdisk/`mount_apfs` first.

## Related Lumina docs

- [STATUS.md](STATUS.md) — live device status and Phase A notes
- [../artifacts/xr-18.7.5/phase-a-2026-08-01.md](../artifacts/xr-18.7.5/phase-a-2026-08-01.md)
- [../research/CUSTOM_BOOT_NEXT.md](../research/CUSTOM_BOOT_NEXT.md) — earlier CUSTOM_BOOT host research
- [../research/kexploit/README.md](../research/kexploit/README.md) — isolation rules
