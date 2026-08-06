# Research plan — Path A / B / C (XR A12 / 18.7.5)

**Device:** iPhone XR (n841), CPID 8020 / A12, iOS **18.7.5 (22H311)**  
**Entry:** usbliter8 (RP2350 / Pico-class) → Pwned DFU `05ac:1227`  
**Host:** primarily Windows + Python `usbliter8ctl`; Linux available  
**Updated:** 2026-08-06  

This is the **newest realistic plan to advance jailbreak capability ourselves**.  
It is a fork matrix, not a single magical exploit claim.

**Goal tension (honest):**
- **(A)** Dopamine-style semi-untethered userspace JB **on 18.7.5 specifically**
- **(B)** any workable tethered JB / lab root (may leave 18.7.5)

**Binding scene constraints (Aug 2026):**
- A12 is a **PPL** device. Public Dopamine-style on PPL past ~**17.3.1** needs a **public** PPL bypass **and** a covering kernel exploit.
- `pattern_F_` A12/A13 PPL bypass is **private** (demo’d with public kernel exp → phkrw). Not recoverable from abstracts/demos. Treat as blocked for Path A until a **public** artifact exists.
- **Relaxin** (OwnGoal / Lakr): A12 on **17.0–17.3.1** only — **not** 18.7.5.
- Documented practical XR path others claim: usbliter8 + surrealra1n (+ iBoot64Patcher etc.) → unsigned tethered **17.0**, then Relaxin, with SEP/keybag kernel fixes when SEP is newer — that is a **version change**, not “discover 18.7.5 Dopamine.”
- usbliter8ra1n-style (patched iBoot → kernel at boot, tethered SSH) ≠ userspace Dopamine.

**Status line:** no matching **public** primitive for A12 / **18.7.5** Dopamine-style.  
Nothing under `research/` is wired into `boot/` without an explicit lab decision.

Cross-links: [STATUS.md](STATUS.md) · [RESEARCH.md](RESEARCH.md) ·
[../research/kexploit/FORK1_STRATEGY.md](../research/kexploit/FORK1_STRATEGY.md) ·
[../research/kexploit/WRITEUP_WATCHLIST.md](../research/kexploit/WRITEUP_WATCHLIST.md) ·
[../research/kexploit/experiments/INTAKE_2026-08-06.md](../research/kexploit/experiments/INTAKE_2026-08-06.md)

---

## 1) Path matrix

| | **Path A** — Stay 18.7.5, Dopamine-style userspace | **Path B** — Stay 18.7.5, tethered boot-chain / patched kernel | **Path C** — Leave 18.7.5 → tethered unsigned **17.0–17.3.1** + Relaxin |
|---|---------------------------------------------------|----------------------------------------------------------------|--------------------------------------------------------------------------|
| **Intent** | Semi-untethered / rootless-style JB **on 22H311** | Lab root / tethered SSH / optional boot-patched kernel on **same build** | Workable userspace JB via **Relaxin’s public window** |
| **Prerequisites** | Public kernel exploit covering **≤18.7.5 / A12** **plus** public A12 PPL bypass; patchfinder/bootstrap after that | Reliable: Pico-pwn → demote → patched iBSS → Recovery → **iBEC send + execute** → known stage2 (ramdisk/kernel) | Full backup; disposable/accepted data loss; surrealra1n (or equiv) + usbliter8 + iBoot64Patcher; SEP mismatch plan; Relaxin IPA for 17.0–17.3.1 A12 |
| **Blockers** | **Public PPL bypass absent** (private `pattern_F_`); no citable 18.7.5 A12 KRW recipe; inventing triggers from CVE strings is forbidden | **iBEC execute / leave-iBSS reliability** (weak gate); Data mount / SEP keybag still hard even with ramdisk root; repo `usbliter8ctl send` may be stub vs your working host copy | **Leaves 18.7.5**; SEP newer than 17.x → kernel bag panic class (see T014 claim); surrealra1n published XR window historically ≤16.6.1 — 17.0 needs claim/repro; rollback not free |
| **Success signals** | Public writeup/PoC: A12 PPL bypass + kernel path that runs on **22H311** (or proven still-live); then elevate + PPL defeat on-device | N/M consecutive: `1227 PWND` → `1281` Recovery → iBEC **executes** (not only bulk-sent) → stage2 (ramdisk SSH or patched kernel boot) with logged USB serial transitions | Device About = **17.0–17.3.1**; tethered boot works; Relaxin installs/runs; activation/SEP usable per your checklist; **labeled as version change** |
| **Risk to device/data** | Low while RO/watch-only; high if wrong kernel poke without backup | Medium: bad iBEC/iBSS bricks *boot session* (recoverable via DFU+Pico); Data/SEP experiments can brick usability | **High:** erase / unsigned restore; SEP mismatch panics; may burn hours; leaving 18.7.5 is intentional |
| **Depends on private 0days?** | **Yes** today (PPL). Kernel may also be private. Unblocks only if **public** artifacts appear | **No** for bootrom→ramdisk engineering with public/usbliter8 tooling. Yes if you aim for full SpringBoard JB without public PPL | **No** for Relaxin’s marketed 17.x window (closed IPA, but not “private PPL 0-day”). Custom SEP-bag patches may be non-public craft |

**Mapping to older “Fork” language:** Path A ∪ Path B ≈ former Fork 1 (stay on 18.7.5). Path C ≈ expanded Fork 2 (version change → Relaxin). Do not merge Path C install notes into Path A discovery logs without labeling.

---

## 2) Immediate next 5 engineering steps

Ranked by **leverage × feasibility** with XR + usbliter8 + **public** info only.

### Step 1 — iBEC execute reliability matrix (Path B, highest leverage)
**Do:** On Windows host, log a fixed protocol after known-good iBSS→Recovery:
1. Pico-pwn → `usbliter8ctl info` (expect PWND `1227`)
2. demote (if used) → boot patched iBSS → wait `1281`
3. bulk-send iBEC (your working send path / `irecovery` / host fork — note if root-repo `send` is stub)
4. **execute** / go / boot-command variants one variable at a time  
Record: USB VID:PID timeline, serial string, which command left iBSS, failure mode (stall / disconnect / stay 1281 / reboot to Apple logo / DFU).

**Success:** ≥3/5 consecutive runs reach post-iBEC stage2 entry (ramdisk or next image load).  
**Fail-closed:** if execute never leaves Recovery after N controlled trials → treat as host/protocol bug, not “missing kernel 0day”; freeze Path C spike until Step 1 green.

**Hypothesis (H-B1):** see §6.

### Step 2 — Freeze a known-good stage2 protocol doc (Path B)
**Do:** Write `artifacts/xr-18.7.5/stage2-protocol.md` (gitignored secrets only in local notes) capturing the **exact** command order that last got ramdisk SSH — payloads hashes, timeouts, abort/reset flags (`usbliter8ctl boot` options), Windows vs Linux differences. Improve execute path; **do not rewrite** history of what already worked.

**Success:** a second operator (or cold next day) can follow the doc to SSH without chat archaeology.  
**Fail-closed:** if unreproducible → Path B is not “solved”; keep iterating Step 1.

### Step 3 — Kernelcache / patchfinder hygiene (Path A watch + Path B/C prep)
**Do:** Offline (Windows/Linux/Mac): inventory `22H311` kernelcache for n841; record hash, decompress path, string probes for SEP/bag / PPL-related names **as inventory only**. Keep Relaxin/libxpf notes under `research/kexploit/` (T013 teacher). No invented offsets into `boot/`.

**Success:** reproducible extract + note file updated (`research/kexploit/22H311_NOTES.md`).  
**Fail-closed:** strings ≠ triggers; do not open a “CVE PoC” from symbol names.

### Step 4 — Writeup watch with hard unblock criteria (Path A)
**Do:** Poll [WRITEUP_WATCHLIST.md](../research/kexploit/WRITEUP_WATCHLIST.md) 2×/week. Escalate Path A **only** when criteria in §4 fire.

**Success:** intake card + FILTER pass.  
**Fail-closed:** screenshots / “jailbroken 18–26” demos without public recipe → stay T015 watch.

### Step 5 — Optional Path C spike plan (docs + backup only until Step 1 green)
**Do:** Prepare checklist in §5; gather surrealra1n release notes / XR support matrix; **do not** flash until backup + SEP expectations written. Prefer a disposable restore target.

**Success:** go/no-go written; if go — isolated branch `cursor/path-c-17x-spike-*` for notes.  
**Fail-closed:** no public reproducible 17.0 XR recipe → Path C remains claim-watch (T014), not lab default.

---

## 3) Explicit anti-patterns

- Do **not** invent CVE triggers from kernelcache strings, talk titles, or advisory blurbs.
- Do **not** claim `pattern_F_` PPL bypass is recoverable from abstracts, demos, or Lakr screenshots.
- Do **not** equate ramdisk root / tethered SSH with Dopamine-style JB.
- Do **not** mix 17.x Relaxin install steps into 18.7.5 discovery notes without labeling **version change**.
- Lab root ≠ public PPL bypass.
- Do **not** treat social claims (T014/T015) as matrix upgrades without reproduction.
- Do **not** wire `research/` into `boot/` “to try something.”
- Do **not** assume surrealra1n reaches “lower iOS 18” for DarkSword — wrong tool/window; DarkSword kernel stages dead on 18.7.5 anyway (T004).
- Do **not** promote a hypothesis to “the path” without a defined success/fail signal.

---

## 4) WRITEUP_WATCHLIST criteria (Path A unblock)

**Path A unblocks only if a public artifact provides both:**

| Layer | Minimum public artifact | Pre-integration verify |
|-------|-------------------------|------------------------|
| Kernel | Writeup or open PoC: exploit class + entry + **SoC includes A12/T8020** + version window includes **≤18.7.5** or proven still-live on 22H311 | FILTER.md; defensive audit; RO string/xref on 22H311; no weaponized paste into boot |
| PPL | **Public** A12/A13 PPL bypass (code, detailed writeup, or shipped open tool) — **not** demo credit alone | Confirm A12 (not SPTM-only story); runs after your KRW; document failure if PPL still blocks |
| Bootstrap | Optional later: open jailbreakd/rootless notes | Only after KRW+PPL on-device |

**Also watch (does not alone unblock Path A):** T008/T009 deep dives (may yield KRW class ideas); Relaxin release notes that **explicitly** add 18.7.x A12 (unlikely without public PPL).

**Reject as unblock:** “full phkrw + ppl” screenshots; private Discord; YouTube; “18.?.?–26.0.1” without SoC+build.

Details / poll list: [../research/kexploit/WRITEUP_WATCHLIST.md](../research/kexploit/WRITEUP_WATCHLIST.md).

---

## 5) Path C checklist (if/when leaving 18.7.5)

Label every note: **VERSION CHANGE — not 18.7.5 discovery.**

| # | Item | Done? |
|---|------|-------|
| 1 | Full backup / accept data loss; export 2FA / activation-critical data | ☐ |
| 2 | Record current: iOS **18.7.5 / 22H311**, UDID, ECID, SEP-related panic history | ☐ |
| 3 | Expect **SEP newer than 17.x** → 17.0 kernel may request bags SEP won’t grant (hard panic class; T014). Plan for **kernel SEP-bag patch** research — may need RE skill beyond current lab | ☐ |
| 4 | Roles: **usbliter8** = BootROM pwn; **surrealra1n** (or equiv) = tethered unsigned restore/boot orchestration; **iBoot64Patcher** = iBoot sig patches; **Relaxin** = userspace JB **only** on **17.0–17.3.1 A12** | ☐ |
| 5 | Confirm target build inside Relaxin window; do not aim 17.4+ “hoping” | ☐ |
| 6 | Isolate branch + artifact dir for 17.x notes (see §7); do not overwrite Phase A 18.7.5 inventory | ☐ |
| 7 | Rollback reality: returning to **signed** 18.7.5 may require Apple’s signing window / update path; unsigned return is another tethered project. Assume **one-way** until proven otherwise | ☐ |
| 8 | Go only after Path B Step 1 (iBEC execute) is green enough to trust the boot chain | ☐ |
| 9 | Success = About shows 17.0–17.3.1 + Relaxin runs — **not** “we still have 18.7.5 Dopamine” | ☐ |

No hand-wavy “just downgrade.”

---

## 6) Optional hypotheses (max 3) — not the primary path

### H-B1 — Windows iBEC execute fails on protocol ordering, not payload corruption
1. **Evidence:** bulk send often succeeds; leave-iBSS/execute is the weak gate; DFU/Recovery timing and abort/reset defaults differ by OS (`usbliter8ctl` macOS vs non-macOS defaults).
2. **Test:** Step 1 matrix — one variable (abort, reset, delay after send, execute cmd, cable direct vs hub) × 5 trials; log PID transitions.
3. **Fail-closed:** if all orderings fail with known-good payloads that previously worked → escalate to payload/identity mismatch (wrong iBEC/CPID), not more CVE hunting.

### H-B2 — Repo `usbliter8ctl send` stub ≠ your working host send path
1. **Evidence:** root `usbliter8ctl` `do_send` currently prints “not implemented yet”; lab reports bulk send success → divergent host tooling.
2. **Test:** Diff working Windows script vs repo; document the Recovery bulk + execute sequence; port **execute** reliability into repo without breaking known-good `boot`.
3. **Fail-closed:** if working path can’t be reproduced from a clean clone → treat as undocumented local tool debt (fix it) before Path C.

### H-A1 — Still-live 18.7.5 kernel bug exists in public advisories but is useless for Dopamine without public PPL
1. **Evidence:** T008/T009 fixed in 18.7.9 (window open on 18.7.5); scene constraint that PPL past ~17.3.1 needs public PPL bypass; opa334-class guidance that `pattern_F_` PPL stays private.
2. **Test:** Writeup watch only — if a **technical** writeup names subsystem, do FILTER + RO probes; **do not** build Dopamine bootstrap on advisory text alone.
3. **Fail-closed:** even a confirmed kwrite/root primitive **does not** promote Path A to “the path” until a **public** PPL bypass artifact exists. Lab root ≠ Dopamine.

---

## 7) Repo / Cursor workflow

| Tree | Purpose |
|------|---------|
| `main` + `boot/` + Phase A artifacts | **Known-good 18.7.5** ramdisk / inventory — protect |
| `research/kexploit/` on Path A/B notes | Teachers, watches, FILTER — **no boot wiring** |
| Branch `cursor/path-c-17x-spike-*` | Only when Path C go: surrealra1n/Relaxin/SEP notes isolated |
| Host `usbliter8ctl` | Prefer improving **execute** / stage2 on the two-stage DFU→Recovery flow already in tree; don’t rewrite successful history |

**Agent split:**
- **Cloud:** writeup poll, docs, FILTER, plan hygiene (this file).
- **Windows lab:** Step 1–2 USB matrix (device required).
- **Offline RE:** Step 3 kernelcache inventory when blobs present — blunt: deep SEP-bag / PPL RE may exceed current lab skill; say so and defer rather than invent.

---

## Primary recommendation (next 48 hours)

**Primary path: Path B — make iBEC execute reliable and freeze the stage2 protocol.**

Path A stays **blocked until public PPL + covering kernel artifacts** (watch only).  
Path C stays **checklist/prep only** until Step 1 is green and backups/SEP expectations are written — then it is the only **public** route to Relaxin-like userspace JB, explicitly as a **version change**.
