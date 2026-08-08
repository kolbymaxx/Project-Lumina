# Step 4 — AppleAVE2UserClient reachability (what to do)

**Goal:** Answer one question with a citation:  
Can a **third-party app** on **iPadOS 26.5 / A12X** open **`AppleAVE2UserClient`**?  
→ **yes / no / unknown**

This is **not** writing an exploit. No invented IOKit selectors. No on-device crash loops yet.

## Already known (offline)

From `com.apple.driver.AppleAVE2` **905.36.1** (26.5 / 23F77):

- Classes: `AppleAVE2Driver`, `AppleAVE2UserClient`
- Bundle: `com.apple.driver.AppleAVE`
- Stats string: `com.apple.AppleVideoEncoder.ClientStats`

Diff evidence: [DIFF_NOTES_23F77_23G71.md](experiments/DIFF_NOTES_23F77_23G71.md)

## Do this (Mac + optional device) — pick in order

### 4a — IOKit personality / entitlements (Mac, IPSW or live)

1. From the **26.5** IPSW (or a mounted system), locate the AppleAVE2 kext Info / embedded personality (or dump via `ipsw` / `ioreg` on device).
2. Record: `IOClass`, `IOUserClientClass`, `IOMatchCategory`, any **`IOUserClientDefaultEntitlements`** / sandbox requirements.
3. **Success:** entitlement name written down (e.g. `com.apple.…`) or “no entitlement key in personality.”  
4. **Fail:** cannot find personality → try 4b.

### 4b — Who links / opens AVE (Mac, shared cache if you have one)

1. On a Mac with matching **dyld_shared_cache** for iPadOS 26.5 (from IPSW extract tools / blacktop `ipsw extract`), search for:
   - `AppleAVE2UserClient`
   - `AppleVideoEncoder`
   - `IOServiceOpen` callers near AVE
2. Typical suspects: **VideoToolbox**, `videodecoded`, `mediaplaybackd`, Camera/ReplayKit stacks — **cite the binary**.
3. **Success:** named Apple process + whether it is third-party-reachable (public VT API) or system-only.  
4. **Fail:** no DSC handy → 4c on-device.

### 4c — Live iPad (lab unit, low risk)

1. USB: `ideviceinfo` / confirm still **26.5** (tap About → version for **build** if still TBD).
2. If you have a shell (TrollStore / other — **not** Dopamine on 26.5): `ioreg -p IODeviceTree -w 0 | grep -i AVE` or `ioreg | grep -i AppleAVE`.
3. From a **normal App Store / sideloaded test app with no special entitlements**, try only **documented** VideoToolbox encode APIs (public headers). Do **not** craft raw externalMethod calls.
4. **Success signals:**
   - Public VT encode works and kernel logs / `ClientStats` show AVE activity → **likely yes** (indirect), still not a trigger.
   - Personality requires entitlement you cannot get → **no** for third-party.
5. **Fail-closed:** no evidence either way after 4a–4c → leave **unknown**; move to **P002**.

## How to record the answer

Add to [P001](experiments/P001_ave_cve_2026_64747_watch.md) or a one-pager `REACHABILITY_AVE.md`:

```text
Reachability: yes | no | unknown
Evidence: <file / ioreg / entitlement / VT API>
Third-party?: yes | no | unknown
Next: Step 5 fail-closed hyp  OR  demote P001 → P002
```

## What you should **not** do on Step 4

- Install Dopamine 3.0 expecting a 26.5 jailbreak  
- Bump ClearSword / momentarius plist `End` to 26.5  
- Invent `externalMethod` selector numbers from “UserClient”  
- Panic-loop the daily driver  

## After Step 4

| Result | Continuity next |
|--------|-----------------|
| **yes** (cited) | Step 5 — one fail-closed hyp with (1)(2)(3) on **lab** device |
| **no** (entitled-only) | Demote P001; **try P002** (kernel write CVE cluster) |
| **unknown** | Same as no for continuity — **P002**; keep AVE as watch |
