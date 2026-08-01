# Lab agent rules

Operating rules for agents driving the usbliter8 lab package under
`~/Projects/lumina`. Do **not** re-scaffold the package when these change.

## Human gates
The human only gates:
- DFU / re-pwn
- Anything destructive or unclear

After the human says **`pwned, go`** (or `scripts/01_wait_pwned.py` succeeds):
run the experiment **end-to-end** without asking permission for each small command.

## Logging
- Write under `logs/`
- Prefer clear failures over silent success
- `usbliter8ctl` via existing lookup (`scripts/lib_paths.py` / `scripts/lib_ctl.sh`)

## Device lost → STOP
If the live device is gone (no `05ac:1227` / `05ac:1281`, SSH dead, back to iOS),
**STOP** and reply **only** in this format:

```markdown
## Need re-pwn
**What failed:** ...
**Evidence:** ...
**Next theory after I re-pwn:** ...
**Commands you will run first after PWND:** ...
```

Do **not** ask for re-pwn unless the live device is actually gone.
If the human has not said otherwise, assume they are still in ramdisk SSH.

## Data mount (15.1)
- Never DYLD-hack Data mount on the 15.1 ramdisk
- Exit **76** on Data remains **expected** (not success, not a reason to re-pwn)

## Paths
| Role | Path |
|------|------|
| Lumina root | `~/Projects/lumina` |
| Status | `PROJECT_STATUS.md` + `docs/STATUS.md` |
| Experiment runner | `scripts/05_run_experiment.sh` |
