# t8027 live experiment harness

Disciplined, single-shot testing of **prepared** payload theories against the A12X iPad in DFU.

This is not a fuzzer. No autonomous looping, no random offset mutation, no payload spray.

## Workflow

```text
hypothesis  →  candidate file  →  READY gate  →  one live test  →  log / classify
```

1. **Hypothesis** — Write one falsifiable claim with evidence (RE notes, dump findings). Unconfirmed VAs stay labeled unconfirmed.
2. **Candidate file** — `./new_candidate.sh "short title"` creates `candidates/C00N-….md` from the template.
3. **READY gate** — Edit the candidate. Fill Evidence / Payload plan / Expected observable. Set `Status` to `READY` only when you intentionally authorize one run. Set `Action` to `dry-run` (default) or `manual_pico`.
4. **Single live test** — From repo root (or this directory):
   ```bash
   ./research/usbliter8-t8027/experiments/run_experiment.sh C001
   ```
   The script aborts unless `Status` is `READY`. It never loops. It never sends host payloads (`demote`/`boot`/`send`).
5. **Log / classify** — Full transcript under `logs/`. Structured summary appended to `../LIVE_SESSION.md`. Candidate marked `DONE` with classification:
   - `NO_EFFECT` — still DFU, identity stable, no `PWND:`
   - `USB_ANOMALY` — disappear / PID·MODE·identity change without PWND
   - `PWND` — serial contains `PWND:`
   - `ERROR` — tool failure or unreadable pre/post state

## Actions (current)

| Action | Behavior |
|--------|----------|
| `dry-run` | Pre-check → skip payload → post-check → classify. Default if unset/unknown. |
| `manual_pico` | Pre-check → wait for operator to run **one** prepared Pico step → Enter → post-check → classify. |

Host `usbliter8ctl` mutation commands are **not** wired here on purpose.

## Hard rules

- No autonomous looping
- No random offset mutation
- No payload path unless candidate `Status=READY`
- Default to `dry-run` if `Action` is missing or not explicitly defined
- Do not touch `boot/` or invent offset stubs from this harness
- Prefer observation; claim A12X pwn only when serial shows `PWND:`

## Layout

```text
experiments/
  README.md                 # this file
  new_candidate.sh          # create next C00N markdown
  run_experiment.sh         # READY-gated single run
  templates/candidate.md
  candidates/C00N-*.md
  logs/YYYYMMDD-HHMMSS-C00N-*.log
```

## Environment (optional)

| Variable | Purpose |
|----------|---------|
| `LUMINA_CABLE_NOTES` | Skip interactive cable prompt |
| `LUMINA_REPO_ROOT` | Override repo root (default: walk up to `usbliter8ctl`) |
| `LUMINA_USBLITER8CTL` | Override path to `usbliter8ctl` |
