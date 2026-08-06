# Next live session — runbook (Fork 1)

**Docs only in this pass.** No device commands here.  
**Stay on:** XR A12 / **18.7.5 (22H311)**. No Fork 2.

Read first: [`kexploit/STATUS.md`](kexploit/STATUS.md) · [`kexploit/T012_CEILING.md`](kexploit/T012_CEILING.md)

---

### Preconditions
- Device still **18.7.5 / 22H311** (confirm before claiming window)
- Read **STATUS** + **T012 ceiling** before powering on a session
- Choose **Track 1** (Data) **or** **Track 2** (kernel/JB path) — not both ad hoc
- Known-good host path only: Lumina `./boot/lumina-boot.sh` / SSH (or documented ICH equivalent) — do not swap default ramdisk without a dated plan

---

### Track 1 — Data (default if no new CVE writeup)

1. Unlock **A/B** per [`DATA_MOUNT_SEP_KEYBAG_PLAN.md`](DATA_MOUNT_SEP_KEYBAG_PLAN.md) (unlock→use→pwn vs cold lock→pwn)
2. Boot **known-good** ramdisk + SSH (ICH / current lab path only)
3. **System RO** first; then **Data** with **short timeout**; record **hang vs RC** (+ exact string)
4. **Stop** on hang, clear deny string, unexpected RC, or wrong System identity — **no** `seputil` / RW without a written step
5. Log under [`logs/`](logs/) — copy [`logs/_TEMPLATE.md`](logs/_TEMPLATE.md) → `YYYY-MM-DD_track1_data.md` (see [`logs/README.md`](logs/README.md)); no secrets

Optional S8 only after Data result is recorded. See also [`DATA_MOUNT_LIVE_PLAN.md`](DATA_MOUNT_LIVE_PLAN.md).

---

### Track 2 — Kernel / JB path

- **Only if** [`kexploit/WRITEUP_WATCHLIST.md`](kexploit/WRITEUP_WATCHLIST.md) shows a **deep writeup** naming a concrete surface
- Then: **offline RE** first on `kernelcache.payload`; lab RO only under a dated experiment card
- Follow [`kexploit/LAB_TO_DOPAMINE_BRIDGE.md`](kexploit/LAB_TO_DOPAMINE_BRIDGE.md) gates — **lab ≠ JB**; T012 still applies after any win

T008/T009 stay **watch-only** until that writeup exists.

---

### Never in a live session without a new written plan
- Bare Data `mount_apfs` spam  
- Wiring `research/` into `boot/`  
- Inventing T008/T009 triggers or offsets  
- Fork 2 / surrealra1n  

Map: [`kexploit/INDEX.md`](kexploit/INDEX.md)
