# KRW test plan — read first, write later

Target: iPhone XR / **22H311**.  
Do not mark STATUS as KRW success without a command + expected output.

## Preconditions

- [ ] Build identity confirmed (SystemVersion **18.7.5 / 22H311**)
- [ ] Entry method recorded in STATUS (sideload A/B/C — see `docs/ENTRY.md`)
- [ ] Backend named + attributed in `ATTRIBUTION.md` (not stub)
- [ ] Offsets for this build filled or explicitly skipped with reason

## Phase 0 — Stub honesty (any host)

| Step | Action | Expected |
|------|--------|----------|
| 0.1 | Call `krw_init()` with default stub | `KRW_ERR_NO_BACKEND` |
| 0.2 | Call `kread` / `kwrite` | `KRW_ERR_NOT_INIT` or `KRW_ERR_NO_BACKEND` |
| 0.3 | `kbase()` / `kslide()` | `0` |

## Phase 1 — Init (real backend only)

| Step | Action | Expected |
|------|--------|----------|
| 1.1 | `krw_init()` | `KRW_OK` (or structured, logged failure — not a panic-as-success) |
| 1.2 | Log backend name + build guard (`22H311`) | Matches device |

## Phase 2 — Stable read (required before any write)

Pick **one** known-stable target agreed in notes (examples — do not invent addresses):

- Kernel version string / constant documented from **our** kernelcache, or  
- A field whose unslid offset was derived and cited in the session log  

| Step | Action | Expected |
|------|--------|----------|
| 2.1 | `kbase()` non-zero if model provides it | Matches offline expectation window |
| 2.2 | `kread` of chosen stable value | Bytes match expected hex/ASCII |
| 2.3 | Repeat 2.2 three times | Identical results |

Paste hex dumps into the panic/session log format in `docs/ATTRACT_DEVS.md`.

## Phase 3 — Controlled write (optional, later)

**Refuse** random or spray writes.

| Step | Action | Expected |
|------|--------|----------|
| 3.1 | Read target → save | Baseline |
| 3.2 | Minimal write → re-read | Matches written pattern |
| 3.3 | Restore original → re-read | Matches baseline |
| 3.4 | Device still responsive | No panic; still 22H311 |

## Explicit fails

- Panic without a logged hypothesis  
- Using offsets from another build  
- Claiming success from stub/`KRW_ERR_NO_BACKEND`  
- Skipping Phase 2  

## Related

- [krw.h](krw.h)
- [../../docs/KRW.md](../../docs/KRW.md)
- [../../docs/STATUS.md](../../docs/STATUS.md)
