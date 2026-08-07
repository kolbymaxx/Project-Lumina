# 26.5 A12X delta hunt from 26.6 patches — realistic next steps

**Device / build (locked intent):** iPad Pro 12.9-inch 3rd generation (**A12X / t8027 / CPID `8027`**), research target **iPadOS 26.5 / 26.5.x** (pre–**26.6** patch surface). Apple released **iOS/iPadOS 26.6** on **2026-07-27** with 75+ documented security entries (kernel memory corruption/write, AVEVideoEncoder kernel privileges, MediaRemote root, sandbox escapes, WebKit, etc.). Exact **ProductBuildVersion** on the lab unit is still to lock on-device; until then treat “26.5.x still on device” as the window and **do not invent** unsigned restore/downgrade paths.

**Not a jailbreak.** Advisory impact text ranks *where to look*, not a PoC, trigger, or chain. A12X is a **PPL** device: Dopamine-style JB still needs a **public** kernel primitive **plus** a separate PPL bypass. `pattern_F_` / private PPL recovery is **out of scope**. usbliter8 A12X support is **unproven** — Path A does **not** wait on Pico.

Canonical hunt tree: [`../research/ipados26.5/`](../research/ipados26.5/).  
XR 18.7.5 / usbliter8 track stays under [`RESEARCH_PLAN.md`](RESEARCH_PLAN.md) + [`../research/kexploit/`](../research/kexploit/) — **do not mix** without labeling a device/OS change.

**Status line:** no matching public primitive for **A12X / iPadOS 26.5**.

---

## 1) Path matrix

| | **Path A** — Stay 26.5; original KRW→PPL discovery from 26.6 delta | **Path B** — Lab signals only (crash / corruption / temp root) | **Path C** — Deferred; usbliter8/A12X boot-chain if/when support exists |
|---|--------------------------------------------------------------------|----------------------------------------------------------------|------------------------------------------------------------------------|
| **Intent** | Semi-untethered / Dopamine-shaped chain **on 26.5 A12X** (KRW first, PPL second) | Reproducible **controlled** signal on-device or offline; no full-JB claim | Pwned DFU → board-specific ramdisk/SSH for tethered lab root |
| **Prerequisites** | Device already on **26.5.x**; public IPSW pair **26.5 ↔ 26.6** (or extractable kernel/kexts); FILTER-pass cards; fail-closed hypotheses | Same binary/advisory baseline; willingness to run **non–daily-driver** tests on 26.5 (unpatched) | Pico firmware offsets/ROP/PAC strategy for **t8027** SecureROM `iBoot-4172.0.0.100.14`; host payloads **not** XR `n841ap` |
| **Blockers** | No owned KRW; no public A12/A12X PPL bypass; advisory ≠ trigger; unsigned 26.5 restore if already left the build | Reachability unknown until diffs + IOKit/clients mapped; panic may brick session until reboot | SecureROM **PAC-heavy** on t8027 (unlike t8020 XR); upstream A12X “theoretical only”; nothing in `boot/` |
| **Success signals** | Fail-closed KRW (or KRW-shaped) on **26.5** with citable method **we** own; then **separate** PPL success that is ours | N≥3 reproducible: panic with stable backtrace, measurable corruption, or privilege change logged | Serial gains `PWND:[usbliter8]`; then separate board ramdisk — still ≠ 26.5 PE |
| **Risk** | Staying on 26.5 = living **without** 26.6 fixes (daily-driver risk); false leads from advisory-only ranking | Device instability; data loss on panic loops; confusing Path B root with Path A KRW | Time sink if PAC/ROP never closes; polluting XR boot wrappers |
| **Depends on private 0days?** | **No** for the *method* (original discovery). **Yes** if someone expects a drop-in private PPL/`pattern_F_` — that is **rejected** | **No** — Path B can succeed on public delta + lab | **No** for BootROM class if ported from public usbliter8; **unproven** for A12X today |

**Mapping:** Path A ∪ Path B = active 26.5 delta hunt. Path C = optional foothold later ([`research/usbliter8-t8027/`](../research/usbliter8-t8027/)). Do not block A/B on C.

**Order (do not invert):** (1) reachability + kernel/PE signal → (2) KRW-shaped control → (3) PPL study only after KRW. PPL-without-KRW = mapping only.

---

## 2) 26.6 delta scoreboard (top priority targets)

Source: [About the security content of iOS 26.6 and iPadOS 26.6](https://support.apple.com/en-ca/128066) (released 2026-07-27). Ranking = **public impact language × likely app-reachable × kernel/root relevance**. Impact text is **priority only**.

| Rank | Component | CVE(s) | Impact (Apple) | Why ranked | Binary / diff artifact | First experiment (no invented trigger) |
|------|-----------|--------|----------------|------------|------------------------|----------------------------------------|
| 1 | **AVEVideoEncoder** | CVE-2026-64747 | App → **arbitrary code with kernel privileges**; buffer overflow / size validation | Highest kernel-priv language + app-reachable encoder class historically | `com.apple.driver.AppleAVE2` (or IPSW-equivalent AVE kext) **26.5 vs 26.6**; size-check hunks | Offline: bindiff / size-validation delta list. On-device **only after** client surface named from diff — else **blocked** |
| 2 | **Kernel** (write) | CVE-2026-64751 | App → termination **or write kernel memory**; UAF | Explicit **write** wording | `kernelcache` 26.5 vs 26.6; UAF fix sites | Offline: enumerate UAF fix functions. Lab: no selector invention — wait for named sink or public writeup |
| 3 | **IOKit** | CVE-2026-43805 | App → termination **or write kernel memory**; race / state handling | Write + race; often user-client adjacent | IOKit family kexts changed in 26.6; race/state hunks | Offline: list changed user clients. **Reject** guessing selectors from names |
| 4 | **Kernel** (corrupt) | CVE-2026-64749, CVE-2026-43778 | App → termination **or corrupt kernel memory**; mem handling / UAF | Strong Path B panic/corruption signals; possible Path A if controllable | Same kernelcache delta; mem/UAF clusters | Offline: cluster patches by subsystem. Path B: controlled repro **only** with documented reachability |
| 5 | **Kernel** (disclose) | CVE-2026-64709 | App → **disclose kernel memory** | Leak companion for later KRW (Path A support), not entry alone | kernelcache info-leak fix sites | Offline: mark leak vs write sites. Do not call leak “KRW” |
| 6 | **MediaRemote** | CVE-2026-43723 | App → **root privileges**; path handling | High privilege but **userspace root ≠ KRW ≠ PPL** — Path B / staging | `MediaRemote` / related frameworks 26.5 vs 26.6; path-validation hunks | Offline: path-check delta. On-device: only with concrete path from diff — else blocked |
| 7 | **Sandbox / libc** | CVE-2026-64740 (Game Center), CVE-2026-28973 (libc) | Sandbox breakout | Escalation **after** code exec in-app; not kernel entry | sandbox profiles / libc hunks | Note as chain-stage only; not Path A entry |
| 8 | Kernel (crash-heavy / remote) | e.g. CVE-2026-43739, CVE-2026-43810, CVE-2026-28931 (NFS) | Termination / remote corrupt | Lower for installed-app Path A; NFS/remote demoted | As needed after Tier 1–2 exhaust | Demote unless offline diff shows surprising local reachability |
| — | WebKit batch | multiple | Safari/WebKit impacts | Browser surface; separate from app→kernel Path A unless chained | WebKit dylibs | Out of primary scoreboard unless a chain theory already has a kernel foothold |

Full triage notes: [`../research/ipados26.5/experiments/INTAKE_26.6.md`](../research/ipados26.5/experiments/INTAKE_26.6.md).

---

## 3) Immediate next 5 engineering steps

Ranked by **leverage × feasibility** with A12X + public IPSWs/advisories + optional on-device 26.5. Prefer offline first.

### Step 1 — Lock build identity + IPSW pair (feasibility: high)
On the iPad (Settings → General → About) and/or `ideviceinfo`: record **ProductVersion**, **ProductBuildVersion**, model (`j317`/`j318`/…), UDID. Download matching **26.5.x** and **26.6** IPSWs for this board if Apple still serves them; if 26.5 is unsigned for *restore*, still keep the device on 26.5 and use any **already held** or publicly hosted firmware images for offline extract only — **do not invent** signing/restore.

- **Success:** build string locked in STATUS; IPSW paths documented.
- **Fail:** cannot obtain 26.5 kernel artifact → Path A/B offline diff **blocked** until artifact exists (device stays on 26.5; no fake downgrade).

### Step 2 — Extract kernelcache + AVE / IOKit-related kexts (feasibility: high)
From both IPSWs: extract `kernelcache`, decompress, and pull AVE / changed IOKit kexts (exact bundle IDs from img4/im4p inventory — do not assume names until listed).

- **Success:** two trees on disk; file hashes logged under `research/ipados26.5/artifacts/` notes (paths only; large blobs gitignored).
- **Fail:** extract tooling mismatch → fix host tooling; no on-device guessing.

### Step 3 — Structured 26.5 vs 26.6 diff scoreboard (feasibility: medium–high)
Bindiff / symbol-assisted diff focused on scoreboard rows 1–6. Produce a **patch cluster table**: file → function → “size check / UAF / race / path check” — still **not** a trigger.

- **Success:** ranked list of ≤10 functions with evidence (diff hunk summary).
- **Fail:** no meaningful delta in assumed bundles → revise inventory; do not invent sinks.

### Step 4 — Reachability notes (feasibility: medium)
For top 3 clusters: which **user clients / MIG / XPC / MediaRemote paths** exist in **public headers, ioreg, or binary imports** — cite the artifact. Mark each: **reachable from third-party app?** yes / no / unknown.

- **Success:** at least one cluster marked reachable with citation, or all top-3 marked unknown/blocked.
- **Fail-closed:** “unknown” stays unknown — **no** selector invention.

### Step 5 — One fail-closed experiment design (feasibility: medium; run only if Step 4 cites reachability)
Design **one** Path B experiment (prefer offline harness or minimal on-device probe) attached to a hypothesis with (1)(2)(3). Prefer **non–daily-driver** device; note 26.5 unpatched risk.

Example shape (only after Step 4 cites a real client):

1. **Evidence:** advisory CVE-2026-64747 + concrete size-check hunk in AVE kext diff + named user-client method from binary.
2. **Test:** call only that documented external API / shared-memory path with boundary sizes from the hunk; capture panic log or no-op.
3. **Fail-closed:** no panic / no corruption after agreed input class → hypothesis **rejected**; do not escalate to “kernel exec.”

Until Step 4 has a citation, Step 5 remains **blocked**.

---

## 4) Explicit anti-patterns

| # | Do **not**… |
|---|-------------|
| 1 | Treat “kernel privileges” / “write kernel memory” in an advisory as a working exploit |
| 2 | Invent IOKit selectors / trigger paths from component names or impact blurbs alone |
| 3 | Claim PPL is solved by any single 26.6 CVE (or by MediaRemote root) |
| 4 | Mix XR / usbliter8 **18.7.5** work into this track without labeling **device + OS** change |
| 5 | Recommend unsigned restores / “just downgrade to 26.5” as if signing were open |
| 6 | Recover `pattern_F_` or private PPL bypasses from demos/credits |
| 7 | Block Path A on Pico / usbliter8 A12X bring-up |
| 8 | Promote a hypothesis to “the path” / “the jailbreak” without a defined success/fail signal |
| 9 | Equate Path B temporary root or panic with Path A KRW+PPL |
| 10 | Wire anything under `research/ipados26.5/` into `boot/` |
| 11 | Upgrade the matrix status line from Discord / YouTube / screenshots |
| 12 | Use the lab iPad as a daily driver while hunting on unpatched 26.5 without acknowledging risk |

Also see: [`../research/ipados26.5/ANTI_PATTERNS.md`](../research/ipados26.5/ANTI_PATTERNS.md).

---

## 5) Optional theories (max 3)

Only leads that are **plausible enough to write down** — still theories, not the plan.

### Theory 1 — AVE size-validation delta is the highest-leverage offline target
- **Evidence:** CVE-2026-64747 impact (kernel privileges) + “buffer overflow / improved size validation” class historically localizes to encoder kext size checks; A12X is in the advisory “Available for” list.
- **Next test:** Step 2–3 extract + list size-check hunks; Step 4 name clients from **binary**, not conjecture.
- **Fail-closed:** no size-related delta in AVE bundles between 26.5 and 26.6 → demote rank 1; do not keep “AVE is the jailbreak.”
- **Advances:** Path A **if** controllable write later; otherwise Path B crash only.

### Theory 2 — Kernel UAF/write CVEs are Path B first, Path A only after control
- **Evidence:** CVE-2026-64751 (write + UAF language), CVE-2026-64749 / CVE-2026-43778 (corrupt / UAF); app-reachable wording.
- **Next test:** cluster UAF fixes in kernelcache diff; require a cited local capability before any on-device fuzz.
- **Fail-closed:** clusters are unreachable from third-party apps (entitlement-gated only) → Path A blocked on those CVEs; keep as teacher diffs.
- **Advances:** Path B (repro) first; Path A only if corruption becomes directed.

### Theory 3 — MediaRemote root is a staging privilege, not KRW
- **Evidence:** CVE-2026-43723 “root privileges” + “path handling / improved validation.”
- **Next test:** framework diff for path validation; map whether a third-party app can hit the bad path **from public API surface**.
- **Fail-closed:** only reachable from entitled system processes → irrelevant to third-party Path A entry; document and close.
- **Advances:** Path B (temp root) at best; **does not** satisfy Path A PPL or KRW.

If this signal holds, a **jailbreak-shaped** next step would be: treat root only as a helper to load a **separate** kernel primitive — still **not** “we have a jailbreak.”

---

## 6) WRITEUP_WATCHLIST

Public artifacts that would **change status** (link into [`../research/ipados26.5/WRITEUP_WATCHLIST.md`](../research/ipados26.5/WRITEUP_WATCHLIST.md)):

| Artifact | Effect if citable + version-bounded |
|----------|-------------------------------------|
| Public **kernel exploit** with clear **≤26.5 / fixed 26.6** (or still-open) bounds and **A12/A12X** plausibility | May move matrix to **candidate watch** or lab-relevant after FILTER |
| Public **A12 / A12X PPL bypass** with install/test recipe | Unblocks Path A *second* stage — **never** replaces KRW |
| Writeup for **CVE-2026-64747** (AVE) or **CVE-2026-64751** / **43805** with trigger class | Converts advisory row → audit target with real sinks |
| Confirmation 26.5 IPSW still downloadable / hashes | Unblocks Step 1–2 offline |
| usbliter8 **t8027** PWND proof (serial `PWND:[usbliter8]`) | Enables Path C lab root — **label OS/device**; still ≠ 26.5 PE |

Non-movers: “iOS 26 jailbroken” YouTube, Discord screenshots, advisory-only blogs with no bounds.

---

## 7) Repo / Cursor workflow

| Concern | Rule |
|---------|------|
| **Docs home** | This file + [`../research/ipados26.5/`](../research/ipados26.5/) |
| **XR track** | [`RESEARCH_PLAN.md`](RESEARCH_PLAN.md) + [`../research/kexploit/`](../research/kexploit/) — **parked / secondary** while Path D/A 26.5 is active |
| **BootROM A12X** | [`../research/usbliter8-t8027/`](../research/usbliter8-t8027/) + [`research/usbliter8-t8027-bringup.md`](research/usbliter8-t8027-bringup.md) — Path C only |
| **Branches** | Prefer `cursor/*-a12x-26.5-*` (or this track’s PR branch) for 26.5 notes; avoid dumping 26.5 cards into `research/kexploit/experiments/T00N_*` |
| **Card IDs** | **P00N** series here; **T00N** remains XR 18.7.5 |
| **boot/** | Untouched for A12X; never reuse `n841ap` ramdisk/UDID |
| **Status line** | Separate: XR line stays in kexploit matrix; A12X line in [`PUBLIC_PRIMITIVE_MATRIX.md`](../research/ipados26.5/PUBLIC_PRIMITIVE_MATRIX.md) |
| **Cursor agents** | Point cloud agents at `research/ipados26.5/` + this plan; AGENTS.md still forbids inventing kexploit claims or wiring research into `boot/` |

---

## Continuity

After each step or failed experiment: update
[`../research/ipados26.5/NEXT.md`](../research/ipados26.5/NEXT.md) only —
**one** next action on the highest remaining lead. Do **not** rewrite this path
matrix unless facts change. Rule: [`../research/ipados26.5/CONTINUITY.md`](../research/ipados26.5/CONTINUITY.md).

## Next 48 hours

Live pointer (authoritative): [`../research/ipados26.5/NEXT.md`](../research/ipados26.5/NEXT.md).

**Primary:** **Step 1 — lock ProductVersion / ProductBuildVersion on the A12X iPad and confirm whether 26.5 + 26.6 IPSWs are obtainable for offline extract.**  
- Success: build string + IPSW availability noted in STATUS / `NEXT.md`.  
- Fail: no IPSW → hard block on offline diff; switch to backup in `NEXT.md`; stay on device 26.5; do not invent restore.

**Backup:** If IPSWs already local → Step 2/3 lite (hashes + Mach-O list). If IPSW unavailable → P001 writeup watchlist poll (docs only), then P002.
