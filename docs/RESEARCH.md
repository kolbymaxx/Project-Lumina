# Lumina research index

Study-only index. **Nothing here is a working jailbreak** on XR 18.7.5 or iPad 26.5.
Nothing under `research/` is wired into `boot/lumina-boot.sh`.

## Active track (2026-08-07) — A12X / iPadOS 26.5

| Item | Path |
|------|------|
| Canonical plan | [RESEARCH_PLAN_26.5.md](RESEARCH_PLAN_26.5.md) |
| Hunt tree (P00N) | [../research/ipados26.5/](../research/ipados26.5/) |
| FILTER | [../research/ipados26.5/FILTER.md](../research/ipados26.5/FILTER.md) |
| 26.6 intake | [../research/ipados26.5/experiments/INTAKE_26.6.md](../research/ipados26.5/experiments/INTAKE_26.6.md) |
| SecureROM Path C | [research/usbliter8-t8027-bringup.md](research/usbliter8-t8027-bringup.md) |

**Status:** no matching public primitive for **A12X / iPadOS 26.5**.  
usbliter8 A12X **not** required for Path A/B.

## XR stack (parked Path A — still live BootROM lab)

```text
usbliter8 (BootROM / Pico)          [WORKS — A12 XR entry]
  → iBSS / Recovery                 [WORKS]
  → ramdisk + SSH                   [WORKS — 15.1 restore env]
  → mount System / Data             [System OK; Data BLOCKED]
  → (research) kernel r/w           [NOT DONE — parked]
  → (hard) PPL / SPTM               [NOT DONE]
  → Dopamine-like bootstrap         [NOT DONE]
```

## Roles

| Project | Role for Lumina | XR 18.7.5 / A12? | A12X / 26.5? |
|---------|-----------------|------------------|--------------|
| **usbliter8** | BootROM entry | **Yes** — live | **Not implemented** (Path C) |
| **XR ramdisk** | Tethered SSH | **Yes** | **No** — wrong board |
| **ipados26.5 hunt** | 26.6 delta → PE/KRW watches | N/A | **Yes** — docs/RE primary |
| **checkm8** | ≤A11 BootROM knowledge | Learning only | Learning only |
| **palera1n** | A8–A11 patterns | Learning only | Learning only |
| Dopamine | Bootstrap architecture | After k r/w | After k r/w + PPL |
| DarkSword / LARA | Kernel study | Study only (`kexploit/`) | Do not port without FILTER |

Notes dirs:
- [../research/ipados26.5/README.md](../research/ipados26.5/README.md)
- [../research/checkm8/README.md](../research/checkm8/README.md)
- [../research/palera1n/README.md](../research/palera1n/README.md)
- [../research/kexploit/README.md](../research/kexploit/README.md)
- [../research/kexploit/THEORY.md](../research/kexploit/THEORY.md)
- [../research/mitigations/README.md](../research/mitigations/README.md)
- [../research/usbliter8-t8027/](../research/usbliter8-t8027/)

## Theory / RE roadmap (docs only — not wired to boot)

| Doc | Contents |
|-----|----------|
| [RESEARCH_PLAN_26.5.md](RESEARCH_PLAN_26.5.md) | **Active:** A12X / 26.5 Path A/B/C + 26.6 delta scoreboard |
| [../research/ipados26.5/](../research/ipados26.5/) | FILTER / HUNT_LOOP / P00N watches (P001–P006) |
| [RESEARCH_PLAN.md](RESEARCH_PLAN.md) | XR 18.7.5 Path A/B/C — **Path A parked** |
| [../research/kexploit/ORIGINAL_KRW_PPL_TRACK.md](../research/kexploit/ORIGINAL_KRW_PPL_TRACK.md) | XR Path A method: KRW first, PPL second; not `pattern_F_` recovery |
| [../research/kexploit/ANTI_PATTERNS.md](../research/kexploit/ANTI_PATTERNS.md) | XR anti-goals |
| [../research/kexploit/HYPOTHESIS_TEMPLATE.md](../research/kexploit/HYPOTHESIS_TEMPLATE.md) | Fail-closed hypothesis cards (XR) |
| [ROADMAP_THEORY.md](ROADMAP_THEORY.md) | Staged A→G plan (XR-oriented; label OS when citing) |
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

### A12X / 26.5 (active)
1. **Exact build lock** — ProductBuildVersion on lab iPad still TBD
2. **Offline 26.5↔26.6 artifacts** — kernel/kext extract before any trigger claims
3. **Kernel/PE primitive** — no matching public primitive; watches P001–P006 only
4. **PPL** — separate after KRW; `pattern_F_` recovery rejected

### XR / 18.7.5 (parked Path A)
1. **Data mount** — 15.1 `mount_apfs` fails on iOS 18 Data (`Program version wrong`); next: newer restore `mount_apfs` then SSHRD-style `seputil` (docs in `DATA_MOUNT_SSHRD.md`)
2. **Kernel exploit for 18.7.5 / A12** — **no matching public primitive on 18.7.5**;
   Dopamine 3.0 / momentarius is public through **18.7.1** only
   ([T016](../research/kexploit/experiments/T016_dopamine3_momentarius_window.md)).
   Path A parked — [ORIGINAL_KRW_PPL_TRACK.md](../research/kexploit/ORIGINAL_KRW_PPL_TRACK.md)
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

For **A12 + iOS 18.7.5**, public BootROM (usbliter8) + ramdisk still works.
**Dopamine 3.0** is a real public JB for A12 through **18.7.1** (momentarius PPL) —
**not** 18.7.5. palera1n remains wrong SoC. See T016.

### Public tools vs this device

| Tool / exploit | What it is | XR A12 + 18.7.5? | Notes |
|----------------|------------|------------------|-------|
| usbliter8 | BootROM (SecureROM) pwn | **Yes — already have** | Stage finished |
| iCH / similar SSH ramdisk | BootROM → ramdisk SSH | **Yes — here now** | Forensic/dev toolkit, **not** a jailbreak |
| Dopamine 3.0 + momentarius | Rootless JB + public A12/A13 PPL | **No** (ceiling **18.7.1**) | Teacher / **18.7.1→18.7.5** delta — [T016](../research/kexploit/experiments/T016_dopamine3_momentarius_window.md) |
| ClearSword / DarkSword | Kernel path in Dopamine | **No** on 18.7.5 | DarkSword fixed **18.7.2** (T004); ClearSword not past published window |
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
