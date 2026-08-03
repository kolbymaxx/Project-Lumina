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
Confirmed t8027 SecureROM geography (`JUMP_STATE` @ `0x19C014030`, heavy `0x19C0…` SRAM, region-table hints at `0x19C018000` / `0x19C028000`) does **not** imply a transferable t8020 unsigned LR-ROP path: the same image is PAC-heavy (`pacibsp` ×462, `retab` ×364). Blind copy of `t8020_create_overwrite` is therefore a disproven planning assumption until a specific victim return is shown to use plain `ret` (or a signed-pointer plan exists).

For this dry-run only: under read-only host observation, live DFU identity remains a stable unpwned baseline (CPID/ECID/SRTG match LIVE_SESSION; no `PWND:`), so later PAC-aware experiments have a quiet pre-state. This candidate does **not** validate tramp/heap VAs or claim A12X pwn.

Falsification here: spontaneous identity / MODE / `PWND` change under observation-only queries.

## Evidence
- [`research/usbliter8-t8027/LIVE_SESSION.md`](../../LIVE_SESSION.md) (2026-08-02 ~20:44 / C001): live `05ac:1227` DFU, serial `CPID:8027 … BDID:0A ECID:0019052A1413002E … SRTG:[iBoot-4172.0.0.100.14]`, `iPad8,7` / `j321ap`, no `PWND:`; C001 → **NO_EFFECT**.
- [`research/usbliter8-t8027/FIRST_RE_PASS.md`](../../FIRST_RE_PASS.md) §1–§2 (`SecureROM_t8027_4172.bin`, SHA-256 `22386685…7a8baf`):
  - **Confirmed** `JUMP_STATE == 0x19C014030` (`adrp`/`add` @ `0x100001944`)
  - **Confirmed** SRAM window under `0x19C0…` (heavy ADRP traffic)
  - Region table @ `0x100008180` includes `0x19C018000`, `0x19C028000` — **plausible** `TRAMP_BASE`/`shc_base` and heap/stack bank; **needs validation**
  - PAC divergence vs t8020 teacher: `pacibsp` (`0xD503237F`) ×**462**, `retab` ×**364** (t8020: 0 / 0)
  - USB DMA dest `0x239100B14` / `0x2391…`: **no literal or movk evidence** — do not assume
- [`research/usbliter8-t8027/PAC_AND_CONTROL_FLOW.md`](../../PAC_AND_CONTROL_FLOW.md) §1–§2, §4:
  - SRAM resemblance does not rescue t8020 LR smash; `retab` implies raw gadget LRs fault
  - USB serial builder @ `0x1000067bc` is inside the PAC regime (`pacibsp`)
  - Strategy priority: identify victim CF object + PAC policy **before** tramp validation / Pico
  - USB MMIO still missing (priority 8); no `0x2391` evidence
- [`research/usbliter8-t8027/SYMBOL_WORKSHEET.md`](../../SYMBOL_WORKSHEET.md) §4.1 / §4.3 / §4.6:
  - `JUMP_STATE` → **Confirmed** `0x19C014030`
  - `shc_base` / `TRAMP_BASE` → plausible `0x19C018000` (not stub-ready)
  - `USB_DMA_DEST` → TODO; explicitly no `0x2391` evidence yet
  - Handler PAC → **Confirmed PAC-heavy**; t8020 non-PAC assumption likely wrong

## Payload plan
Observation-only (Action=`dry-run`):

- none — no Pico step, no host `demote`/`boot`/`send`, no DFU DNLOAD
- Harness pre/post: `python3 ./usbliter8ctl info` and `irecovery -q` only
- Afterward: compare serial / MODE / PRODUCT / NONC / SNON / IBFL to LIVE_SESSION baseline; do **not** treat stability as proof of tramp VA or ROP viability

## Risk
Low. Read-only USB queries only. No race, overwrite, or firmware flash. Residual risk is ordinary DFU USB flakiness from host enumeration.

## Expected observable
Default for this dry-run: harness **NO_EFFECT** (stable unpwned DFU; identity matches baseline).

Interesting **without** `PWND` (attention / possible `USB_ANOMALY`):

- IBFL / SCEP / other serial-token drift with CPID/ECID/SRTG unchanged
- MODE or PID change without `PWND:`
- NONC/SNON rotation plus USB re-enumerate oddity
- Device disappear / reappear during the dry-run
- Any `PWND:` tag (unexpected for observation-only — investigate, not success)

Non-goals: proving `0x19C018000` tramp, promoting worksheet rows, stub fills, or A12X exploit claims.

## Live result
<!-- Filled by run_experiment.sh after a live run. Do not pre-fill. -->

- Classification:
- Log:
- Notes:
