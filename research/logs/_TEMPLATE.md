# Live session log

## Date / Track / Goal
- **Date:** YYYY-MM-DD
- **Track:** 1 (Data) | 2 (Kernel)
- **Goal:** (one sentence)

## Preconditions
- **iOS build:** (expect 18.7.5 / 22H311)
- **Unlock state:** A (unlock→use→pwn) | B (cold lock→pwn) | n/a
- **Host path used:** (e.g. `./boot/lumina-boot.sh` + known-good ramdisk — not a one-off unproven tree)
- **Read before start:** STATUS · T012 · NEXT_LIVE_SESSION · (Track 1: SEP plan | Track 2: WRITEUP_WATCHLIST)

## Steps actually run
(Fill in live — commands as executed, not aspirational.)

```
# paste or list
```

## Results
- **System mount:** RC / path / identity
- **Data mount:** hang | RC + exact string | skipped
- **S8 / other:** …
- **USB / serial notes:** (DFU/Recovery IDs if useful; no secrets)
- **Paths that worked:** …

## Stop reason
(hang / deny string / unexpected RC / wrong build / timebox / operator stop)

## Follow-ups
- Link plan docs only (e.g. `DATA_MOUNT_SEP_KEYBAG_PLAN.md`, experiment card).
- **No new exploits.** No inventing T008/T009 triggers. No `boot/` wiring.
