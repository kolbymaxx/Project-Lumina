# Research plan — Path A / B / C (XR A12 / 18.7.5)

**Device:** iPhone XR (n841), CPID 8020 / A12, iOS **18.7.5 (22H311)**  
**Entry:** usbliter8 → Pwned DFU `05ac:1227`  
**Updated:** 2026-08-07  

**Track status:** Path A on this device/OS is **parked / secondary** while the
**A12X / iPadOS 26.5** delta hunt is active. See
[RESEARCH_PLAN_26.5.md](RESEARCH_PLAN_26.5.md) and
[`../research/ipados26.5/`](../research/ipados26.5/). Do not mix notes without
labeling a device/OS change.

Fork matrix for advancing capability ourselves. Not a single exploit claim.

**Goal tension (honest):**
- **(A)** Dopamine-style semi-untethered userspace JB **on 18.7.5 specifically**
- **(B)** workable tethered JB / lab root (may leave 18.7.5 for Path C)

**Binding scene constraints:**
- A12 is a **PPL** device. Dopamine-style needs **KRW + A12 PPL defeat** on the **target build**.
- **2026-08-07:** public **momentarius** A12/A13/A12X PPL (Dopamine **3.0**) covers through **18.7.1** / **26.0.1** — **not 18.7.5**. Delta: [T017](../research/kexploit/experiments/T017_1871_to_1875_delta.md) — **KRW** is the citable 18.7.5 kill; momentarius viability on 18.7.5 still **unproven**.
- `pattern_F_` remains a separate private bypass; do not conflate with momentarius. Recovering private demos is still **out**.
- **Path A on 18.7.5** = study public Dopamine/momentarius/ClearSword as **teachers** + **18.7.1→18.7.5** delta; original KRW track still required for 22H311: [../research/kexploit/ORIGINAL_KRW_PPL_TRACK.md](../research/kexploit/ORIGINAL_KRW_PPL_TRACK.md).
- **Relaxin** marketed window: A12 on **17.0–17.3.1** only — **not** 18.7.5 (superseded as “only public PPL path” by momentarius for ≤18.7.1).
- usbliter8 ramdisk / lab root ≠ userspace Dopamine.

**Status line:** no matching **public** primitive for A12 / **18.7.5**  
(public PPL+JB exists through **18.7.1** only).  
Nothing under `research/` wired into `boot/` without an explicit lab decision.

Cross-links: [STATUS.md](STATUS.md) · [RESEARCH.md](RESEARCH.md) ·
[../research/kexploit/ORIGINAL_KRW_PPL_TRACK.md](../research/kexploit/ORIGINAL_KRW_PPL_TRACK.md) ·
[../research/kexploit/ANTI_PATTERNS.md](../research/kexploit/ANTI_PATTERNS.md) ·
[../research/kexploit/WRITEUP_WATCHLIST.md](../research/kexploit/WRITEUP_WATCHLIST.md) ·
[../research/kexploit/FORK1_STRATEGY.md](../research/kexploit/FORK1_STRATEGY.md)

---

## 1) Path matrix

| | **Path A** — Stay 18.7.5, Dopamine-style | **Path B** — Stay 18.7.5, tethered boot-chain / lab root | **Path C** — Leave 18.7.5 → tethered **17.0–17.3.1** + Relaxin |
|---|------------------------------------------|----------------------------------------------------------|------------------------------------------------------------------|
| **Intent** | Semi-untethered / rootless-style JB **on 22H311** | Lab root / tethered SSH / optional boot-patched kernel on **same build** | Workable userspace JB via Relaxin’s **public** window |
| **How we advance** | **Original KRW+PPL track** (docs/RE until FILTER passes) + public writeup watch | iBEC execute reliability + frozen stage2 protocol | Checklist/prep only until Path B green; then **version change** |
| **Prerequisites** | Own (or later public) kernel primitive covering A12/18.7.5 **plus** A12 PPL defeat; bootstrap after that | Reliable: Pico-pwn → demote → patched iBSS → Recovery → **iBEC send + execute** → stage2 | Backup; surrealra1n (or equiv) + usbliter8; SEP mismatch plan; Relaxin for 17.0–17.3.1 A12 |
| **Blockers** | No live KRW on **22H311** (ClearSword/DarkSword window ends ≤18.7.1 / fixed 18.7.2); momentarius **not** claimed on 18.7.5; inventing triggers forbidden | **iBEC execute / leave-iBSS reliability**; Data mount / SEP still hard | **Leaves 18.7.5**; SEP newer than 17.x → bag panic class; rollback not free |
| **Success signals** | Live KRW on 22H311 **and** PPL defeat on 18.7.5 (ported momentarius **or** owned) with fail-closed tests — not a screenshot | N consecutive: `1227 PWND` → `1281` → iBEC **executes** → stage2 with logged USB transitions | About = **17.0–17.3.1**; Relaxin runs; **labeled version change** |
| **Depends on private 0days?** | Public teachers exist through 18.7.1; **18.7.5** still needs new/still-live work or a proven port | **No** for bootrom→ramdisk with public/usbliter8 tooling | **No** for Relaxin’s marketed 17.x window |

**Mapping:** Path A ∪ Path B ≈ Fork 1 (stay on 18.7.5). Path C ≈ Fork 2 (version change).  
Do not merge Path C install notes into Path A discovery logs without labeling.

---

## 2) Path A — original research (not pattern_F_ cargo-cult)

Full track: [../research/kexploit/ORIGINAL_KRW_PPL_TRACK.md](../research/kexploit/ORIGINAL_KRW_PPL_TRACK.md).

| Goal | Realistic? |
|------|------------|
| Decode what `pattern_F_` shipped | **No** with public info |
| Find our own in class KRW + A12 PPL defeat | **Yes** as a research program (no success guarantee) |

**Order (do not invert):** (1) kernel primitive / KRW → (2) PPL bypass.  
PPL study without KRW = mapping only.

**Monday queue (Path A docs/RE):**
1. Track declared (done in-repo).
2. Finish 22H311 kernelcache RO inventory (Mac + blob).
3. Deep-read T013 / Relaxin A12 DMA as PPL architecture teacher.
4. One public surface → one full defensive audit card (not ten half-audits).
5. Keep Path B green for later tests.

**Templates:** [HYPOTHESIS_TEMPLATE.md](../research/kexploit/HYPOTHESIS_TEMPLATE.md) ·
[ANTI_PATTERNS.md](../research/kexploit/ANTI_PATTERNS.md) ·
[AUDIT_METHOD.md](../research/kexploit/AUDIT_METHOD.md).

**Public writeups** still matter as audit targets: [WRITEUP_WATCHLIST.md](../research/kexploit/WRITEUP_WATCHLIST.md).  
A public KRW without PPL ≠ Dopamine Path A complete — label honestly.

---

## 3) Immediate engineering steps (leverage × feasibility)

### Step 1 — iBEC execute reliability (Path B, lab primary)
Log fixed protocol after known-good iBSS→Recovery: Pico-pwn → info → demote → iBSS → `1281` → iBEC send → **execute** variants.  
**Success:** ≥3/5 consecutive post-iBEC stage2.  
**Fail-closed:** execute never leaves Recovery → host/protocol bug, not “missing kernel 0day.”

### Step 2 — Freeze known-good stage2 protocol (Path B)
Document exact command order that last got ramdisk SSH (payload hashes, timeouts, abort/reset).  
**Fail-closed:** unreproducible → Path B not solved.

### Step 3 — Kernelcache ownership (Path A Track A + Path B/C prep)
Inventory `22H311` kernelcache for n841; hash; IOKit/driver map; PPL segment inventory **only**.  
**Fail-closed:** strings ≠ triggers ([ANTI_PATTERNS.md](../research/kexploit/ANTI_PATTERNS.md) #4).

### Step 4 — One-surface audit + writeup watch (Path A)
When a T008/T009-class writeup appears: FILTER → one [AUDIT_METHOD.md](../research/kexploit/AUDIT_METHOD.md) card → hypothesis with fail-closed test.  
Meanwhile poll [WRITEUP_WATCHLIST.md](../research/kexploit/WRITEUP_WATCHLIST.md).  
**Fail-closed:** no named sink → Watch; do not invent selectors.

### Step 5 — Optional Path C spike (docs + backup only until Step 1 green)
Checklist in §5. Prefer disposable restore. Label **VERSION CHANGE**.

---

## 4) Explicit anti-patterns

Canonical list: [../research/kexploit/ANTI_PATTERNS.md](../research/kexploit/ANTI_PATTERNS.md).

Short form:
- Do **not** invent CVE triggers from strings / titles / advisory blurbs.
- Do **not** claim `pattern_F_` is recoverable from abstracts or demos.
- Do **not** equate ramdisk root with KRW / PPL / Dopamine.
- Do **not** mix 17.x Relaxin steps into 18.7.5 discovery without **version change** label.
- Do **not** invert KRW → PPL order.
- Do **not** wire `research/` into `boot/` “to try something.”
- Do **not** promote a hypothesis without success/fail signals.

---

## 5) Path C checklist (if/when leaving 18.7.5)

Label every note: **VERSION CHANGE — not 18.7.5 discovery.**

| # | Item | Done? |
|---|------|-------|
| 1 | Full backup / accept data loss | ☐ |
| 2 | Record 18.7.5 / 22H311, UDID, ECID, SEP history | ☐ |
| 3 | Expect SEP newer than 17.x → bag panic class; plan honestly | ☐ |
| 4 | Roles: usbliter8 = BootROM; surrealra1n-class = unsigned orchestration; Relaxin = 17.0–17.3.1 A12 only | ☐ |
| 5 | Target inside Relaxin window; do not aim 17.4+ “hoping” | ☐ |
| 6 | Isolate branch + artifacts; do not overwrite Phase A 18.7.5 inventory | ☐ |
| 7 | Assume rollback to signed 18.7.5 is **not** free until proven | ☐ |
| 8 | Go only after Path B Step 1 green enough to trust the boot chain | ☐ |
| 9 | Success = About 17.0–17.3.1 + Relaxin — **not** “still 18.7.5 Dopamine” | ☐ |

---

## 6) Hypotheses (examples — use the template)

Use [HYPOTHESIS_TEMPLATE.md](../research/kexploit/HYPOTHESIS_TEMPLATE.md) for new cards.

### H-B1 — iBEC execute fails on protocol ordering, not payload corruption
1. **Evidence:** bulk send often succeeds; leave-iBSS/execute is the weak gate.
2. **Test:** one variable × 5 trials; log PID transitions.
3. **Fail-closed:** all orderings fail with known-good payloads → payload/identity mismatch, not more CVE hunting.

### H-A1 — Still-live 18.7.5 kernel bug may exist in public advisories; useless for Dopamine without PPL defeat
1. **Evidence:** T008/T009 fixed in 18.7.9 (window open on 18.7.5); A12 PPL still required for Path A product JB.
2. **Test:** writeup watch → FILTER → one audit; **no** bootstrap on advisory text alone.
3. **Fail-closed:** confirmed kwrite/root **does not** promote Path A to “done” until PPL defeat has its own fail-closed success.

### H-A2 — Original KRW on 22H311 is a multi-cycle RE program, not a demo decode
1. **Evidence:** no public A12/18.7.5 match in [PUBLIC_PRIMITIVE_MATRIX.md](../research/kexploit/PUBLIC_PRIMITIVE_MATRIX.md); `pattern_F_` closed.
2. **Test:** kernelcache ownership + one-surface audits per [ORIGINAL_KRW_PPL_TRACK.md](../research/kexploit/ORIGINAL_KRW_PPL_TRACK.md).
3. **Fail-closed:** if “progress” is only social screenshots or string lists → stay inventory/watch; do not claim a path.

---

## 7) Repo / Cursor workflow

| Tree | Purpose |
|------|---------|
| `main` + `boot/` + Phase A artifacts | **Known-good 18.7.5** — protect |
| `research/kexploit/` Path A track | Original KRW+PPL docs, hypotheses, audits — **no boot wiring** |
| Branch `cursor/path-c-17x-spike-*` | Only when Path C go |
| Host `usbliter8ctl` | Improve execute / stage2; don’t rewrite successful history |

**Agent split:**
- **Cloud:** track hygiene, writeup poll, FILTER, audit cards (docs).
- **Device lab:** Path B USB matrix; later RO/lab only after Filter = Pass.
- **Offline RE:** 22H311 ownership on Mac with blobs — say when skill exceeds lab and defer rather than invent.

---

## Primary recommendation

| Horizon | Focus |
|---------|--------|
| **Lab (near-term)** | **Path B** — iBEC execute + stage2 protocol (keep test harness green) |
| **Discovery (parallel)** | **Path A original track** — kernelcache ownership, one-surface audits, PPL mapping as teacher; **not** `pattern_F_` recovery |
| **Path C** | Checklist only until Path B Step 1 green + backups/SEP expectations written |

Bottom line: wanting our own KRW + PPL is the right ambition for Path A. Trying to reconstruct `pattern_F_` is the wrong method.
