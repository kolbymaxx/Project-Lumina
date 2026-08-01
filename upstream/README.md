# Upstream checkouts (local / agent)

Official source of truth for usbliter8 was:

`https://github.com/prdgmshift/usbliter8`

As of 2026-08-01 that org shows **0 public repos** and the URL 404s.
For host/tooling setup, this tree clones a public snapshot that matches the
2026-06-18 disclosure tree:

`https://github.com/ahmadkamal09999-tech/usbliter8` → `upstream/usbliter8/`

Do **not** commit the nested clone. Re-clone on each machine with:

```bash
mkdir -p upstream
git clone --depth 1 https://github.com/ahmadkamal09999-tech/usbliter8.git upstream/usbliter8
# Prefer the official URL again if/when it returns:
# git clone --depth 1 https://github.com/prdgmshift/usbliter8.git upstream/usbliter8
```

Lumina already vendors `./usbliter8ctl` at repo root for day-to-day DFU control.
