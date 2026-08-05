# Attracting real JB developers

## One-line ask

Looking for A12 PPL notes or DS-K / PE help applicable to **22H311** `n841` (or a pre-18.7.2 sandbed); we are exhausting public DarkSword kexploit ports with reproducible lab logs — literature patch landmarks acknowledged, on-device proof required.

## What we are

Research toward a **real KRW demonstration** via **DS-K**, then PPL/bootstrap planning on the build where KRW works.

We acknowledge GTIG/Apple landmarks (PE fixed **18.7.2**) and still run structured on-device tests (H1/H2/H3). We do **not** ship DS-Full watering-hole kits, fake APIs, or Sileo-before-KRW.

## What reviewers should see

| Artifact | Why |
|----------|-----|
| [STATUS.md](STATUS.md) | Living truth + hypothesis table + result log |
| [DARKSWORD.md](DARKSWORD.md) | DS-Full vs DS-K + CVE/patch map |
| [LAB_DSK.md](LAB_DSK.md) | Exact on-device protocol + result codes |
| [ENTRY.md](ENTRY.md) | Signing reality (no TrollStore on 18.7.5) |
| `src/krw/` | Auditable API; no fabricated offsets |
| Panic / session logs | Template below |

## Repro (host tooling)

```bash
python3 -c "import pathlib; print('ok', pathlib.Path('docs/STATUS.md').exists())"
# Device lab requires Mac + signing — see ENTRY.md / LAB_DSK.md
```

## Panic / session log format

```text
### DS-K session YYYY-MM-DD
- Device: iPhone XR n841 / build …
- Entry: E1|E2|E3|E4
- Binary / commit:
- Result code: SUCCESS_KRW|FAIL_PATCHED|FAIL_OFFSETS|FAIL_ENTRY|FAIL_PANIC|UNKNOWN
- Hypothesis: H1|H2|H3
- Logs / panic:
```

## Success signals

| Milestone | Signal |
|-----------|--------|
| Entry chosen | E1–E4 in STATUS |
| First lab | Result code row (even FAIL_* counts) |
| KRW | `SUCCESS_KRW` with re-runnable read |
| PPL | Only after KRW — cited mechanism + tests |

## What we will not spam

- “First JB on 18.7.5” before `SUCCESS_KRW`  
- Fake offsets / pretend backends  
- usbliter8 as a substitute for this track’s PE work  
- WebKit implant packaging  

## Related

- [STATUS.md](STATUS.md)
- [DARKSWORD.md](DARKSWORD.md)
- [KRW.md](KRW.md)
- [ENTRY.md](ENTRY.md)
