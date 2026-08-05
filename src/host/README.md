# `src/host` — minimal DS-K test host

**Purpose:** ship a tiny, signed app (or app-wrapped binary) that runs **DS-K**
and prints structured logs for [LAB_DSK.md](../../docs/LAB_DSK.md).

**Status:** scaffold only — no Xcode project checked in yet.  
**Waiting on:** entry choice **E1/E2/E3/E4** in STATUS.

## Plan (after entry decision)

1. Create an iOS app target (arm64e) on the operator Mac.  
2. Embed or exec locally built `third_party/darksword-kexploit` → `darksword-pe`.  
3. Sign with the chosen path (E1/E2). Expect private entitlements from upstream
   plist to be **missing** on stock 18.7.5 — log actual entitlements.  
4. UI: one button “Run DS-K” + scrollable log (or stdout to Console).  
5. Map outcomes to LAB result codes — never show fake “jailbroken” UI.

## Non-goals

- Sileo / package manager  
- DS-Full WebKit pages  
- Invented KRW success screens  

## Related

- [../../docs/ENTRY.md](../../docs/ENTRY.md)
- [../../third_party/README.md](../../third_party/README.md)
- [../krw/](../krw/)
