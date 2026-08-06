# Data mount — SEP / keybag plan (Fork 1)

**Date:** 2026-08-06  
**Docs only.** No live mounts in this pass. No phone commands here.  
**Stay on:** XR A12 / **18.7.5 (22H311)**. No Fork 2.

Session A evidence: [`../artifacts/xr-18.7.5/data-mount-session-A-2026-08-05.md`](../artifacts/xr-18.7.5/data-mount-session-A-2026-08-05.md)  
Prior tooling notes: [`DATA_MOUNT_SSHRD.md`](DATA_MOUNT_SSHRD.md) · [`DATA_MOUNT_LIVE_PLAN.md`](DATA_MOUNT_LIVE_PLAN.md)

---

## 1) Symptom classes

| Class | Signal | Likely meaning (hypothesis) | Session A? |
|-------|--------|------------------------------|------------|
| **Tool version skew** | exit **76**, `Program version wrong` | Ramdisk `mount_apfs` too old for on-disk APFS features | Phase A (2026-08-01) on `disk0s1s*` / 15.1 tools |
| **Missing node** | exit **66**, `No such file or directory` | Wrong disk map / volumes not probed yet | Early Session A (used `disk0s1s*` before `disk1s*`) |
| **Hang / block** | no RC; `mount_apfs` stalls until interrupt | Waiting on SEP / gigalocker / keybag / unlock state | **Observed** — Data `disk1s2` hung; Ctrl-C; no `DATA_RC` |
| **Clear crypto / keybag deny** | fail-fast errno + readable deny string | Tools match; unlock/SEP staging is the gate | **Not observed** yet |

**What Session A actually observed (2026-08-05/06):**
- System path usable: `disk1s1` → `/mnt1`, **18.7.5 / 22H311** (`SYS_RC:0`)
- Data `disk1s2` → **hang** (not exit 76)
- On-device `disk1s8` check **skipped** after session close
- Closed verdict: Data = **block / SEP-keybag class**, not “retry bare `mount_apfs`”

---

## 2) Next live session design (when we choose — not this pass)

Controlled A/B on unlock state. **One variable at a time.** RO only.

| Arm | Prep | Then |
|-----|------|------|
| **A** | Unlock phone → brief SpringBoard use → DFU → pwn → ramdisk SSH | System mount first; Data with **short timeout** |
| **B** | Cold lock (no unlock) → DFU → pwn → ramdisk SSH | Same mount sequence |

**Sequence (future session):**
1. Confirm SSH alive; inventory `mount` + `/dev/disk*` (expect `disk1s*` on current layout).
2. Mount **System** RO (`disk1s1` → `/mnt1`); confirm **18.7.5 / 22H311**.
3. Attempt **Data** RO (`disk1s2` → `/mnt2`) with short timeout (~20–30s).  
   Datapoint: **hang** vs **RC + string**.
4. Optional **S8** only after Data result is recorded (same timeout rule).
5. **Stop conditions:** hang (interrupt + log), clear deny string, unexpected RC, or System identity wrong.

Do **not** run `seputil` in that first A/B pass. Record arm (A vs B) + exact errors in a dated artifact.

---

## 3) RO diagnostics worth designing later

Only if errno **moves off hang** (fail-fast deny or new RC class):

- Design a **written** RO checklist: Preboot / xART identity (`apfs.util -p` if present) → `seputil --gigalocker-init` / `--load` **as documented steps with expected outputs**
- Re-probe disk roles; do not assume Phase A `disk0s1s*` or that `s6` is Preboot (Cryptexes in Phase A)

**Explicit:** no RW mounts. No destructive `seputil` experiments without a written step and operator approval. No blind spray-mount of all slices.

---

## 4) Non-goals

- Not a jailbreak path; not Sileo; not KRW
- No **16.0** (or other) restore ramdisk wired into **known-good** `boot/` / default payload tree
- No inventing SEP bypasses or keybag cracks
- No Fork 2 / surrealra1n

---

## 5) See also

- [`DATA_MOUNT_LIVE_PLAN.md`](DATA_MOUNT_LIVE_PLAN.md) — Session A0/A1′/A2′ commands (historical)
- [`DATA_MOUNT_SSHRD.md`](DATA_MOUNT_SSHRD.md) — public SSHRD staging reference
- [`kexploit/T010_DEVICE_IDENTITY.md`](kexploit/T010_DEVICE_IDENTITY.md) — works / blocked
- [`kexploit/T011_LAB_CAPABILITIES.md`](kexploit/T011_LAB_CAPABILITIES.md) — lab ≠ JB
- [`../docs/LAB_STATE.md`](../docs/LAB_STATE.md)
