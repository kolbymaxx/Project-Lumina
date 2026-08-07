# Hunt loop — A12X / iPadOS 26.5

Process for evaluating **candidate primitives** for the 26.5 A12X track.
Documentation / research only. **Not wired into `boot/`.**

**Status (locked):** no matching public primitive for A12X / iPadOS 26.5.

Plan: [../../docs/RESEARCH_PLAN_26.5.md](../../docs/RESEARCH_PLAN_26.5.md).  
Filter: [FILTER.md](FILTER.md).  
Continuity: [CONTINUITY.md](CONTINUITY.md) · live action: [NEXT.md](NEXT.md).

After each card Result or eng step: update **NEXT.md** to the highest remaining lead — do not restart the path matrix.

## Process

```text
INTAKE → FILTER → CARD → LAB → MATRIX
   ↑                              │
   └────── next candidate ←───────┘
```

### 1. INTAKE
Primary surface: Apple **iOS/iPadOS 26.6** security content + follow-on writeups.
Capture name + link. No lab yet. See [experiments/INTAKE_26.6.md](experiments/INTAKE_26.6.md).

### 2. FILTER
Apply [FILTER.md](FILTER.md). Fail → **reject in one line**; stop.

### 3. CARD
Copy [experiments/P000_template.md](experiments/P000_template.md) → `experiments/P00N_*.md`.
Fill Claim / Source / Filter. Lab = No until hypothesis (1)(2)(3) exist.

### 4. LAB
Only if **Lab test? Yes**. Prefer offline RE; on-device only on a **non–daily-driver** 26.5 unit.
Never invent offsets/selectors; never wire into `boot/`.
usbliter8 **not** required.

### 5. MATRIX
Update [PUBLIC_PRIMITIVE_MATRIX.md](PUBLIC_PRIMITIVE_MATRIX.md).
Status line unchanged until citable + lab-relevant.

## Card series

| Series | Track |
|--------|-------|
| **P00N** | This tree — A12X / 26.5 |
| **T00N** | XR / 18.7.5 under `research/kexploit/` — **do not reuse IDs** |

## Closed vs open

Open watches start from INTAKE_26.6 Tier 1–2 cards (P001+).  
Do not reopen XR closed cards (T001–T004, T013) as if they applied here without a new FILTER pass labeled for A12X/26.5.
