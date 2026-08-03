# C002 — SRAM trampoline VA consistency probe

## Status
DRAFT

<!-- Allowed: DRAFT | READY | DONE | ABORTED
     run_experiment.sh will only execute when Status is exactly READY. -->

## Action
dry-run

<!-- Allowed (exactly one):
     dry-run       — pre/post checks + logging only; no Pico/host payload
     manual_pico   — operator runs one prepared Pico step between pre/post checks
     Harness defaults to dry-run if this field is missing or unrecognized. -->

## Hypothesis
t8027 SecureROM appears to reuse a **0x19C0… SRAM window** (JUMP_STATE / tramp / heap-bank hints), but the ROM is **PAC-heavy** (`pacibsp` / `retab` class). Therefore:

1. Shared SRAM *geography* with t8020 must **not** be read as “t8020 unsigned LR-ROP transfers.”
2. Any later CE theory for A12X must be **PAC-aware** (signed return / auth gadgets), not a copy of the t8020 overwrite frame.
3. For this candidate only: under read-only host observation, the live DFU identity stays a stable baseline (same CPID/ECID/SRTG, no `PWND:`), so subsequent PAC-aware experiments have a clean pre-state to compare against.

Falsification for *this* dry-run: spontaneous identity/MODE/`PWND` change under observation-only queries (unexpected; would block treating the session as a quiet baseline).

## Evidence
- **LIVE_SESSION.md** (2026-08-02 ~20:44 / C001): live DFU `05ac:1227`, serial  
  `CPID:8027 … BDID:0A ECID:0019052A1413002E … SRTG:[iBoot-4172.0.0.100.14]`,  
  product `iPad8,7` / `j321ap`, no `PWND:`; C001 dry-run classified **NO_EFFECT**.
- **FIRST_RE_PASS.md** (dump pass on `artifacts/SecureROM_t8027_4172.bin`, SRTG 4172.0.0.100.14):
  - `JUMP_STATE` appears at **0x19C014030**
  - Heavy literal / table traffic in **0x19C0…** SRAM
  - Plausible but **unconfirmed**: `shc_base` / TRAMP ≈ **0x19C018000**, heap bank ≈ **0x19C028000**
  - **No** evidence yet for t8020-style USB MMIO at **0x2391…**
- **PAC_AND_CONTROL_FLOW.md**:
  - ROM control flow is PAC-dense (`pacibsp` / `retab` class) — unlike the non-PAC t8020 SecureROM CE assumption
  - Implication: stack-LR overwrite strategies that work on t8020 are **not** a default for t8027
- Cross-check (artifact scan, not a new claim): `0x19C018000` and `0x19C028000` appear as u64 literals in the ROM image; aligned `0x2391…` u64s not seen; `retab` opcode density is high. Treat as support for the notes above, not as confirmed gadget locations.

## Payload plan
Observation-only (Action=`dry-run`):

- none — no Pico step, no host `demote`/`boot`/`send`, no DFU DNLOAD
- Harness pre/post: `python3 ./usbliter8ctl info` and `irecovery -q` only
- Human review afterward: compare serial / MODE / PRODUCT / NONC / SNON / IBFL to LIVE_SESSION baseline; do **not** interpret stability as evidence that tramp VA is correct or that ROP would work

## Risk
Low. Read-only USB queries only. No race, no overwrite, no firmware flash. Residual risk is ordinary DFU USB flakiness (brief disconnect) from host enumeration — not payload-induced.

## Expected observable
Default success for this DRAFT’s dry-run intent: **NO_EFFECT** (stable unpwned DFU).

Still **interesting without PWND** (would elevate attention / possibly `USB_ANOMALY`):

- Serial token drift (IBFL, SCEP, or unexpected field) while CPID/ECID/SRTG stay put
- MODE or PID change without `PWND:`
- NONC/SNON rotation coupled with any USB re-enumerate oddity
- Device disappear / reappear mid dry-run
- Any `PWND:` tag (highly unexpected for observation-only — treat as ERROR/investigate, not success)

Non-goals for this candidate: proving tramp=0x19C018000, proving JUMP_STATE, or claiming A12X pwn.

## Live result
<!-- Filled by run_experiment.sh after a live run. Do not pre-fill. -->

- Classification:
- Log:
- Notes:
