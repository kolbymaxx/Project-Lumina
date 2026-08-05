# DarkSword dossier — DS-Full vs DS-K

**Main line for Lumina = DS-K.**  
**DS-Full = research reference only** (no deployable exploit pages in this repo).

Evidence labels: **literature** | **lab** | **unknown**.

## Critical technical split (always label)

| Track | What it is | Product shape |
|-------|------------|---------------|
| **DS-Full** | Leaked WebKit → sandbox → kernel chain (watering-hole kit) | Not our jailbreak UX; CVE/version map only |
| **DS-K** | Kernel PE / opa334-style `darksword-kexploit` and serious forks | What we **integrate** into a JB-shaped host |

Alias used elsewhere: **DS-PE** = **DS-K** (kernel PE only).

## CVE / patch map (public narrative)

Sources: [GTIG DarkSword](https://cloud.google.com/blog/topics/threat-intelligence/darksword-ios-exploit-chain), Apple security content, NVD.

| Stage | Module (GTIG) | CVE | Class (approx.) | Patched (iOS 18.x) | Matters for **DS-K**? | Matters for **DS-Full**? |
|-------|---------------|-----|-----------------|--------------------|----------------------|--------------------------|
| JSC RCE (≤18.5 path) | `rce_module.js` | CVE-2025-31277 | JavaScriptCore | **18.6** | No | Yes |
| JSC RCE (18.6–18.7) | `rce_worker_18.6/18.7.js` | CVE-2025-43529 | JavaScriptCore | **18.7.3** | No | Yes |
| Userspace PAC | `rce_worker_*.js` | CVE-2026-20700 | dyld PAC bypass | 26.3 (per GTIG) | Indirect (post-RCE) | Yes |
| Sandbox / ANGLE | `sbx0_main*.js` | CVE-2025-14174 | ANGLE | **18.7.3** | No | Yes |
| Kernel COW / privileged process | `sbx1_main.js` | CVE-2025-43510 | XNU memory mgmt | **18.7.2** | **Yes** (chain helper; Apple: malicious app) | Yes |
| Kernel VFS race → KRW | `pe_main.js` | CVE-2025-43520 | XNU VFS race | **18.7.2** | **Yes — core PE** | Yes |

### What DS-K actually needs

For a **kexploit-only** jailbreak-shaped host we care about:

1. **CVE-2025-43520** (and the public reimplementations of that PE logic) → arbitrary / phys+virt R/W  
2. Supporting primitives inside those ports (sockets, IOSurface, OOB oracles, etc.)  
3. Correct **offsets** for the target build + **entry** that can trigger the race  

CVE-2025-43510 appears in the full kit as a step toward a more privileged process; public **DS-K** ports may fold PE into a single app binary. Cite the specific tree’s code paths when integrating.

**DS-Full** WebKit/ANGLE/JSC stages are **out of product scope** here.

## Patch landmarks vs daily driver

| Landmark | Literature meaning | Implication for XR **18.7.5 / 22H311** |
|----------|--------------------|----------------------------------------|
| **18.7.2** | PE CVEs fixed | **literature:** PE dead — **lab still required** to confirm H1 vs H2 |
| **18.7.3** | DS-Full browser/sbx stages fixed | Irrelevant to DS-K product path |
| **18.7.7** | Broader protection messaging | Does not replace on-device DS-K result |

## Public repos to evaluate (**DS-K**)

| Repo | Role | LICENSE | Notes |
|------|------|---------|-------|
| [opa334/darksword-kexploit](https://github.com/opa334/darksword-kexploit) | **Primary** ObjC reimplementation | **None specified** (as of fetch) | README: “15.0–26.0.1”; “Offsets hardcoded for 15.x(?)”; single `src/main.m` + `entitlements.plist`; builds `darksword-pe` for arm64/arm64e |
| [htimesnine/DarkSword-RCE](https://github.com/htimesnine/DarkSword-RCE) | Upstream leak reference (opa334 attribution) | **None specified** | Teacher / provenance; not our default integrate target |
| ClearSword-class ports | Teacher writeups / C ports | Check per tree | Use only if public + LICENSE reviewed |

### README vs Apple — surface the tension

| Claim | Source | Conflict |
|-------|--------|----------|
| Supports through **26.0.1** | opa334 README | Apple/NVD: PE fixed **18.7.2** |
| Offsets for **15.x(?)** | opa334 README | Even if bug were live, **22H311** offsets are almost certainly wrong → expect `FAIL_OFFSETS` unless rebuilt |
| “Kernel PE on EOL devices” plea | opa334 README | Aspirational; not evidence on 22H311 |

**Resolution path:** on-device protocol in [LAB_DSK.md](LAB_DSK.md) — not README trust.

## Vendoring policy

See [../third_party/README.md](../third_party/README.md).

Because **no LICENSE** is published on the primary tree, we **do not** commit exploit sources into Lumina. Operator clones locally (gitignored). Adapter: `src/krw/krw_backend_darksword.c`.

## Exhaustion ladder

Detailed steps: [../research/kexploit/DARKSWORD_EXHAUST.md](../research/kexploit/DARKSWORD_EXHAUST.md).

| Step | Goal |
|------|------|
| Inventory + LICENSE note | third_party clone instructions |
| Version gates | README/code vs 18.7.2 |
| Offsets | TODO until derived — never invent |
| Entry | E1–E4 decision |
| On-device @ 22H311 | Result code into STATUS |
| If fail | [BUILD_vulnerable_target.md](BUILD_vulnerable_target.md) (H3) |

## Honesty rules

1. Never invent offsets.  
2. Never claim KRW without re-runnable command + observed bytes.  
3. Do not generate DS-Full weaponized pages or implant/exfil logic.  
4. Do not treat literature “patched” as a substitute for a logged lab taxonomy on our hardware.  
5. usbliter8 / Pico / iBEC are **out of scope** for this track.

## Related

- [STATUS.md](STATUS.md)
- [KRW.md](KRW.md)
- [ENTRY.md](ENTRY.md)
- [LAB_DSK.md](LAB_DSK.md)
- [../research/kexploit/viability/darksword_kexploit.md](../research/kexploit/viability/darksword_kexploit.md)
