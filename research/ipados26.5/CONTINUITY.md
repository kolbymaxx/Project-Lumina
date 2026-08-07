# Continuity rule — A12X / 26.5 track

Binding for agents and lab notes. Plan: [../../docs/RESEARCH_PLAN_26.5.md](../../docs/RESEARCH_PLAN_26.5.md).  
Live pointer: [NEXT.md](NEXT.md).

## After every completed step or failed experiment

1. Propose **one** next action on the **highest remaining ranked lead**
   (engineering Steps 1→5, then scoreboard P001→P00N).
2. Prefer **“try target N+1”** over refining or rewriting the plan.
3. **Do not** restart the full path matrix or rewrite docs unless **facts changed**
   (new build string, IPSW hash, FILTER result, hard blocker).
4. Only **pause** a lead when a hard blocker is explicit, e.g.:
   - needs public PPL
   - needs unsigned restore fiction
   - needs hardware / Pico we don’t have
   - needs binary artifact we cannot obtain
5. On pause → switch to the **backup** with a clear **success/fail** signal.
6. Never invent triggers to “unblock” a lead.

## Rank order (do not reshuffle without evidence)

1. Eng Step 1 — lock build + IPSW availability  
2. Eng Step 2 — extract kernel/AVE/IOKit  
3. Eng Step 3 — structured 26.5↔26.6 diff  
4. Eng Step 4 — reachability cites  
5. Eng Step 5 — one fail-closed experiment (only if Step 4 cites a client)  
6. Scoreboard P001 → P002 → P003 → … (docs watches; Lab only after binary evidence)

## Anti-continuity

- Re-deriving Path A/B/C from scratch each session  
- Opening ten half-audits instead of the top lead  
- Blocking Path A on usbliter8 t8027 (Path C) without a hard eng blocker on A/B
