# Bootstrap / AMFI–trustcache lab (ramdisk track)

**Separate from** the kernel CVE hunt under [`../kexploit/`](../kexploit/).  
Live surface: tethered usbliter8 → XR ramdisk SSH on **A12 / 18.7.5 (22H311)**.

**Not a jailbreak.** No Sileo claim. Exit **137** (SIGKILL) on `dpkg` is still
the live failure mode under test. Nothing here is wired into `boot/` unless a
card explicitly says to rebuild payloads on the Mac.

## Status (locked until contradicted)

- Remap / ents / secret-slot theories from the local session are **closed** (see below).
- Highest-signal open DFU card: **append `dpkg` CDHash to build-time trustcache → rebuild → re-pwn → one `dpkg --version`**.
- Live bootargs observed in that session: `rd=md0 -v debug=0x2014e` only  
  (`boot/lumina-boot.sh` defaults include AMFI bypass args — **not** proven live on that chain).

## Closed cards (do not re-run)

| ID | Question | Result |
|----|----------|--------|
| [B001](experiments/B001_var_jb_tmpfs_remap.md) | Does `/var/jb` tmpfs remap kill SSH? | **No** — PHASE1_OK |
| [B002](experiments/B002_remap_alone_dpkg.md) | Remap alone makes `dpkg` run? | **No** — still 137 |
| [B003](experiments/B003_platform_ents_vs_bash.md) | Missing platform ents vs bash? | **No** — same ents, different CDHash |
| [B004](experiments/B004_num_loadable_secret_slot.md) | `num_loadable` secret slot? | **No** — stays 0 |
| [B000](experiments/B000_fakesign_bash_copy.md) | Controlled fakesign (one bash copy) | **Fatal** (already proven) — skip unless new bootchain |

## Open cards (priority)

| Pri | ID | Needs | One-line |
|-----|----|-------|----------|
| **1** | [B005](experiments/B005_tc_append_dpkg_cdhash.md) | Mac `build.sh` / TC tool + full re-pwn | Append dpkg CDHash → rebuild → boot → `dpkg --version` |
| **2** | [B006](experiments/B006_amfi_tc_stub_hit.md) | After B005; + offline kernelcache RE | Does ios18 `AMFIIsCDHashInTrustCache` stub actually hit on 22H311? |
| **4** | [B007](experiments/B007_live_cs_counters.md) | Live SSH after remap, no resign | `cs_*` counters + `ldid -h` evidence only |
| **5** | [B008](experiments/B008_bootargs_amfi_groom.md) | Rebuild/boot with new args | `amfi_get_out_of_my_way=1` (etc.) vs still-137 |

Session checklist: [DFU_SESSION_TC_APPEND.md](DFU_SESSION_TC_APPEND.md)

## Out of scope for this track
- KPF launch-constraint patch for 18.7.5 (host RE first — later)
- Kernel r/w / PPL (no live primitive in SSH)
- DarkSword / CVE ports ([`../kexploit/`](../kexploit/) only)

## See also
- [../CUSTOM_BOOT_NEXT.md](../CUSTOM_BOOT_NEXT.md) — known-good BootROM path
- [../../docs/STATUS.md](../../docs/STATUS.md)
- [../../boot/lumina-boot.sh](../../boot/lumina-boot.sh) — default bootargs (may differ from live chain)
