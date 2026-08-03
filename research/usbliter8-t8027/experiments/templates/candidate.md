# CXXX — short title

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
One falsifiable claim. Example: “If ROP frame X lands at VA Y, DFU serial gains PWND:[usbliter8].”

## Evidence
Pointers only (dump offsets, RE notes, prior LIVE_SESSION entries). No invented addresses.

-

## Payload plan
What will be attempted in the single live action. For dry-run, write “none”.
For manual_pico, name the exact prepared UF2/procedure the operator will run once.

-

## Risk
What can go wrong (USB disconnect, SecureROM panic→reboot to DFU, wrong cable path, etc.).

-

## Expected observable
Concrete post-check signal. Prefer serial / MODE / PID changes over vibes.

-

## Live result
<!-- Filled by run_experiment.sh after a live run. Do not pre-fill. -->

- Classification:
- Log:
- Notes:
