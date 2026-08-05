# Attracting real JB developers

What a serious reviewer should see in this repo — and what we will **not** spam.

## What we are

A **research monorepo** for iPhone XR (A12 / `n841`) on **iOS 18.7.5 (22H311)** with:

1. Proven **BootROM → ramdisk** track (usbliter8) — separate from SpringBoard KRW  
2. Honest **KRW + PPL** research track with dead-candidate documentation  
3. Thin, auditable harness stubs — no “AI complete jailbreak”

We are **not** shipping Sileo, not claiming first public JB, and not packaging spyware chains.

## Repro steps (what works today)

### A) Host tooling smoke (any Mac/Linux clone)

```bash
python3 usbliter8ctl -h
python3 usbliter8ctl info   # expect: no DFU/Recovery device on cloud VM
python3 tools/decode_t8020_handler.py
```

### B) Live XR ramdisk (Mac + Pico + phone only)

1. Pico-pwn the XR (usbliter8).  
2. Connect phone **directly** to the Mac (not through Pico).  
3. Ensure `boot/config.env` from `boot/config.env.example` + ramdisk payloads.  
4. `./boot/lumina-boot.sh` then `./boot/lumina-ssh.sh`.  
5. Confirm SystemVersion **18.7.5 / 22H311** under `/mnt1`.

Details: [../boot/README.md](../boot/README.md), [STATUS.md](STATUS.md).

### C) Offline kernelcache (operator Mac)

Paths and probes: [BUILD_22H311.md](BUILD_22H311.md),  
[../research/kexploit/22H311_NOTES.md](../research/kexploit/22H311_NOTES.md).  
**Do not** commit IPSW/kernelcache blobs.

### D) KRW harness (not yet lab-proven)

```text
src/krw/   — API stubs only; backend = none until a live primitive is integrated
```

See [KRW.md](KRW.md), [../src/krw/test_plan.md](../src/krw/test_plan.md).

## Panic / failure log format

When a device session fails or panics, paste using this template (STATUS or
`research/kexploit/notes/` locally):

```text
### Session YYYY-MM-DD
- Device: iPhone XR n841 / 22H311
- Track: krw | ppl | bootrom | other
- Build confirmed: yes/no (paste SystemVersion)
- Action attempted: …
- Expected: …
- Observed: …
- Panic string (if any): …
- Panic full text / photo: …
- Aftermath: reboot ok? still 22H311?
- Claim level: none | literature | partial | demonstrated
- Will NOT claim: …
```

## Success looks like (per milestone)

| Milestone | Success signal |
|-----------|----------------|
| **M0** Truth doc | STATUS lists target, hypothesis, evidence level, blockers |
| **M1** Entry | ENTRY states TrollStore blocked; operator picks sideload vs docs-only |
| **M2** Harness | `krw.h` API + stub + offset policy + read-first test plan in tree |
| **M3** Kernelcache | BUILD hashes filled; offsets header only TODO or derived |
| **M4** PPL | PPL.md concludes blocked or cites mechanism + observational plan |
| **M5** Attract | This file + clear ask (below) |
| **KRW demonstrated** | Re-runnable `kread` of known kernel value on device — STATUS upgrade |
| **PPL progress** | Cited mechanism + RO probes; never “essay = bypass” |

## Clear ask — where help matters

**We need help with PPL strategy on A12 / 22H311 *after* (or in parallel to) finding a live KRW primitive.**

Specifically valuable:

- Citable writeups for advisory-window kernel bugs still relevant on **18.7.5**  
- Confirmation that a candidate is triggerable from **developer-signed** sandbox (no TrollStore)  
- PPL observational checklists against **22H311** kernelcache (A12, not SPTM cargo-cult)  
- Audit of our offset policy / harness for foot-guns  

Less useful: “port Dopamine,” YouTube JB claims, or WebKit implant packaging.

## What we will not spam

- “First public jailbreak on 18.7.5” marketing before **demonstrated** KRW  
- Fake offsets / gadgets  
- Sileo screenshots as progress  
- Wiring research exploits into `boot/`  
- Claiming PPL bypass without mechanism + test plan  

## Reviewer checklist

- [ ] STATUS evidence levels honest (`literature` vs `demonstrated`)  
- [ ] DarkSword PE marked patched on 18.7.2 / dead on 22H311  
- [ ] Entry gate (no TrollStore) visible  
- [ ] `src/krw` has no invented immediates  
- [ ] PPL section can conclude **blocked**  
- [ ] BootROM track not confused with SpringBoard KRW  

## Related

- [STATUS.md](STATUS.md)
- [KRW.md](KRW.md)
- [PPL.md](PPL.md)
- [ENTRY.md](ENTRY.md)
- [../research/kexploit/PUBLIC_PRIMITIVE_MATRIX.md](../research/kexploit/PUBLIC_PRIMITIVE_MATRIX.md)
