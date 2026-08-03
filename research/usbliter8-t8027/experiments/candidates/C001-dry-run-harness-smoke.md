# C001 — dry-run harness smoke

## Status
DONE

<!-- Allowed: DRAFT | READY | DONE | ABORTED
     run_experiment.sh will only execute when Status is exactly READY. -->

## Action
dry-run

<!-- Allowed (exactly one):
     dry-run       — pre/post checks + logging only; no Pico/host payload
     manual_pico   — operator runs one prepared Pico step between pre/post checks
     Harness defaults to dry-run if this field is missing or unrecognized. -->

## Hypothesis
Harness pre/post USB checks see stable unpwned t8027 DFU (CPID 8027, ECID 0019052A1413002E, SRTG iBoot-4172.0.0.100.14) with no serial change.

## Evidence
- LIVE_SESSION 2026-08-02 DFU identity confirm
- artifacts/SecureROM_t8027_4172.bin present (RE only; unused by this dry-run)

## Payload plan
none

## Risk
None beyond read-only USB queries (`usbliter8ctl info`, `irecovery -q`).

## Expected observable
Classification NO_EFFECT; pre/post serial identical; no PWND tag.

## Live result

- Classification: NO_EFFECT
- Log: experiments/logs/20260802-205442-C001.log
- Action: dry-run
- Timestamp: 2026-08-02 20:54 EDT
- Notes: still DFU; serial/identity unchanged; no PWND
