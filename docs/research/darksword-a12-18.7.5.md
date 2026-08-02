# DarkSword / Dopamine applicability — iPhone XR (A12) · iOS 18.7.5 (22H311)

**Status: RESEARCH-ONLY. NOT an integration doc.**  
No DarkSword / `darksword-kexploit` / Dopamine code is present in, or added to,
this repo. Nothing here is wired into `boot/`, `research/kexploit/` exploit
trees, or any exploit/boot/kernel path.

Device under evaluation: **iPhone XR (iPhone11,8 / n841ap), A12 (arm64e),
iOS 18.7.5 (22H311)**. Current Lumina path: usbliter8 SecureROM pwn + ICH A12
ramdisk (tethered); on-disk `JBROOT` = `/mnt2/root/jb`.

Framed to match project applicability style in
[`docs/RESEARCH.md`](../RESEARCH.md) and
[`research/kexploit/PUBLIC_PRIMITIVE_MATRIX.md`](../../research/kexploit/PUBLIC_PRIMITIVE_MATRIX.md):
claim vs proof, teacher not installer, no invented ports.

## Verdict

> **NO-GO for iPhone XR (A12) on iOS 18.7.5 (22H311).**
>
> No public Dopamine or DarkSword matrix lists this chip + build. Dopamine 2.5
> beta’s DarkSword-backed window is **arm64 only through 18.7.1** — wrong ABI
> class for A12, and **two point releases below** our build. The kernel
> primitive DarkSword reuses (`CVE-2025-43520`) is patched on the 18.x branch
> at **18.7.2**, so **18.7.5 is already closed**. Separately, the Dopamine
> maintainer states DarkSword does **not** supply the **PPL bypass** required
> for arm64e (A12+) on iOS 18. Treat DarkSword/Dopamine as a **teacher, not
> an installer**, consistent with existing `research/kexploit/` policy.

---

## 0. Naming disambiguation

Public writing uses “DarkSword” for two related but different things:

1. **DarkSword (in-the-wild exploit chain)** — a multi-CVE Safari/WebKit →
   sandbox-escape → kernel r/w → payload kit disclosed by Google Threat
   Intelligence Group (GTIG) and Lookout (March 2026 reporting). Public
   reconstructions include [`htimesnine/DarkSword-RCE`](https://github.com/htimesnine/DarkSword-RCE)
   (captured ITW JS) and community RE (e.g.
   [`AntonioCiolino/DarkSword-Analysis`](https://github.com/AntonioCiolino/DarkSword-Analysis),
   [TheRealClarity ClearSword writeup](https://therealclarity.github.io/blog/clearsword/)).
2. **`opa334/darksword-kexploit`** — a narrower Objective-C reimplementation of
   the **kernel read/write stage** of (1), for use from an already-running
   native context. Folded into **Dopamine 2.5 beta** as an optional kernel
   exploit backend (alongside older `kfd`-class paths), extending Dopamine past
   its classic 15/16 ceiling — but only for the ABI class the release notes
   name.

Neither is present in this repo, and neither will be added by this memo.

---

## 1. Does any public matrix list A12 / iPhone11,8 / iOS 18.7.5 for DarkSword or Dopamine?

**No.** Checked public READMEs, Dopamine release notes, and maintainer
statements (2026-08-02). Nothing lists **A12 / iPhone11,8 / arm64e** together
with **iOS 18.7.5**.

| Source | What it lists | vs our device |
|--------|---------------|---------------|
| [`opa334/Dopamine` README](https://github.com/opa334/Dopamine) | Stable: iOS **15.0–16.5.1 (arm64e)** and 15.0–15.8.6 / 16.0–16.6.1 (arm64) | A12 is arm64e → stable ceiling **16.5.1**, far below 18.7.5 |
| [Dopamine **2.5b3**](https://github.com/opa334/Dopamine/releases/tag/2.5b3) | “Add support for iOS 16.7.16, **17.0 – 18.7.1 (arm64)**” | **arm64 only** (A8–A11 class), not arm64e/A12; ceiling **18.7.1**, not 18.7.5 |
| [Dopamine **2.5b4**](https://github.com/opa334/Dopamine/releases/tag/2.5b4) | Fixes 17.1–17.3.1; same DarkSword known-issues list | Still no arm64e / A12 / 18.7.5 |
| opa334, Infosec Exchange ([2.5b3 thread](https://infosec.exchange/@opa334/116568920937079212)) | Asked about arm64e / A12+ / XR-class PPL: *“What DarkSword doesn't contain is the PPL bypass… Coruna… doesn't go up to iOS 18. So basically the latest arm64e news will be for iOS 17 only until then.”* | Maintainer **excludes** near-term arm64e iOS 18 path |
| [`opa334/darksword-kexploit` README](https://github.com/opa334/darksword-kexploit) | “Supposed to support iOS 15.0 – 26.0.1”; “Offsets hardcoded for 15.x(?)” | Broad **claim**, not a device matrix; no XR / 22H311 listing |
| Community forks (e.g. [`W1xced-io/darksword-kexploit`](https://github.com/W1xced-io/darksword-kexploit)) | Call out **A18 / pe_v2** work | Evidence per-generation work is required; **A12 not** called out as supported for 18.7.5 |
| Project prior art | [`PUBLIC_PRIMITIVE_MATRIX.md`](../../research/kexploit/PUBLIC_PRIMITIVE_MATRIX.md), [`SOURCES.md`](../../research/kexploit/SOURCES.md), [`docs/RESEARCH.md`](../RESEARCH.md) | LARA/DarkSword tooling public text through **18.7.1**; **18.7.5 outside** |

Secondary corroboration: [24rows.com summary of 2.5b3](https://24rows.com/dopamine-2-5-beta-3-adds-ios-17-and-18-support-same-day-ios-16-7-16-compatibility/)
restates the arm64-only 17.0–18.7.1 scope.

**Answer:** no public matrix entry for A12 / iPhone11,8 / iOS 18.7.5.

---

## 2. What does the kexploit provide (kernel r/w) vs full JB?

`opa334/darksword-kexploit` (and the ITW DarkSword kernel stage it reimplements)
provides **one class of primitive: arbitrary kernel memory read/write**. It is
**not** a full jailbreak.

From GTIG’s chain description and community RE
([ClearSword writeup](https://therealclarity.github.io/blog/clearsword/),
[`AntonioCiolino/DarkSword-Analysis`](https://github.com/AntonioCiolino/DarkSword-Analysis)):

- Kernel stage centers on **`CVE-2025-43520`** — XNU VFS race
  (`cluster_write_contig` / related path) used to build physical/virtual
  memory r/w (often described via ICMPv6 / `ICMP6_FILTER` socket option
  patterns for bounded r/w).
- That yields **kernel r/w** — inspect/corrupt kernel data structures — the
  same *class* of foothold historical Dopamine `kfd` / physpuppet-era
  exploits aimed at (already marked “idea only / out of window” for 18.7.5
  in the project matrix).
- It does **not**, by itself, provide: reliable arbitrary kernel function
  call (`kcall`), PAC defeat for native unsigned code paths, **PPL bypass**
  (required on A12 for trustcache/codesigning-adjacent writes), AMFI policy
  changes, rootless bootstrap, package-manager integration, or reboot
  persistence.

GTIG notes the ITW chain could avoid needing a PPL/SPTM bypass for its
*infostealer* use case by staying in JavaScript/JIT (no native unsigned
tweak execution). Dopamine’s use case is the opposite: run **arbitrary
native** binaries/tweaks, which is exactly where **PPL on A12** becomes
unavoidable — and per opa334, DarkSword does not ship that piece for
arm64e.

**Full JB (Dopamine-style semi-untether)** ≈ kernel r/w **+** kcall **+**
AMFI/trustcache work **+** PPL bypass (A12) **+** rootless bootstrap **+**
launchd/respring integration (see §4).

---

## 3. Why 18.7.5 may already be patched for original kit bugs

**It is, for the chain links that matter to a kexploit port.** GTIG’s CVE
table (cross-checked against NVD for the kernel PE) shows DarkSword’s
18.x-branch fixes land **at or before 18.7.3**; our build is **18.7.5**.

| CVE | Role in ITW chain | Patched in (public) |
|-----|-------------------|---------------------|
| CVE-2025-31277 | JSC RCE (pre-18.6 devices) | iOS **18.6** |
| CVE-2025-43529 | JSC DFG JIT GC RCE (18.6–18.7 devices) | iOS **18.7.3** / 26.2 |
| CVE-2025-14174 | ANGLE memory corruption (sandbox escape) | iOS **18.7.3** / 26.2 |
| CVE-2025-43510 | Kernel memory-management / CoW stage | iOS **18.7.2** / 26.1 |
| CVE-2025-43520 | Kernel VFS race → **kernel r/w** (`pe_main` / kexploit core) | iOS **18.7.2** / 26.1 |
| CVE-2026-20700 | Userspace `dyld` PAC bypass (ITW native-exec link) | iOS **26.3** (no 18.x-branch fix found in sources checked) |

Primary source: [Google Cloud Blog — “The Proliferation of DarkSword”](https://cloud.google.com/blog/topics/threat-intelligence/darksword-ios-exploit-chain)
(exploit-module / CVE table). Kernel PE confirmation:
[NVD CVE-2025-43520](https://nvd.nist.gov/vuln/detail/CVE-2025-43520)
(“fixed in iOS 18.7.2 and iPadOS 18.7.2 …”). Lookout’s kit writeups agree on
the kill-chain framing:
[DarkSword Exploit Kit](https://security.lookout.com/threat-intelligence/article/darksword-exploit-kit).

**Implication for 22H311:** every CVE with a confirmed **18.x** patch date in
that table is closed on 18.7.5, including **both kernel-side bugs** and the
JS/sandbox stages. The README claim “supposed to support … 26.0.1” is a
**claim**, not proof against Apple’s patch dates — exactly the project’s
claim-vs-proof rule in
[`PUBLIC_PRIMITIVE_MATRIX.md`](../../research/kexploit/PUBLIC_PRIMITIVE_MATRIX.md).

**Caveat (honest, not a loophole):** CVE-2026-20700 (`dyld` PAC) is only
listed as fixed at **26.3** in GTIG’s table; no 18.x-branch fix was found in
sources checked. That does **not** revive the kit on 18.7.5: the kernel r/w
link (`CVE-2025-43520`) is already closed, and a userspace PAC bypass is not
a substitute for the **PPL** gap opa334 cites for arm64e/iOS 18.

**Unrelated 18.7.5 fix (do not confuse with DarkSword):** Apple’s
[iOS 18.7.5 security content](https://support.apple.com/en-afri/126347)
lists **CVE-2026-20621** under **Wi-Fi** (“unexpected system termination or
corrupt kernel memory”), available for iPhone XR among others. Different
CVE from the DarkSword set; noted only to avoid conflation in future notes.

Even Dopamine’s **arm64** DarkSword beta window ends at **18.7.1** — so
18.7.5 is outside the published *installer* matrix twice: wrong ABI for A12,
and past the version ceiling for the arm64 beta.

---

## 4. What would still be needed after kexploit for semi-untethered (AMFI, bootstrap, launchd)

Even hypothetically assuming a still-live kernel r/w on A12/18.7.5 (which
public patch dates contradict for DarkSword’s `CVE-2025-43520`), r/w alone
is not a Dopamine-style semi-untether. Drawing on Dopamine’s public
architecture, opa334’s arm64e comments, and
[`research/mitigations/README.md`](../../research/mitigations/README.md):

1. **`kcall` (arbitrary kernel function call)** — r/w can corrupt structures;
   Dopamine historically builds callable kernel execution on top of r/w, then
   uses that for policy/bootstrap work.
2. **PPL bypass (A12-specific hard gate)** — A12 is PPL-era, not SPTM/TXM
   (project mitigations table). Trustcache / codesigning-adjacent kernel
   writes need a PPL strategy. opa334: DarkSword lacks this for arm64e;
   Coruna-derived PPL “doesn’t go up to iOS 18.” No public working A12 / 18.x
   PPL bypass was found for this memo.
3. **AMFI / codesigning + trustcaching** — so unsigned dylibs/binaries
   (tweaks, package manager, injection) can run under live SpringBoard AMFI
   (ramdisk root SSH is a different environment — see mitigations notes).
4. **Rootless bootstrap** — filesystem overlay + Procursus-class packages +
   tweak injection (Dopamine uses ElleKit) + package manager. Lumina’s disk
   constant is `/mnt2/root/jb` for tethered staging; a semi-untether would
   still need a live-OS bootstrap story beyond ramdisk mounts.
5. **launchd integration / persistence model** — Dopamine’s modern path
   leans on **launchd** hooks / XPC jailbreak state rather than a forever
   separate `jailbreakd`. That is what makes it *semi*-untethered: userspace
   re-applies after reboot without a fresh BootROM pwn (unlike our current
   fully tethered usbliter8 + ramdisk sessions).
6. **Respring / SpringBoard reinjection** — bring dyld/library-injection
   state up cleanly for apps and SpringBoard.
7. **Sandbox loosening** for jailbreak helper / tweak processes.

None of steps 1–7 exist publicly as a drop-in for **A12 + 18.7.5**. Step 2
is a **named** gap from the Dopamine maintainer, not a vague “needs more
research.”

---

## Sources

- Google Cloud Blog (GTIG) — [The Proliferation of DarkSword](https://cloud.google.com/blog/topics/threat-intelligence/darksword-ios-exploit-chain) — CVE table, patch versions, chain roles (§1–§3)
- Lookout — [DarkSword Exploit Kit](https://security.lookout.com/threat-intelligence/article/darksword-exploit-kit) — kill-chain / kit framing
- [`htimesnine/DarkSword-RCE`](https://github.com/htimesnine/DarkSword-RCE) — captured ITW JS; cited by opa334 as leak origin
- [`AntonioCiolino/DarkSword-Analysis`](https://github.com/AntonioCiolino/DarkSword-Analysis) — community RE
- [TheRealClarity — Into the Dark / ClearSword](https://therealclarity.github.io/blog/clearsword/) — CVE-2025-43520 VFS race / kernel r/w mechanism detail
- [`opa334/darksword-kexploit`](https://github.com/opa334/darksword-kexploit) (+ [README](https://raw.githubusercontent.com/opa334/darksword-kexploit/main/README.md)) — ObjC kernel-primitive reimplementation; version claim vs 15.x offsets caveat
- [`W1xced-io/darksword-kexploit`](https://github.com/W1xced-io/darksword-kexploit) — fork notes (A18 / pe_v2); per-SoC work evidence
- [`opa334/Dopamine`](https://github.com/opa334/Dopamine) ([README](https://raw.githubusercontent.com/opa334/Dopamine/master/README.md)) — stable support matrix (arm64e ≤ 16.5.1)
- Dopamine releases — [2.5b3](https://github.com/opa334/Dopamine/releases/tag/2.5b3), [2.5b4](https://github.com/opa334/Dopamine/releases/tag/2.5b4) — explicit “(arm64)” 17.0–18.7.1 window
- opa334, Infosec Exchange — [2.5b3 announcement thread](https://infosec.exchange/@opa334/116568920937079212) — arm64e / PPL / iOS 18 maintainer statement
- 24rows.com — [Dopamine 2.5 Beta 3 summary](https://24rows.com/dopamine-2-5-beta-3-adds-ios-17-and-18-support-same-day-ios-16-7-16-compatibility/) — secondary corroboration of arm64-only scope
- Apple — [About the security content of iOS 18.7.5](https://support.apple.com/en-afri/126347) — XR in device list; CVE-2026-20621 (Wi-Fi) unrelated to DarkSword set
- NVD — [CVE-2025-43520](https://nvd.nist.gov/vuln/detail/CVE-2025-43520) — fixed in iOS 18.7.2
- Project framing — [`docs/RESEARCH.md`](../RESEARCH.md), [`research/kexploit/PUBLIC_PRIMITIVE_MATRIX.md`](../../research/kexploit/PUBLIC_PRIMITIVE_MATRIX.md), [`research/kexploit/SOURCES.md`](../../research/kexploit/SOURCES.md), [`research/kexploit/RE_PRIORITY.md`](../../research/kexploit/RE_PRIORITY.md), [`research/mitigations/README.md`](../../research/mitigations/README.md), [`docs/STATUS.md`](../STATUS.md)

## Explicit non-claims (project policy)

- This memo does **not** claim a working kexploit, PPL bypass, or jailbreak
  for A12 / iOS 18.7.5.
- No DarkSword, `darksword-kexploit`, or Dopamine **code** was added to this
  repo. This file is the **only** deliverable for this research task.
- No offsets, no device-specific derivation, no port attempt.
- Not wired into `boot/`, `research/kexploit/` exploit clones, or any
  exploit/boot/kernel path.
- If future public evidence changes an answer (e.g. an arm64e PPL bypass
  ships with a cited matrix), add a dated addendum with new sources — do not
  silently rewrite the verdict.

## Related

- [`docs/RESEARCH.md`](../RESEARCH.md)
- [`research/kexploit/README.md`](../../research/kexploit/README.md)
- [`research/kexploit/PUBLIC_PRIMITIVE_MATRIX.md`](../../research/kexploit/PUBLIC_PRIMITIVE_MATRIX.md)
- [`research/kexploit/SOURCES.md`](../../research/kexploit/SOURCES.md)
- [`research/mitigations/README.md`](../../research/mitigations/README.md)
- [`docs/STATUS.md`](../STATUS.md)
