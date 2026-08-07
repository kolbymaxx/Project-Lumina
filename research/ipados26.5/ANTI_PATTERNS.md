# Anti-patterns — A12X / iPadOS 26.5

Hard rejects for Path A/B on this track.  
Plan: [../../docs/RESEARCH_PLAN_26.5.md](../../docs/RESEARCH_PLAN_26.5.md).

If a note or PR violates any row, **reject in one line**.

| # | Do **not**… | Why |
|---|-------------|-----|
| 1 | Treat “kernel privileges” / “write kernel memory” in an advisory as a working exploit | Impact text ranks research; it is not a PoC |
| 2 | Invent IOKit selectors / trigger paths from component names alone | Names ≠ sinks |
| 3 | Claim PPL is solved by any single 26.6 CVE | A12X PPL is a separate post-KRW problem |
| 4 | Mix XR/usbliter8 18.7.5 results into this track without labeling device/OS change | Different SoC image + OS train |
| 5 | Recommend unsigned restores as if signing were open | Prefer device already on 26.5 or offline binaries |
| 6 | Recover `pattern_F_` / private PPL from demos | Out of scope; abstracts do not encode the bug |
| 7 | Block Path A on Pico / usbliter8 A12X | Path C is deferred; A/B are userspace/offline |
| 8 | Promote a hypothesis to “the path” without success/fail signal | Theory ≠ plan |
| 9 | Equate MediaRemote root or Path B panic with Path A KRW+PPL | Different privilege domains |
| 10 | Wire `research/ipados26.5/` into `boot/` | Protect XR known-good boot path |
| 11 | Use daily-driver iPad for crash loops without acknowledging unpatched 26.5 risk | Operational safety |
| 12 | Claim Cursor/AI will find the 0day from repo structure | Skill gate is senior iOS RE + evidence |
