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
- [../research/kexploit/THEORY.md](../research/kexploit/THEORY.md)
- [../research/mitigations/README.md](../research/mitigations/README.md)

## Theory / RE roadmap (docs only — not wired to boot)

| Doc | Contents |
|-----|----------|
| [RESEARCH_PLAN.md](RESEARCH_PLAN.md) | **Path A/B/C matrix** — lab primary (B) + original KRW+PPL discovery (A) |
| [../research/kexploit/ORIGINAL_KRW_PPL_TRACK.md](../research/kexploit/ORIGINAL_KRW_PPL_TRACK.md) | Path A method: KRW first, PPL second; fail-closed; not `pattern_F_` recovery |
| [../research/kexploit/ANTI_PATTERNS.md](../research/kexploit/ANTI_PATTERNS.md) | Explicit anti-goals for the Dopamine-style ambition |
| [../research/kexploit/HYPOTHESIS_TEMPLATE.md](../research/kexploit/HYPOTHESIS_TEMPLATE.md) | Fail-closed hypothesis cards |
| [ROADMAP_THEORY.md](ROADMAP_THEORY.md) | Staged A→G plan: foothold → RE → kexploit study → mitigations → bootstrap → persistence honesty |
| [../research/mitigations/README.md](../research/mitigations/README.md) | A12 / iOS 18 mitigation table (PAC, PPL, AMFI, SPTM contrast, SEP, …) |
| [../research/kexploit/RE_PRIORITY.md](../research/kexploit/RE_PRIORITY.md) | **Teachers not installers** — palera1n/Dopamine/Coruna map + RE order |
| [../research/kexploit/PUBLIC_PRIMITIVE_MATRIX.md](../research/kexploit/PUBLIC_PRIMITIVE_MATRIX.md) | Bug → SoC → last iOS → why dead on 18.7.5 (**no public match**) |
| [../research/kexploit/THEORY.md](../research/kexploit/THEORY.md) | Bug classes, why BootROM ≠ SpringBoard JB, applicability checklist for 22H311 |
| [../research/kexploit/22H311_NOTES.md](../research/kexploit/22H311_NOTES.md) | Offline kernelcache paths + Mac probe list (docs only; no kexploit claim) |
| [../research/DATA_MOUNT_SSHRD.md](../research/DATA_MOUNT_SSHRD.md) | Exit-76 theory + SSHRD/restore-ramdisk staging research (**no** working A12/18.7.5 Data mount) |
| [research/usbliter8-t8027-bringup.md](research/usbliter8-t8027-bringup.md) | A12X / t8027 SecureROM bring-up — DFU identity live; pwn **not implemented** (stubs TODO-only) |
| [../research/usbliter8-t8027/OFFSET_DERIVATION.md](../research/usbliter8-t8027/OFFSET_DERIVATION.md) | t8027 offset derivation plan — what differs vs t8020, RE order, artifacts needed (**research only**) |
| [../research/usbliter8-t8027/SECUREROM_ACQUISITION.md](../research/usbliter8-t8027/SECUREROM_ACQUISITION.md) | How to seek/verify t8027 SecureROM `4172.0.0.100.14` (securerom.fun et al.; **no blobs**) |
| [../research/usbliter8-t8027/SYMBOL_WORKSHEET.md](../research/usbliter8-t8027/SYMBOL_WORKSHEET.md) | t8027 symbolization worksheet — verified ROM hash; empty candidate tables (**no invented offsets**) |
| [../research/usbliter8-t8027/FIRST_RE_PASS.md](../research/usbliter8-t8027/FIRST_RE_PASS.md) | t8027 first RE pass — strings/PAC/SRAM findings; THEORY labeled (**stubs untouched**) |
| [../research/usbliter8-t8027/PAC_AND_CONTROL_FLOW.md](../research/usbliter8-t8027/PAC_AND_CONTROL_FLOW.md) | t8027 PAC vs t8020 ROP — strategies (THEORY), site plans, Pico go/no-go bar |

Rule unchanged: **nothing under `research/` is imported into `boot/`.**

## Hard gates (current)

1. **Data mount** — 15.1 `mount_apfs` fails on iOS 18 Data (`Program version wrong`); next: newer restore `mount_apfs` then SSHRD-style `seputil` (docs in `DATA_MOUNT_SSHRD.md`)
2. **Kernel exploit for 18.7.5 / A12** — **no matching public primitive**; Path A
   discovery is the **original KRW+PPL track**
   ([kexploit/ORIGINAL_KRW_PPL_TRACK.md](../research/kexploit/ORIGINAL_KRW_PPL_TRACK.md)),
   not `pattern_F_` recovery. Study Dopamine/palera1n/Coruna as teachers
   ([kexploit/RE_PRIORITY.md](../research/kexploit/RE_PRIORITY.md)).
   **Fork 1 / Path A∪B active** (stay on 18.7.5):
   [../research/kexploit/FORK1_STRATEGY.md](../research/kexploit/FORK1_STRATEGY.md) ·
   [RESEARCH_PLAN.md](RESEARCH_PLAN.md)
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

## Public tool applicability (2026-08-01)

For **A12 + iOS 18.7.5**, the only public, real capability in this class is still
**BootROM (usbliter8) + ramdisk**. There is **no** public Dopamine/palera1n-style
jailbreak that applies to this chip + build. arm64e on iOS 18 still needs a
**kernel** (or equivalent) primitive that is not shipping as a user-ready JB
for A12.

### Public tools vs this device

| Tool / exploit | What it is | XR A12 + 18.7.5? | Notes |
|----------------|------------|------------------|-------|
| usbliter8 | BootROM (SecureROM) pwn | **Yes — already have** | Stage finished |
| iCH / similar SSH ramdisk | BootROM → ramdisk SSH | **Yes — here now** | Forensic/dev toolkit, **not** a jailbreak |
| Dopamine (stable) | Rootless JB | **No** | A12/arm64e public path roughly stops ~16.5 |
| Dopamine 2.5 beta / DarkSword-style chatter | Higher iOS via kernel path | **No for drop-in** | Not public / not something to paste into Lumina |
| palera1n | checkm8 chain | **No** | **arm64** A8–A11 (up to ~18.x on those chips), not A12/arm64e |
| YouTube “iOS 18 A12+ jailbreak” | Usually scam / outdated | **Ignore** | Not real public releases |
| Random “kernel root” CVE clips | One-off bugs | **Low** | Often patched, wrong SoC, or not a full chain |

### What is worth applying from others

| Idea | Apply? | How |
|------|--------|-----|
| usbliter8 host / ramdisk flows | **Yes** | Already done; keep mounts, docs, boot wrappers |
| Dopamine architecture (bootstrap, rootless, ElleKit) | **Study only** | Useful **after** kernel r/w — not a shortcut to get it |
| checkm8 / palera1n boot-chain design | **Study only** | Same stage names (iBSS → ramdisk → …); USB path is ours (usbliter8) |
| Random YouTube CVE “roots” | **Low** | Patched / wrong SoC / incomplete |

**Bottom line:** nothing in the public matrix removes the need for
**kernel-side execution** on this device’s **22H311 / T8020 (A12)** kernel
binary (offline artifact noted in
[../research/kexploit/22H311_NOTES.md](../research/kexploit/22H311_NOTES.md)).
That is documentation / future RE — **not** a claim that a kexploit exists.

## Phase A note (2026-08-01) — inventory locked

- Ramdisk = **15.1** (`19B5042h`), `/dev/md0` HFS RO
- System `/mnt1`, Update `/mnt4`, Cryptex `/mnt6` OK → on-disk **18.7.5 (22H311)**
- Data `s2` + `s8` FAIL exit **76**; Preboot/`s3`, bbfs/`s4`, FactoryData/`s7` RO OK
- Kernel RE next: public chains as teachers — **no public A12 18.7.5 primitive**

## Related

- [STATUS.md](STATUS.md)
- [RESEARCH_PLAN.md](RESEARCH_PLAN.md)
- [../artifacts/xr-18.7.5/phase-a-2026-08-01.md](../artifacts/xr-18.7.5/phase-a-2026-08-01.md)
- [../research/CUSTOM_BOOT_NEXT.md](../research/CUSTOM_BOOT_NEXT.md)
- [../research/kexploit/ORIGINAL_KRW_PPL_TRACK.md](../research/kexploit/ORIGINAL_KRW_PPL_TRACK.md)
