# Candidate filter — A12X / iPadOS 26.5

Hard rules before opening a theory card or spending lab time.
Used by [HUNT_LOOP.md](HUNT_LOOP.md).
Plan: [../../docs/RESEARCH_PLAN_26.5.md](../../docs/RESEARCH_PLAN_26.5.md).
Anti-patterns: [ANTI_PATTERNS.md](ANTI_PATTERNS.md).

**Status (locked until contradicted):** no matching public primitive for A12X / iPadOS 26.5.

**Lab rule:** no pwn / trigger session until a candidate **passes** this filter **and** a hypothesis includes evidence + concrete test + fail-closed.

## ACCEPT for a theory card — only if **all** hold

| # | Rule |
|---|------|
| 1 | **Kernel (or equivalent) entry** is claimed, **or** a clear PE→kernel / root staging path is stated honestly (label Path A vs Path B) |
| 2 | **SoC** is **A12X**, or the bug is clearly **not** SoC-locked away from A12X |
| 3 | **OS window** could still include **iPadOS 26.5 / 26.5.x** (not clearly fixed earlier than 26.5) |
| 4 | There is a **citable source** (Apple advisory CVE, writeup, commit, talk) |
| 5 | Hypothesis (if any) has **(1) evidence beyond advisory text alone**, **(2) concrete test**, **(3) fail-closed** — or the card is marked **docs-only watch** with Lab = No |

Evaluation stays under `research/ipados26.5/`. Nothing wired into `boot/`.

## REJECT immediately — if **any** hold

| # | Reject when… |
|---|--------------|
| 1 | Only targets **A15+ / SPTM-only** with **no A12X path** |
| 2 | Public **last-affected** is **before 26.5** |
| 3 | Pure WebKit / Safari with **no** escalation story to kernel/root |
| 4 | “Port **Dopamine / DarkSword / LARA / kfd**” with **no** 26.5 evidence |
| 5 | Treats advisory impact (“kernel privileges”) as a **working exploit** |
| 6 | Invents **IOKit selectors / triggers** from names alone |
| 7 | Claims **PPL solved** by any single 26.6 CVE |
| 8 | Recovers **`pattern_F_`** / private PPL from demos |
| 9 | Requires **unsigned restore** fiction to get onto 26.5 |
| 10 | Mixes **XR 18.7.5** results without labeling device/OS change |
| 11 | Blocks progress on **usbliter8 A12X** as if Path A needed Pico |
| 12 | Unverified blobs / YouTube-only “JB” claims |

Reject in **one line** on intake.

## Soft signals (not enough alone)

- Component name in the 26.6 advisory without a binary/diff signal
- “Root privileges” without path to KRW or a Path B-only label
- PPL / PAC essays without prior KRW
- XR T008–T012 watches (different device/OS)
- DFU identity / SecureROM RE (Path C only)

## After filter

1. **Pass** → copy [experiments/P000_template.md](experiments/P000_template.md) → `P00N_short_name.md`
2. **Reject** → one-line reason; no lab; no status-line change
3. Lab only if the card marks **Lab test? Yes** and hypothesis (1)(2)(3) are filled
4. Status line stays locked until citable **and** lab-relevant on **this** device/build
