# Mitigations map — A12 (XR) + iOS 18.x research notes

Own-device RE notes for **iPhone XR / A12 / iOS 18.7.5 (22H311)**.
Not a bypass guide. **BootROM foothold ≠ jailbreak.**

Legend:
- **BootROM helps?** — Does usbliter8 (or similar) directly remove this control?
- **Needs kexploit?** — Typically needs kernel (or stronger) primitive on the *running* OS

| Mitigation | What it protects | BootROM helps? | Needs kexploit? | Notes for 18.7.5 / A12 |
|------------|------------------|----------------|-----------------|-------------------------|
| **SecureROM** | Earliest code integrity; DFU trust | **Yes** — usbliter8 achieves pwned DFU / custom USB handler | No for entry | Proven on this XR. Does not grant live kernel r/w. |
| **iBoot image4** | Boot-object signatures (iBSS/iBoot/…) | Partial — can load *raw* next stages via CUSTOM_BOOT after demote (as used in tethered chain) | Not for boot objects once chain is attacker-controlled | Still must feed correct board/build payloads. |
| **CTRR** | Contiguous memory lockdown in boot chain | Partial — public iBoot patchfinder *concepts* exist in usbliter8 ecosystem | Often boot-stage patches, not live OS | Treat as boot-chain concern; verify any patch claims per image. |
| **PAC (arm64e)** | Return/pointer integrity in EL1/userspace | No | Usually yes to *survive* or forge pointers in exploits | A12 is arm64e-class for modern iOS userspace/kernel. Complicates naive exploits. |
| **PPL** | Protected page-table / sensitive kernel ops (A12-era model) | No | Typically yes (dedicated PPL strategy after or with k r/w) | *Research:* confirm how 18.7.5 kernel still describes PPL on A12; do not assume A11 writeups. |
| **SPTM / TXM** | Newer secure page-table / execution monitors | No | N/A or different research track | **Primarily newer SoCs (e.g. A15+ / later platforms).** Do **not** treat SPTM/TXM as the A12 XR’s main map; cite only for contrast. |
| **AMFI** | Exec policy, trust, entitlements | No for live OS | Usually yes (hooks/policy after k r/w) | Live SpringBoard still AMFI-bound; ramdisk root SSH is a different environment. |
| **Codesigning (CS)** | Signature / platform / library validation | No for live OS | Usually yes | Library Validation blocks unsigned dylib injection without policy changes. |
| **Sandbox** | Per-process containment | No | Often after k r/w / unsandbox | Required for useful tweak-style capability. |
| **APFS sealed system** | System snapshot / seal integrity | Indirect — can *read* System from ramdisk | Writes/seal defeat need stronger story | We mount System RO-capable from 15.1 ramdisk; seal/write not characterized. |
| **APFS Data + file protection** | User data confidentiality/integrity | Indirect | Mount tooling + often SEP/class keys | **Live blocker:** 15.1 `mount_apfs` → “Program version wrong” on Data. Even after mount, passcode/SEP classes may limit files. |
| **SEP / data protection** | Keys, passcode, sensitive data classes | No (SEP not compromised by usbliter8 research claims) | Beyond normal kexploit scope | BootROM jailbreak research historically leaves SEP as separate hard problem; don’t assume Data readability equals plaintext of protected files. |

## Practical reading for Lumina

1. usbliter8 removes **SecureROM** as the tethered entry gate.
2. Everything about **running iOS 18.7.5** (AMFI, CS, sandbox, PPL) still applies once that OS is booted normally.
3. Our ramdisk session is a **restore environment** (15.1 tooling) inspecting volumes — not proof of SpringBoard-level control.
4. SPTM/TXM discussions in iOS 17–18 public JB chatter often target **newer silicon**; keep A12 notes in the PPL/PAC/AMFI row, not SPTM cargo-cult.

## Related
- [../../docs/ROADMAP_THEORY.md](../../docs/ROADMAP_THEORY.md)
- [../kexploit/THEORY.md](../kexploit/THEORY.md)
- [../../docs/STATUS.md](../../docs/STATUS.md)
