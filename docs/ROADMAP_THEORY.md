# Lumina theory roadmap — A12 XR / iOS 18.7.5 (22H311)

Research plan only. **Not a claim of a working jailbreak or kexploit.**
Nothing here is wired into `boot/`. Speculation is marked as such.

## Current proven foothold (Phase A inventory locked — 2026-08-01)

| Capability | Status |
|------------|--------|
| usbliter8 BootROM (A12) | Works |
| Tethered ramdisk + root SSH | Works (15.1 restore env `19B5042h`) |
| System `disk0s1s1` → `/mnt1` | Works — RO sealed **18.7.5 / 22H311** |
| Update `disk0s1s5` → `/mnt4` | Works — ota-result → **22H311** |
| Cryptex `disk0s1s6` → `/mnt6` | Works — active cryptex1/current (**18.7.5 / 22H311**, RestoreVersion **22.8.311.0.0**) |
| Preboot / bbfs / FactoryData | Works RO (`s3` / `s4` / `s7`) |
| Data `disk0s1s2` / `disk0s1s8` | **Blocked** — `mount_apfs -o rdonly` exit **76** (`Program version wrong`) |
| Kernel / userspace on the *running* OS | **Not reached** |

Claim scope: tethered SSH + those RO mounts. **No** Data R/W, kexploit, or Sileo.
We cannot yet alter the live SpringBoard session or claim persistence.
Inventory: [STATUS.md](STATUS.md), [../artifacts/xr-18.7.5/phase-a-2026-08-01.md](../artifacts/xr-18.7.5/phase-a-2026-08-01.md).

---

## Stage A — Foothold hardening (Data mount + tooling)

### Goal
Reliable read (and later controlled write) of Data and richer offline dumps
from the tethered session, without regressing BootROM → ramdisk SSH.

### What we already have
- usbliter8 → iBSS → ramdisk → SSH
- System `disk0s1s1` → `/mnt1`
- Preboot-ish `disk0s1s5` → `/mnt4`
- Host IPSW name: `iPhone11,8_18.7.5_22H311_Restore`

### What’s missing
- `mount_apfs` (or equivalent) that understands iOS 18 Data
- Confirmed kernelcache path (not found under `/mnt1` Caches/Kernels this session)
- Optional: newer restore ramdisk matching 18.x tooling

### Candidate approaches (theory)
1. **Newer restore ramdisk `mount_apfs`** — staged candidates:
   - **16.0 n841** (still HFS restore DMG in SSHRD practice; newer APFS userspace)
   - **18.x APFS restore** (closest tooling to 22H311; Mac `hdiutil` packaging)
2. **SSHRD-style SEP staging** (process reference only) — after tools clear
   exit 76: Preboot + xART → `seputil --gigalocker-init` → `seputil --load`
   → Data. Full write-up: [../research/DATA_MOUNT_SSHRD.md](../research/DATA_MOUNT_SSHRD.md).
3. **Host-side IPSW extract** for kernelcache / trustcaches while Data stays blocked.
4. **Deeper on-device search** under `/mnt1` and mounted non-Data volumes.

### How we’d reverse-engineer / validate
- Diff 15.1 vs 16.0 vs 18.x restore ramdisk binaries (`mount_apfs`, `fsck_apfs`, `apfs.util`)
- Mount System always; retry Data **before** seputil; log exact errno/strings
- Only if errno leaves “Program version wrong”, run SEP staging and compare
- Host: `ipsw extract --kernel` (or equivalent) from 22H311 IPSW; hash artifacts into `artifacts/xr-18.7.5/` (gitignored dumps)

### Dependencies / risks
- Newer ramdisk may need different iBSS/iBoot patches — do not break the known-good boot
- ≥16 restore sessions may renumber NAND to `disk1s*` — re-probe, don’t hardcode
- Data may also be SEP/file-protection constrained even after mount
- Public SSHRD iOS 17+ Data mounts are frequently broken — not a ready recipe
- Keep all experiments off the production `boot/` path until proven

### Exit criteria — done when…
- [x] Documented SSHRD / restore-ramdisk staging research ([DATA_MOUNT_SSHRD.md](../research/DATA_MOUNT_SSHRD.md))
- [ ] Documented recipe mounts Data **or** proves a hard SEP/crypto blocker with evidence
- [ ] Kernelcache for 22H311 obtained (device path and/or host IPSW) with hash noted in STATUS

---

## Stage B — Offline firmware RE (IPSW 22H311)

### Goal
Build a local RE corpus: kernelcache, trustcaches, relevant iBoot/iBSS,
strategy for dyld_shared_cache — so later kexploit/bootstrap work has symbols
and version gates.

### What we already have
- Device/board: n841ap / A12 / build **22H311**
- Readable System tree at `/mnt1` for userspace binaries (when tethered)

### What’s missing
- Indexed kernelcache + KEXT list for this build
- Trustcache / cryptex layout notes
- Shared-cache extraction plan (size, tools, arm64e)

### Candidate approaches (theory)
1. Host extract from IPSW; IDA/Ghidra/Binary Ninja + public iOS loaders
2. String/symbol surveys; compare to public patchfinder target lists (Dopamine-era patterns as *names only*)
3. Map AMFI / sandbox / codesigning related kexts before any exploit study

### How we’d reverse-engineer / validate
- Confirm CPID/board match in BuildManifest
- Record kernel UUID / Darwin version from extracted cache
- Note which APIs appear in this build vs older public write-ups (*speculation* until verified)

### Dependencies / risks
- arm64e / PAC complicates naive RE
- Large artifacts stay gitignored
- RE ≠ exploit capability

### Exit criteria — done when…
- [ ] `artifacts/` (local) has hashed kernelcache + short `notes.md` of UUID/paths
- [ ] RESEARCH notes list primary kexts of interest for 22H311

---

## Stage C — Kernel execution path theories

### Goal
Decide *whether* any public kernel-exploit family is even a candidate for
A12 + 22H311, and what would be required to prove it — without wiring code
into boot.

### What we already have
- BootROM arbitrary entry (usbliter8) — helpful for loading stages, **not** live kernel r/w
- RE priority framing: [../research/kexploit/RE_PRIORITY.md](../research/kexploit/RE_PRIORITY.md)
  (**teachers, not installers**)
- Primitive matrix skeleton:
  [../research/kexploit/PUBLIC_PRIMITIVE_MATRIX.md](../research/kexploit/PUBLIC_PRIMITIVE_MATRIX.md)
- Study indexes: palera1n (boot), Dopamine/kfd (kernel ideas), Coruna/Relaxin,
  DarkSword/LARA (*references only*)
- Explicit status: **no matching public primitive for A12 / 18.7.5**

### What’s missing
- Proven kernel read/write on **this** build
- Cited rows in the public primitive matrix (sources + last-known iOS)
- Version/offset matrix for 22H311 (only after a live primitive exists)
- Clear statement of entrypoint (app, WebKit, installed helper, etc.) vs tethered-only

### Candidate approaches (theory)
1. **palera1n boot-only compare** to usbliter8 → SSH (structure, not exploit)
2. **Dopamine / kfd / physpuppet-class writeups** — bug class, Apple fix, gap on 18.x
3. **Relaxin / Coruna public material** — claim vs proof; SoC/iOS; entry model
4. **LARA matrix honesty:** through **18.7.1**; 18.7.5 outside until proven
5. Long-shot: find a still-live or new bug — treat as new research, not a given

### How we’d reverse-engineer / validate
- Follow RE order in [../research/kexploit/RE_PRIORITY.md](../research/kexploit/RE_PRIORITY.md)
- Applicability checklist in [../research/kexploit/THEORY.md](../research/kexploit/THEORY.md)
- Fill matrix rows with citations; reject silent “supports 15–26” marketing
- Cursor: diffs + mitigation timeline — **not** IPA decompile → free exploit
- If ever testing: isolated branch/device session; never merge into `boot/`

### Dependencies / risks
- False confidence from README marketing or closed binaries
- PAC/PPL/SPTM confusion across SoC generations (A12 has PPL, not SPTM)
- Blind offset ports to 22H311 without a live primitive
- Legal/ethical: own device research only; no weaponization writeups

### Exit criteria — done when…
- [x] RE priority + matrix skeleton committed (teachers framing)
- [ ] Written go/no-go for each studied family on A12/22H311 with evidence
- [ ] If “go”: minimal PoC plan that still stays out of the boot scripts
- [ ] If “no-go”: STATUS updated; roadmap pivots (new bug class or accept tethered-only limits)

---

## Stage D — Mitigations map (A12 on iOS 18)

### Goal
Accurate map of what still binds us after BootROM on this SoC/OS.

See [../research/mitigations/README.md](../research/mitigations/README.md).

### What we already have
- BootROM bypass for tethered DFU control
- Awareness that A12 ≠ A11 (checkm8) and A12 ≠ A14+ SPTM world in the same way

### What’s missing
- Per-mitigation “does BootROM help?” answers grounded in 18.7.5
- Clarity on PPL vs SPTM/TXM relevance to **A12**

### Candidate approaches (theory)
- Literature + RE of 22H311 kernel/AMFI paths
- Cross-check public Dopamine / Coruna *discussions* of PPL as historical technique names only

### Exit criteria — done when…
- [ ] Mitigations table reviewed against 22H311 notes (no major “wrong SoC” mistakes)
- [ ] Each later stage cites which mitigation it must confront

---

## Stage E — Bypass theories (post-kernel primitives)

### Goal
If (and only if) some form of kernel r/w or equivalent exists, reason about
AMFI, codesign, sandbox, library validation, PPL — as *theories*, not promises.

### What we already have
- Historical patterns from checkra1n / palera1n / Dopamine ecosystems (names/concepts)
- No live primitive on 18.7.5 yet

### What’s missing
- Actual primitive
- 18.7.5-specific changes vs those historical writeups (*speculation* until RE’d)

### Candidate approaches (theory)
| Area | What it blocks | Classic patterns (historical) | Likely 18.7.5 caution |
|------|----------------|-------------------------------|------------------------|
| PPL | Sensitive kernel/page-table ops | Dedicated PPL attacks in older JB research | Must confirm A12/iOS 18 still matches assumed model |
| AMFI | Unsigned/untrusted exec | AMFI hooks / trustcache / get-task-allow games | Cryptex / tighter policy — verify on this build |
| Codesign / LV | Library validation, loading | CS flags, platform binaries | arm64e + modern CS — don’t assume A11 tricks |
| Sandbox | App containment | Sandbox escape after k r/w | Still required for useful userspace |

### How we’d reverse-engineer / validate
- Trace which checks fire on a test unsigned binary *after* a hypothetical primitive
- Prefer crash logs / policy denials over blind patching

### Dependencies / risks
- Entire stage is blocked on Stage C
- Cargo-culting palera1n/Dopamine patches onto A12/18.7.5 is expected to fail

### Exit criteria — done when…
- [ ] Written “primitive → policy bypass” plan for *this* build, or explicit deferral

---

## Stage F — Userspace bootstrap (Sileo/Zebra, jailbreakd, injectors)

### Goal
Package manager / tweak injection architecture **after** kernel-capable primitives.

### What we already have
- Dopamine as an *architecture* reference (rootless, jailbreakd concepts)
- Tethered SSH only in restore ramdisk today — **not** SpringBoard

### What’s missing
- Kernel r/w (or equivalent)
- Safe bootstrap that survives the 18.7.5 policy model
- Decision: rootless vs other layouts

### Candidate approaches (theory)
1. Study Dopamine bootstrap sequencing as a checklist of *components*, not a port
2. Injector strategy only after codesign/AMFI theory is grounded
3. Keep bootstrap artifacts out of `boot/` until a dedicated userspace phase

### Exit criteria — done when…
- [ ] Component checklist written (jb daemon, path remaps, package repo)
- [ ] Explicit dependency edge: “blocked until Stage C/E exit criteria”

---

## Stage G — Persistence model (honest)

### Goal
State clearly what “jailbreak” would mean on this device given BootROM reality.

### What we already have
- **Always-available tethered entry** via usbliter8 (silicon), re-pwn each boot
- No evidence of untether on A12/18.7.5

### What’s missing
- Semi-untether would need a surviving userspace/kernel foothold across reboot
  without BootROM — *not demonstrated; do not promise*

### Candidate approaches (theory)
| Model | Meaning | Likelihood framing |
|-------|---------|-------------------|
| Fully tethered | Every boot: Pico/usbliter8 → chain | Matches current hardware reality |
| Semi-untether | BootROM once per update; userspace persists | *Speculation* — needs durable kernel/userspace exploit story |
| Fully untether | No cable | Not in scope given known public landscape; do not claim |

### Exit criteria — done when…
- [ ] STATUS “Persistence” section matches reality (default: tethered-only)
- [ ] Any semi-untether idea listed as research hypothesis with blockers

---

## Suggested order of work

```text
A foothold (Data / kernelcache)
  → B offline RE (22H311 corpus)
  → D mitigations map (correct SoC facts)
  → C kexploit applicability study (no boot wiring)
  → E bypass theories (only if C progresses)
  → F bootstrap architecture
  → G persistence honesty (continuous)
```

## See also
- [STATUS.md](STATUS.md)
- [RESEARCH.md](RESEARCH.md)
- [../research/mitigations/README.md](../research/mitigations/README.md)
- [../research/kexploit/RE_PRIORITY.md](../research/kexploit/RE_PRIORITY.md)
- [../research/kexploit/PUBLIC_PRIMITIVE_MATRIX.md](../research/kexploit/PUBLIC_PRIMITIVE_MATRIX.md)
- [../research/kexploit/THEORY.md](../research/kexploit/THEORY.md)
