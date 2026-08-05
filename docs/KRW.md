# KRW — DS-K integration + lab results

**Goal:** demonstrate kernel R/W via **DS-K** (public DarkSword kexploit ports), then unlock PPL work on the build where KRW actually works.

| Field | Value |
|-------|--------|
| Track | **DS-K** (not DS-Full) |
| Daily driver | XR / **22H311** — not assumed PE-viable |
| Status | Integration scaffolding ready; **lab not run** |
| Fake backends | **Forbidden** |

Evidence: **literature** | **lab** | **unknown**.

## Literature vs lab

| Question | Literature | Lab |
|----------|------------|-----|
| PE CVEs fixed at 18.7.2? | Yes (Apple/NVD/GTIG) | Not yet tested on our XR |
| opa334 supports through 26.0.1? | README claim | Conflict — test on device |
| Offsets for 22H311? | README admits 15.x(?) | All TODO in header |

Hypotheses **H1/H2/H3**: [STATUS.md](STATUS.md).

## API (`src/krw`)

```c
int      krw_init(void);
int      kread(uint64_t kaddr, void *out, size_t len);
int      kwrite(uint64_t kaddr, const void *in, size_t len);
uint64_t kbase(void);
uint64_t kslide(void);
void     krw_deinit(void);
```

| File | Role |
|------|------|
| [`krw.h`](../src/krw/krw.h) / [`krw.c`](../src/krw/krw.c) | Dispatch + default none backend |
| [`krw_backend_darksword.c`](../src/krw/krw_backend_darksword.c) | Calls into **local** third_party tree when linked |
| [`offsets_n841_22H311.h`](../src/krw/offsets_n841_22H311.h) | All `/* TODO verify */` — no invented numbers |
| [`test_plan.md`](../src/krw/test_plan.md) | Read-known-stable before any write |

### Backend link rules

1. Clone upstream per [../third_party/README.md](../third_party/README.md) (gitignored; **no LICENSE** → do not commit sources).  
2. Build with `-DKRW_BACKEND_DARKSWORD=1` only when the local tree exists.  
3. Adapter must **call into** vendored code (or document binary-runner mode) — not a news-article reimplementation.  
4. Upstream today is monolithic `src/main.m` (`darksword-pe`). First lab may run that binary directly; library extraction is a follow-up once entry works.

## Offset policy

Offsets only from:

1. Public tables that explicitly list **this build**, or  
2. Derivation from our hashed kernelcache, or  
3. `/* TODO verify */` + symbol name  

Never invent. Wrong offsets → expect `FAIL_OFFSETS`, not silent “success.”

## Lab result taxonomy

Record in STATUS using exactly one:

| Code | Meaning |
|------|---------|
| `SUCCESS_KRW` | Stable `kread` of agreed value (see test plan) |
| `FAIL_PATCHED` | Exploit path behaves as patched / early hard-fail consistent with fix |
| `FAIL_OFFSETS` | Runs far enough that wrong constants are the best explanation |
| `FAIL_ENTRY` | Could not run with needed environment/entitlements |
| `FAIL_PANIC` | Panic/reboot during attempt |
| `UNKNOWN` | Ambiguous — needs more instrumentation |

Protocol: [LAB_DSK.md](LAB_DSK.md).

## After SUCCESS_KRW

1. Update STATUS hypothesis column.  
2. Open PPL work for **that build** ([PPL.md](PPL.md)).  
3. Only then flesh out [JB_SHAPE.md](JB_SHAPE.md) beyond design sketch.

If `FAIL_PATCHED` or `FAIL_OFFSETS` on 22H311 → follow [BUILD_vulnerable_target.md](BUILD_vulnerable_target.md) (**H3**).

## Related

- [DARKSWORD.md](DARKSWORD.md)
- [ENTRY.md](ENTRY.md)
- [STATUS.md](STATUS.md)
