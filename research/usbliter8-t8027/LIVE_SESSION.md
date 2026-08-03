# t8027 live session log

**Device (expected):** iPad Pro 12.9" 3rd gen Cellular — `iPad8,7` / `j321ap` / CPID `8027`  
**Rules:** observation only unless explicitly authorized to pwn/send. No invented offsets. No Pico flash unless asked.

## How to log an entry

Copy the template below. One entry per action. Prefer raw command output over interpretation.

```text
### YYYY-MM-DD HH:MM TZ — <short title>
- Host: <mac hostname / cwd>
- Goal: <one line>
- Command(s):
  ```
  <exact commands>
  ```
- Observed:
  - USB: <vid:pid bus/addr if known>
  - Serial: <full DFU serial string>
  - Other: <irecovery fields, descriptor notes, errors>
- Delta vs prior: <unchanged | changed field=old→new | first sighting>
- Interpretation (optional, labeled): <hypothesis only — not fact>
- Next: <optional>
```

## Session identity baseline

| Field | Expected |
|-------|----------|
| USB | `05ac:1227` DFU |
| CPID | `8027` |
| CPRV | `01` |
| CPFM | `03` |
| BDID | `0A` |
| ECID | `0019052A1413002E` |
| SRTG | `[iBoot-4172.0.0.100.14]` |
| Product (irecovery) | `iPad8,7` / `j321ap` |
| PWND tag | absent (unpwned DFU) |

Stable identity = same CPID/BDID/ECID/SRTG string. Bus/addr may change across re-plugs.

---

## Entries

### 2026-08-02 ~20:44 EDT — DFU identity confirm (no pwn)
- Host: Mac, `~/Projects/lumina`
- Goal: Confirm device still visible; serial matches baseline; note USB descriptors only
- Command(s):
  ```
  python3 ./usbliter8ctl info
  irecovery -q
  # plus pyusb descriptor dump (read-only)
  ```
- Observed:
  - USB: `05ac:1227` DFU, bus=20 addr=7, bcdDevice=0
  - Serial: `CPID:8027 CPRV:01 CPFM:03 SCEP:01 BDID:0A ECID:0019052A1413002E IBFL:3C SRTG:[iBoot-4172.0.0.100.14]`
  - Product string: `Apple Mobile Device (DFU Mode)` / mfr `Apple Inc.`
  - Config: cfg=1, 1 interface, intf0 alt0 class `254:1:0`, **0 endpoints** (control-only DFU)
  - irecovery: MODE=DFU, PRODUCT=`iPad8,7`, MODEL=`j321ap`, NAME=`iPad Pro 12.9-inch (3rd gen, Cellular)`
  - NONC=`2b19954bdc76cdbe71492219848e7eae73fdfaf3da38fab2e0cc5675d9f9e440`
  - SNON=`f8156dffa405a2d3e6cc004ba29152457785d359`
  - No `PWND:[…]` in serial
- Delta vs prior: first logged live sighting this session; matches operator-stated identity
- Interpretation (optional): unpwned SecureROM DFU; host ctl can see device when run with normal Mac USB permissions
- Next: await explicit instruction before any pwn / payload send

### 2026-08-02 20:54 EDT — experiment C001 [NO_EFFECT]
- Host: iMac, repo `/Users/kolby/Projects/lumina`
- Goal: Harness pre/post USB checks see stable unpwned t8027 DFU (CPID 8027, ECID 0019052A1413002E, SRTG iBoot-4172.0.0.100.14) with no serial change.
- Candidate: `C001-dry-run-harness-smoke.md` Action=`dry-run`
- Cable: direct Mac USB; harness smoke (no Pico)
- Command(s):
  ```
  research/usbliter8-t8027/experiments/run_experiment.sh C001
  python3 ./usbliter8ctl info   # pre + post
  irecovery -q                  # pre + post
  ```
- Observed:
  - Pre serial: `CPID:8027 CPRV:01 CPFM:03 SCEP:01 BDID:0A ECID:0019052A1413002E IBFL:3C SRTG:[iBoot-4172.0.0.100.14]`
  - Post serial: `CPID:8027 CPRV:01 CPFM:03 SCEP:01 BDID:0A ECID:0019052A1413002E IBFL:3C SRTG:[iBoot-4172.0.0.100.14]`
  - Pre MODE/PRODUCT: `DFU` / `iPad8,7`
  - Post MODE/PRODUCT: `DFU` / `iPad8,7`
  - Classification: **NO_EFFECT** — still DFU; serial/identity unchanged; no PWND
- Delta vs prior: unchanged
- Interpretation (optional, labeled): harness result only; not an A12X exploit claim
- Next: review `research/usbliter8-t8027/experiments/logs/20260802-205442-C001.log` and candidate Live result
