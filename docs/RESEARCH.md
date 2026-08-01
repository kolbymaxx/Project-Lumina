# Lumina research index

Study-only index. **Nothing here is a working jailbreak on 18.7.5.**
Nothing under `research/` is wired into `boot/lumina-boot.sh`.

## Intended stack (aspirational)

```text
usbliter8 (BootROM / Pico)          [WORKS — A12 entry]
  → iBSS / Recovery                 [WORKS]
  → ramdisk + SSH                   [WORKS — 15.1 restore env]
  → mount System / Data             [System OK; Data BLOCKED]
  → (research) kernel r/w           [NOT DONE — isolated]
  → (hard) PPL / SPTM               [NOT DONE]
  → Dopamine-like bootstrap         [NOT DONE]
```

## Roles

| Project | Role for Lumina | Applies on XR 18.7.5 / A12? |
|---------|-----------------|------------------------------|
| **usbliter8** | BootROM entry; pwned DFU + CUSTOM_BOOT | **Yes** — live entry |
| **XR ramdisk** (hsbugss) | Tethered ramdisk + SSH; volume mounts | **Yes** for boot/SSH; Data mount tooling is 15.1-limited |
| **checkm8** | Historical A11-and-older BootROM knowledge | **No** as exploit on A12 — learning only |
| **palera1n** | A8–A11 tethered/semi tooling patterns | **No** as drop-in on A12/18.7.5 — learning only |
| Dopamine | Bootstrap / rootless / jailbreakd architecture | Architecture only after k r/w exists |
| DarkSword / darksword-kexploit | Kernel r/w research | Study only; isolated under `research/kexploit/` |
| LARA | Userspace toolbox on DarkSword | Public matrix ends **18.7.1**; 18.7.5 outside |

Notes dirs:
- [../research/checkm8/README.md](../research/checkm8/README.md)
- [../research/palera1n/README.md](../research/palera1n/README.md)
- [../research/kexploit/README.md](../research/kexploit/README.md)

## Hard gates (current)

1. **Data mount** — 15.1 `mount_apfs` fails on iOS 18 Data (`Program version wrong`)
2. **Kernel exploit for 18.7.5 / A12** — not available / not proven; keep isolated
3. **Userspace bootstrap** — no Sileo/Dopamine path until primitives exist

Crossing these gates is future work. Document progress in [STATUS.md](STATUS.md).
Do **not** wire kexploit or checkm8/palera1n code into the boot path.

## Version matrix (short)

| Source | Claimed / role | vs 18.7.5 XR |
|--------|----------------|--------------|
| usbliter8 | A12/A13 SecureROM | Entry works |
| XR ramdisk | n841 tethered ramdisk | Boot + SSH works; Data blocked |
| checkm8 | ≤A11 BootROM | Knowledge only |
| palera1n | A8–A11 jailbreak tooling | Knowledge only |
| LARA | ≤18.7.1 (and some 26.0.x) | **18.7.2+ unsupported** |
| darksword-kexploit | Broad claim; 15.x offsets called out | Unproven for 22H311 |

## Phase A note (2026-08-01)

- Ramdisk = **15.1** (`19B5042h`), `/dev/md0` HFS RO
- System `disk0s1s1` → `/mnt1` OK; on-disk OS **18.7.5 (22H311)**
- Data `disk0s1s2` FAIL; preboot-ish `disk0s1s5` → `/mnt4` OK
- Kernel under `/mnt1` Caches/Kernels not found this session

## Related

- [STATUS.md](STATUS.md)
- [../artifacts/xr-18.7.5/phase-a-2026-08-01.md](../artifacts/xr-18.7.5/phase-a-2026-08-01.md)
- [../research/CUSTOM_BOOT_NEXT.md](../research/CUSTOM_BOOT_NEXT.md)
