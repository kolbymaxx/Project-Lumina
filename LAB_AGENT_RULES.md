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

## Boot + SSH (preferred)
- Stay on **Mac** + **`~/Projects/ICH_A12_plus_Ramdisk`** (`boot.sh`, vendored `iproxy`)
- Windows `usbliter8ctl` iBSS→go is **not** needed for current ramdisk use
- After erase: empty `/mnt2` user trees are expected — not a mount bug

## Data mount (15.1 legacy only)
- Never DYLD-hack Data mount on the 15.1 ramdisk
- Exit **76** on 15.1 Data remains **expected** (closed negative)

## Paths
| Role | Path |
|------|------|
| Lumina root | `~/Projects/lumina` |
| Status | `PROJECT_STATUS.md` + `docs/STATUS.md` |
| Live boot+SSH | `~/Projects/ICH_A12_plus_Ramdisk` |
| Experiment runner | `scripts/05_run_experiment.sh` (host DFU helpers; ICH for full boot) |
