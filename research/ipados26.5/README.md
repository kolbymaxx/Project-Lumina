# iPadOS 26.5 / A12X — delta hunt (docs only)

**Device:** iPad Pro 12.9" 3rd gen (A12X / t8027 / CPID `8027`)  
**Target OS:** iPadOS **26.5 / 26.5.x** (pre–**26.6** patch surface)  
**Delta source:** Apple security content for **iOS/iPadOS 26.6** (2026-07-27)

**Status line:** no matching public primitive for **A12X / iPadOS 26.5**.

Canonical plan: [`../../docs/RESEARCH_PLAN_26.5.md`](../../docs/RESEARCH_PLAN_26.5.md).

Nothing here is wired into `boot/`. This tree is **separate** from XR 18.7.5 [`../kexploit/`](../kexploit/) (T00N cards). Use **P00N** cards here.

## Scope

- Path A: original KRW→PPL-oriented discovery from 26.6 delta (stay on 26.5)
- Path B: reproducible lab signals (crash / corruption / temp root) without full-JB claims
- Path C: deferred usbliter8/A12X — see [`../usbliter8-t8027/`](../usbliter8-t8027/); **do not block** A/B on Pico

## Non-claims

- Not a jailbreak; not Sileo/bootstrap
- Advisory impact ≠ PoC / trigger / chain
- MediaRemote “root” ≠ KRW ≠ PPL
- usbliter8 does **not** pwn t8027 in this repo today
- Do not reuse XR `n841ap` ramdisk / UDID / DeviceTree

## Layout

| File | Role |
|------|------|
| [NEXT.md](NEXT.md) | **Single next action** (update after each step/fail) |
| [STEP4_REACHABILITY.md](STEP4_REACHABILITY.md) | Concrete checklist for AppleAVE2UserClient reachability |
| [CONTINUITY.md](CONTINUITY.md) | Prefer try N+1; no plan rewrites unless facts change |
| [FILTER.md](FILTER.md) | Hard ACCEPT / REJECT before cards or lab |
| [HUNT_LOOP.md](HUNT_LOOP.md) | INTAKE → FILTER → CARD → LAB → MATRIX |
| [PUBLIC_PRIMITIVE_MATRIX.md](PUBLIC_PRIMITIVE_MATRIX.md) | Status + tool/CVE rows |
| [ANTI_PATTERNS.md](ANTI_PATTERNS.md) | Binding rejects |
| [HYPOTHESIS_TEMPLATE.md](HYPOTHESIS_TEMPLATE.md) | Evidence / test / fail-closed |
| [WRITEUP_WATCHLIST.md](WRITEUP_WATCHLIST.md) | Public artifacts that change status |
| [SOURCES.md](SOURCES.md) | Advisories / NVD / writeups |
| [experiments/](experiments/) | INTAKE + P00N cards |

## Daily-driver risk

Staying on 26.5 means running **without** 26.6 fixes. Prefer a dedicated lab unit for on-device tests.
