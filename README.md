# Project Lumina

Research monorepo for a **tethered → (eventual) semi-untethered** A12/A13 path
starting from usbliter8 BootROM.

**This is not a jailbreak.** No Sileo / package-manager claim on iOS **18.7.5**.

Primary live device: iPhone XR (`n841ap`) on **18.7.5 (22H311)**.

### Honest status (Phase A, 2026-08-01)
- **Done:** BootROM (usbliter8) → ramdisk SSH → System volume mount (`/mnt1` shows 18.7.5)
- **Blocked:** Data volume mount (`mount_apfs: Program version wrong` on 15.1 ramdisk tooling)
- **Not done:** kernel exploit, PPL, userspace bootstrap

## What works today
1. usbliter8 Pico → Pwned DFU
2. iBSS → Recovery
3. hsbugss XR ramdisk payload chain → `bootx`
4. Root SSH (`alpine`) via `iproxy 2222 22`
5. System `disk0s1s1` → `/mnt1` (on-disk 18.7.5 / 22H311)

## Quick start (Mac)

**Preferred live path:** Pico usbliter8 → direct Mac USB →
`~/Projects/ICH_A12_plus_Ramdisk` (`./boot.sh`) → ICH `tools/darwin/iproxy`
→ SSH (`root` / `alpine`) → `mount_ich`.

```bash
# 1) Pico-pwn the XR, then plug it directly into the Mac (not through the Pico)
# 2) Boot ICH ramdisk (built for n841ap / 22H311):
cd ~/Projects/ICH_A12_plus_Ramdisk && ./boot.sh

# 3) Host helper (tool check + iproxy + prints SSH):
cd ~/Projects/lumina && ./scripts/user/one_shot_mac.sh

# Or reconnect with Lumina wrapper:
./boot/lumina-ssh.sh
```

Full button-by-button DFU → pwn → ramdisk → SSH sequence:
[`scripts/user/from_dfu_to_ssh.md`](scripts/user/from_dfu_to_ssh.md).

Alternate (15.1-style payloads, System mount only historically):
`./boot/lumina-boot.sh` with `~/Projects/usbliter8-xr-ramdisk` — see
[`boot/README.md`](boot/README.md).

UDID used for usbmux wait: `00008020-00117540340B002E`

## Supported devices

| Device | SoC | iOS | Status |
|--------|-----|-----|--------|
| iPhone XR (`n841ap`) | A12 | **18.7.5 (22H311)** | **Supported** — only combo these scripts/docs are verified against |
| Other A12/A13 (usbliter8 SoCs) | A12/A13 | any | **Not verified here** — expect to redo payload/config yourself |
| A11 and older, A14 and newer | — | — | **Out of scope** for usbliter8 entry |

## Requirements

- **Hardware:** iPhone XR, Mac, Raspberry Pi Pico 2 (RP2350) or other
  supported RP2350 board with `usbliter8` firmware, Lightning cable
  (prefer USB-A → Lightning for Mac boot). Pico flash/wiring is upstream
  usbliter8 scope — see [`upstream/README.md`](upstream/README.md).
- **Software (Mac):** `irecovery`, `idevice_id`, `sshpass`, `python3` +
  `pyusb` (`brew install libusb libirecovery libimobiledevice usbmuxd sshpass
  && python3 -m pip install pyusb`). Prefer ICH vendored
  `~/Projects/ICH_A12_plus_Ramdisk/tools/darwin/iproxy`.
- **Payloads:** `~/Projects/ICH_A12_plus_Ramdisk` (preferred live boot+SSH)
  and optionally `~/Projects/usbliter8-xr-ramdisk` for Lumina
  `boot/lumina-boot.sh`. Root `./usbliter8ctl` for DFU info/boot helpers.
- No Windows path for the ramdisk/SSH stage.

## Safety

- **Never write to `/mnt1`** (sealed System). Stage only under
  `JBROOT=/mnt2/root/jb` (or `/mnt2/tmp/…`) — never `/mnt2/jb` or classic
  `/var/jb` on disk.
- **PATH rule:** do not put `JBROOT` first until a full-path binary from
  `JBROOT` runs without `Killed: 9` (SIGKILL fix lands in
  `scripts/bootstrap/`; do not reimplement it here).
- **Uninstall** Data-side bootstrap with
  `./scripts/bootstrap/uninstall_bootstrap.sh` when that tree is present
  (Data-only; never touches `/mnt1`).
- **Tethered = lost on reboot.** Every reboot/unplug returns stock iOS;
  re-entry requires Pico pwn + ramdisk boot again — see
  [`scripts/user/from_dfu_to_ssh.md`](scripts/user/from_dfu_to_ssh.md#safety).
- Only run this on a device you own or have explicit permission to service.

## Layout
```text
PROJECT_STATUS.md         # lab package SoT (current / blocked / next)
boot/                     # one-command ramdisk re-entry (do not regress)
docs/STATUS.md            # live project status + Phase A paste area
docs/RESEARCH.md          # Dopamine / DarkSword / LARA index
scripts/                  # lab automation 00–04 (wait / boot / SSH / Data probe)
scripts/user/             # end-user packaging: DFU→SSH doc + one-shot Mac helper
scripts/bootstrap/        # Data-only Procursus-shaped staging (JBROOT; when present)
host/usbliter8ctl         # preferred DFU tool path for scripts/
ramdisk/NOTES_NEXT.md     # newer ramdisk checklist (no 15.1 Data claim)
gui/lab_console.py        # optional tkinter lab console
logs/                     # timestamped lab runs (gitignored)
artifacts/xr-18.7.5/      # dumps from the live XR (mostly gitignored)
research/CUSTOM_BOOT_NEXT.md
research/kexploit/        # isolated kexploit study (not in boot path)
research/checkm8/         # A11-and-older knowledge only
research/palera1n/        # A8–A11 reference only
tools/                    # host helpers / stubs
usbliter8ctl              # pyusb host utility (DFU / CUSTOM_BOOT)
```

## Lab automation (Mac)
Agent rules: [`LAB_AGENT_RULES.md`](LAB_AGENT_RULES.md).

```bash
./scripts/00_check_env.sh
python3 scripts/01_wait_pwned.py          # after Pico-pwn, direct USB
python3 scripts/02_boot_chain.py --skip-ibec   # or pass --ibss/--ibec
# full ramdisk: ./boot/lumina-boot.sh
./scripts/03_ramdisk_ssh.sh
./scripts/04_data_mount_probe.sh          # exit 76 expected — NOT Data success

# End-to-end after PWND (requires IBSS + IBEC):
export IBSS="$HOME/Projects/usbliter8-xr-ramdisk/payload/iBSS.raw"
export IBEC="$HOME/Projects/usbliter8-xr-ramdisk/payload/iBEC.raw"
./scripts/05_run_experiment.sh            # writes logs/last_run.md; exit 10 = NEED_REPWN
```

## Docs
- [scripts/user/from_dfu_to_ssh.md](scripts/user/from_dfu_to_ssh.md) — DFU → pwn → ramdisk → SSH
- [docs/STATUS.md](docs/STATUS.md)
- [docs/RESEARCH.md](docs/RESEARCH.md)
- [docs/ROADMAP_THEORY.md](docs/ROADMAP_THEORY.md) — staged RE / JB theory (docs only)
- [boot/README.md](boot/README.md)
- [research/mitigations/README.md](research/mitigations/README.md)
- [research/kexploit/THEORY.md](research/kexploit/THEORY.md)
- [research/checkm8/README.md](research/checkm8/README.md)
- [research/palera1n/README.md](research/palera1n/README.md)

## Hard gates
- Data mount blocked on current 15.1 ramdisk `mount_apfs`
- No working-kexploit claim on 18.7.5 / A12
- No Sileo / userspace bootstrap claim
- checkm8 / palera1n = knowledge only; usbliter8 = A12 BootROM entry only
- Kexploit stays under `research/kexploit/` — never wired into boot

## usbliter8ctl

`usbliter8ctl` is a `pyusb` host utility for an Apple device already placed
in Pwned DFU by usbliter8. For `1227` vs `1281`, `boot` vs `send`, Windows vs
Mac host setup, and a session-drop re-pwn checklist, see
[`docs/HOST_USB_HANDOFF.md`](docs/HOST_USB_HANDOFF.md).

On macOS, use the Pico only for the race/pwn step. Disconnect the phone from
the Pico and connect it directly to the Mac before running `usbliter8ctl`.
Leaving the phone connected through the Pico can prevent the remote-boot path
from completing.

For day-to-day XR ramdisk boots, prefer Mac +
`~/Projects/ICH_A12_plus_Ramdisk/boot.sh` (see
[`scripts/user/from_dfu_to_ssh.md`](scripts/user/from_dfu_to_ssh.md)
and [`docs/HOST_USB_HANDOFF.md`](docs/HOST_USB_HANDOFF.md)).
Lumina `./boot/lumina-boot.sh` remains the alternate payload-tree wrapper.

```sh
python3 -m pip install pyusb
python3 usbliter8ctl info
python3 usbliter8ctl demote
python3 usbliter8ctl boot iBoot_patched.raw
```

The macOS boot path deliberately:

- uses `wValue=0` and `wIndex=0` for every DFU request;
- terminates the download with an empty `DNLOAD` whose payload is `None`;
- polls `DFU_GETSTATUS` and logs each state until
  `MANIFEST_WAIT_RESET`;
- does not set a configuration or claim/release interface 0;
- waits up to two seconds for `CUSTOM_BOOT`;
- omits `DFU_ABORT` by default;
- issues the USB reset required by `MANIFEST_WAIT_RESET`;
- disposes the PyUSB handle before scanning for re-enumeration; and
- reports success only after finding Recovery (`05ac:1281`) or a new device
  identity.

`DFU_ABORT` is standard DFU request 6. Request 4 is `DFU_CLRSTATUS` and is not
used as an abort.

Use `--abort` to test `CUSTOM_BOOT` followed by the corrected `DFU_ABORT`
request, or `--no-abort` to omit the abort explicitly on any platform.
Use `--no-reset` to suppress the post-manifest USB reset:

```sh
python3 usbliter8ctl boot --no-abort iBoot_patched.raw
```

The alternative ordering requested for protocol diagnosis is also available:

```sh
python3 usbliter8ctl boot --boot-before-final-dnload iBoot_patched.raw
```

## CUSTOM_BOOT research

**Current:** known-good `payload/iBSS.raw` remote-boots to `05ac:1281` on
macOS; full ramdisk + SSH works. Historical stuck-on-`1227` notes and offset
checks live in [research/CUSTOM_BOOT_NEXT.md](research/CUSTOM_BOOT_NEXT.md).

```sh
python3 tools/decode_t8020_handler.py
./boot/lumina-boot.sh
```
