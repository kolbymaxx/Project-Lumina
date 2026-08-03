# t8027 PAC / control-flow — theory matrix

**Date:** 2026-08-03  
**Status:** research / THEORY only — **no READY candidates; no stub fills; A12X pwn not claimed**  
**Depends on:** [FIRST_RE_PASS.md](FIRST_RE_PASS.md), [PAC_AND_CONTROL_FLOW.md](PAC_AND_CONTROL_FLOW.md), [SYMBOL_WORKSHEET.md](SYMBOL_WORKSHEET.md), [experiments/candidates/C002-sram-trampoline-va-consistency-probe.md](experiments/candidates/C002-sram-trampoline-va-consistency-probe.md)

VA load base assumed `0x100000000`. Confirm in ibis/IDA before trusting any code VA.

---

## Scope / non-claims

- Every speculative mechanism below is labeled **THEORY — unconfirmed**.
- Confirmed facts (from first RE pass) are called out as such; they are not theories.
- Do not mark experiment candidates READY from this document.
- Do not paste numbers into [`stubs/`](stubs/).
- Do not treat SRAM resemblance to t8020 as CE proof.
- Live experiments, if ever authorized later, must be single-shot harness candidates — not blind spray.

---

## 1. Hard constraint — why t8020-style raw LR ROP is unlikely

### Confirmed divergence

| Fact | Source | Implication |
|------|--------|-------------|
| `pacibsp` ×462, `retab` ×364 on t8027; **0 / 0** on teacher t8020 `3865.0.0.4.7` | FIRST_RE_PASS §1 | Returns authenticate LR (key B / SP modifier class) |
| USB serial builder `@0x1000067bc` starts with `pacibsp` | FIRST_RE_PASS §2; PAC_AND_CONTROL_FLOW §1 | Hot DFU/USB path is inside the PAC regime |
| USB window `0x100006xxx`: ~18 `pacibsp` / ~15 `retab` in 4K | PAC_AND_CONTROL_FLOW §2.B | Race-relevant code is not a non-PAC island |
| t8020 gadget VAs are wrong code here | FIRST_RE_PASS §2 | Even ignoring PAC, overwrite LRs must be re-found |
| Upstream “A12 SecureROM has no PAC” | describes **t8020**, not this image | Cannot lean on that slogan for A12X |

### What the t8020 usbliter8 path needs

1. DWC2 underflow corrupts USB-task stack/heap in SRAM.
2. Saved **LR** (and short ROP) overwritten with **raw** code pointers.
3. Return / chain into shellcode → plant USB handler.
4. Handler later writes **unsigned** `JUMP_AWAY` into `MAIN_TASK_STACK_LR` (`WITH_PAC` off).

Step (2) and the handler’s unsigned LR poke assume returns that do **not** authenticate on use.

### Constraint statement

**Confirmed:** t8027 SecureROM is PAC-heavy on the USB-adjacent path.  
**THEORY — unconfirmed (strong prior):** smashing a USB-task saved LR with a raw gadget VA faults on `retab` rather than transferring PC.  
SRAM facts (`JUMP_STATE == 0x19C014030` confirmed; `0x19C018000` / `0x19C028000` plausible region-table entries; no `0x2391…` MMIO evidence) address *where memory lives*, not *how control flow authenticates*. Geography does not rescue a blind `t8020_create_overwrite` port.

Until a specific victim object is shown to use plain `ret` or unauthenticated `blr`, treat “ignore PAC / hope raw LR works” as a **planning dead end** (see §4).

---

## 2. Theory matrix

All entries: **THEORY — unconfirmed**.

### T1 — Signed LR forge (`PACIB` / t8030-shaped teacher)

| Field | Content |
|-------|---------|
| **Name** | Signed-return forge |
| **Core idea** | Keep stack-LR as the victim, but write a pointer signed for the consumer’s `retab`/`autib` context (key B, SP modifier), not a raw VA. Teacher shape: t8030 `WITH_PAC` path in upstream `handler.c` (`PACIB(JUMP_AWAY, …)`). First hijack may need a signing gadget or an already-running context that can sign. |
| **Why plausible** | Matches measured `pacibsp`/`retab` density; explains why t8020 unsigned LR fails; same race *memory* story (`0x19C0…`) can still supply the overwrite surface once MMIO/DMA dest is known. |
| **Falsify if** | Victim return uses plain `ret`; or no usable signing primitive / wrong modifier always faults; or race never hits an LR slot. |
| **Offline RE next** | For candidate victim frames: key A vs B, modifier (SP vs disc), `retab` vs `retaa`; locate `pacib`/`pacibsp` producers; map `MAIN_TASK_STACK_LR`-class SRAM only after stack map exists. |
| **Future live (high level)** | Single prepared overwrite that installs one **signed** LR (not a ROP spray). Success signal: controlled deviation (e.g. `PWND:` or deterministic USB anomaly), not “try many signatures.” |
| **Confidence** | Medium (as *class*); Low on any concrete key/modifier. |
| **DRAFT candidate soon?** | **No** — needs victim + PAC context first. Keep as planning umbrella. |

### T2 — Short non-PAC / plain-`ret` window as race victim

| Field | Content |
|-------|---------|
| **Name** | Plain-`ret` victim window |
| **Core idea** | DMA underflow hits a frame that still returns with plain `ret` (282 present in ROM), so raw LR ROP works *for that frame only*. |
| **Why plausible** | Plain `ret` count is non-zero; early/system-register helpers may be non-PAC. If the race’s exact victim is one of those frames, t8020-shaped ROP roles could return (with new gadget VAs). |
| **Falsify if** | Identified USB-task / DFU victim uses `retab`; or plain-`ret` sites have no overlap with the underflow-reachable stack. |
| **Offline RE next** | Identify exact saved LR the DWC2 path can corrupt; disassemble that function’s epilogue; do **not** assume “282 plain ret ⇒ USB path is open.” PAC_AND_CONTROL_FLOW already notes USB `0x100006xxx` is PAC-rich. |
| **Future live (high level)** | Only after victim epilogue is plain `ret`: one minimal raw-LR overwrite toward a harmless observable (e.g. known ROM spin / serial mutation helper) — never a gadget spray. |
| **Confidence** | Low for USB-task victim; Speculative as primary strategy. |
| **DRAFT candidate soon?** | **No** — weak until victim ID. Worth a short offline kill/keep pass only. |

### T3 — Non-LR control object (callback / handler CB smash)

| Field | Content |
|-------|---------|
| **Name** | Callback / FP smash |
| **Core idea** | Overwrite a SRAM function pointer (e.g. `USB_REQ_HANDLER_CB`-class) that is loaded and `blr`’d, rather than a saved LR. Auth policy may differ from `retab` (raw `blr`, `blraa`/`blrab`, or signed FP). |
| **Why plausible** | Worksheet already tracks `USB_REQ_HANDLER_CB_ADDR` as a first-class plant target on t8020; FIRST_RE_PASS flags busy ADRP traffic around `0x19C010000` and DFU-string site `0x10000ad58` toward `HANDLE_USB_REQ`. Avoids assuming LR is the only CF object. |
| **Falsify if** | No mutable CB in underflow range; or load path uses authenticated branch that rejects raw pointers with no forge path; or CB is write-once / checksummed. |
| **Offline RE next** | From `0x10000ad58` / serial builder callers: find stores to SRAM under `0x19C010000`; note whether call sites use `blr`, `blraa`, or auth. Rank CB slots by DFU-request reachability. |
| **Future live (high level)** | One overwrite aimed at a single CB slot → one known ROM function that mutates serial/USB observably (still not PWND-or-bust). Classify with harness. |
| **Confidence** | Medium as *direction*; Speculative on any concrete slot. |
| **DRAFT candidate soon?** | **Maybe (DRAFT only)** after one evidenced CB store/load pair — still not READY. |

### T4 — Reuse already-authenticated function pointers (selector corruption)

| Field | Content |
|-------|---------|
| **Name** | Authenticated FP reuse / selector corruption |
| **Core idea** | Do not forge PAC. Corrupt *data* that chooses among pointers the ROM already signed (index, flags, object fields), so a legitimate authenticated call/return lands on attacker-chosen *existing* code, then pivot via corrupted state. |
| **Why plausible** | Sidesteps needing a signing gadget; consistent with PAC density (auth stays valid); SecureROM often has small sets of USB/DFU handlers selected by request type. |
| **Falsify if** | No selectable authenticated targets near corruptible state; or selection is immediate VA in writable SRAM (collapses to T3); or corrupted selectors only panic. |
| **Offline RE next** | DFU control-request dispatch: switch/table near `HANDLE_USB_REQ` candidates; which table entries are ROM constants vs SRAM; whether PAC wraps the chosen target. |
| **Future live (high level)** | Flip one selector/field that should invoke an alternate *benign* ROM path with a distinct USB observable — not shellcode plant on first try. |
| **Confidence** | Speculative (clever; thin evidence today). |
| **DRAFT candidate soon?** | **No** — needs dispatch-table RE. Stronger as offline hunt than live. |

### T5 — Exit classic ROP: data-only → deferred hijack

| Field | Content |
|-------|---------|
| **Name** | Data-only deferred CF |
| **Core idea** | First race write is purely data (heap metadata, task state, descriptor buffers, `JUMP_STATE`-adjacent flags). Later a *legitimate* signed return or scheduled callback consumes that state and reaches attacker-controlled continuation (e.g. tramp bank once mapped). |
| **Why plausible** | Confirmed `JUMP_STATE` + plausible tramp/heap banks give *state* surfaces; PAC makes immediate LR ROP hard, so “corrupt now, hijack later” matches the constraint. C002 correctly refuses to treat geography as CE. |
| **Falsify if** | No consumer of corrupted state that yields PC control; or data corruption only panics (`double panic` / `panic:` strings exist — easy failure mode). |
| **Offline RE next** | Who reads `JUMP_STATE`; clear-loop / region roles for `0x19C018000`; heap checksums (`CALCULATE_HEAP_BLOCK_SUM`-class) that would kill silent metadata corruption. |
| **Future live (high level)** | Extremely constrained: one data-only mutation with a predicted non-CF observable first (stability vs panic). CF attempt only after consumer RE. |
| **Confidence** | Speculative — easy to hand-wave; call out as **weak** without a named consumer. |
| **DRAFT candidate soon?** | **No** for CF; optional later DRAFT for “data poke → panic/no-panic” telemetry only. |

### T6 — USB/DFU path objects that are less PAC-protected than LR

| Field | Content |
|-------|---------|
| **Name** | DFU path soft targets |
| **Core idea** | Focus corruption on USB/DFU *objects* (descriptor buffers, setup-packet mirrors, DOEPDMA-linked SRAM, serial string slots) that influence control flow or DMA continuation without being saved LR — possibly less PAC-wrapped than function returns. |
| **Why plausible** | Race class is DWC2 Setup-ring / DMA underflow (family claim); missing `0x2391…` means MMIO base is unknown, but the *logical* soft targets still exist. Serial builder uses SRAM `0x19C00C000` / `0x19C010000` (FIRST_RE_PASS). Descriptor restore is a known t8020 overwrite role (worksheet §4.2) even if VAs differ. |
| **Falsify if** | Soft targets are not in underflow reach; or they never feed CF (only data echoed to host); or all continuation is still via `retab` frames. |
| **Offline RE next** | Map DFU EP0 buffer / setup queue SRAM; xrefs from second DFU-string site `0x10000ad58`; find DMA descriptor formats without assuming `0x2391`. |
| **Future live (high level)** | Observation-first (C002-class), then one targeted soft-target overwrite aimed at a host-visible descriptor/serial change — CF escalation only if RE shows a CF edge. |
| **Confidence** | Low–Medium for *host-visible* effects; Speculative for *PC control*. |
| **DRAFT candidate soon?** | **Yes as DRAFT observation/descriptor probe** after MMIO or buffer VA candidates exist — still dry-run / manual_pico gated; not READY now. |

### T7 — Hybrid planning frame (memory story + PAC-aware first hijack)

| Field | Content |
|-------|---------|
| **Name** | Hybrid (race memory + PAC-aware CE + WITH_PAC handler) |
| **Core idea** | (1) Keep DWC2 + `0x19C0` SRAM as the corruption channel (partially evidenced). (2) First PC control via T1 or T3, not raw LR. (3) Plant handler with t8027 `WITH_PAC`-style signed `JUMP_AWAY` (t8030 teacher), not t8020 unsigned poke. |
| **Why plausible** | Explicit synthesis in PAC_AND_CONTROL_FLOW §2.E; aligns worksheet priority (victim → PAC policy → handler → tramp → MMIO). Avoids false choice between “same race” and “different CE.” |
| **Falsify if** | Race shape itself differs on t8027 (no usable underflow); or no PAC-aware plant path exists even after victim ID. |
| **Offline RE next** | Execute PAC_AND_CONTROL_FLOW §3 address plan (`0x100001944`, `0x100008180`, `0x1000067bc`) with PAC verdict per frame; kill T2 early if USB victim is `retab`. |
| **Future live (high level)** | Sequence of **few** READY-gated single-shot candidates: baseline dry-run → one memory-shape probe → one CF theory probe. Never a loop. |
| **Confidence** | Medium as *program of work*; does not elevate any sub-theory’s confidence. |
| **DRAFT candidate soon?** | **Program-level yes** — spawn DRAFT children from T3/T6 when evidence rows appear; T7 itself is not one experiment. |

### T8 — Exception / IRQ / tramp-PTE as *first* hijack

| Field | Content |
|-------|---------|
| **Name** | Exception / IRQ / PTE-first |
| **Core idea** | Divert an exception vector, IRQ handler, or boot-tramp PTE to gain EL1 without USB-task LR ROP. |
| **Why plausible** | PAC_AND_CONTROL_FLOW lists it; tramp/PTE symbols exist on t8020 teacher (`BOOT_TRAMP_PTE*`, `ROM_TRAMP`). |
| **Falsify / weakness** | SecureROM DFU rarely exposes useful IRQ diversion; tramp/PTE abuse on t8020 is **after** PC control, not a substitute. **Weak / hand-wavy** without a DFU-time registration site. |
| **Offline RE next** | Quick kill pass: any mutable vector/IRQ registration in DFU-resident SRAM? If none, archive. |
| **Future live (high level)** | Not justified until offline evidence of a mutable DFU-time handler slot. |
| **Confidence** | Speculative (weak). |
| **DRAFT candidate soon?** | **No.** |

---

## 3. Ranked shortlist — top 3 to pursue first

| Rank | Theory | Rationale |
|------|--------|-----------|
| **1** | **T3 — Callback / FP smash** | Best chance to *avoid* `retab` while staying on the USB/DFU path we can actually xref (`0x1000067bc`, `0x10000ad58`, `0x19C010000` traffic). Worksheet already expects a handler CB plant. Offline cost is concrete; live stays single-object. |
| **2** | **T1 — Signed LR forge** | Highest-fidelity match to measured PAC density and t8030 teacher. Remains the fallback if the race victim *is* an LR slot. Blocked on key/modifier/victim — prioritize RE, not live. |
| **3** | **T6 — DFU soft targets** (as a bridge) | Advances the missing MMIO/buffer map without pretending CF is solved; produces host-visible observables for harness classification; feeds T3/T1 with real underflow reachability. |

**T7 (hybrid)** is the recommended *portfolio* wrapping 1–3, not a competing CE mechanism.

Deprioritize T2 until victim epilogue is known (likely kill). Park T4/T5/T8 as offline side quests.

---

## 4. Explicit non-theories (stop spending time for now)

| Non-theory | Why stop |
|------------|----------|
| **Raw LR ROP copied from t8020** (“ignore PAC”) | Contradicted by confirmed `retab`/`pacibsp` density on USB-adjacent code; PAC_AND_CONTROL_FLOW §2.D. |
| **Same VAs as t8020 gadgets / `0x239100B14` DMA dest** | FIRST_RE_PASS: gadget VAs differ; **no** `0x2391…` evidence — inventing MMIO is stub self-deception. |
| **SRAM geography ⇒ CE works** (`JUMP_STATE` / `0x19C018000` / `0x19C028000`) | Confirmed/plausible *memory* only; C002 hypothesis correctly separates geography from PAC CF. |
| **Blind offset / timing spray on Pico** | Violates lab discipline; no victim model; expected outcome is noise (`NO_EFFECT` / random `USB_ANOMALY`), not learning. |
| **Exception/IRQ-first (T8) as near-term bet** | No DFU-time evidence; historically post-hijack on teacher path. |
| **Filling stubs to “try the device”** | Hard rule; worksheet rows stay THEORY/TODO until evidence — PWND serial is the only success claim. |
| **Marking C002 (or siblings) READY for CF probes** | C002 is observation baseline; PAC matrix does not authorize READY. |

---

## 5. Suggested offline order (before any CF live candidate)

1. Kill/keep **T2**: epilogue of the best USB-task victim candidate — `retab` or plain `ret`?
2. Map **T3**: SRAM CB store/load near `0x19C010000` / DFU request path.
3. Deepen **T1** only for that victim’s PAC context (or for `MAIN_TASK_STACK_LR` post-plant).
4. Hunt USB MMIO / EP0 buffers (**T6**) without seeding `0x2391`.
5. Validate tramp role of `0x19C018000` (shellcode plant) — still not first hijack.
6. Only then consider a **DRAFT** harness candidate (likely dry-run or one manual_pico), still not READY until payload plan names one object and one observable.

---

## See also

- [PAC_AND_CONTROL_FLOW.md](PAC_AND_CONTROL_FLOW.md) — original strategy sketches A–E  
- [FIRST_RE_PASS.md](FIRST_RE_PASS.md) — PAC counts, `JUMP_STATE`, region table, no `0x2391`  
- [SYMBOL_WORKSHEET.md](SYMBOL_WORKSHEET.md) — row tracking  
- [experiments/README.md](experiments/README.md) — READY-gated single-shot discipline  
- Upstream teacher (shape only): `usb_req_handler/handler.c` (`WITH_PAC`)
