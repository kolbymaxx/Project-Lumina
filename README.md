# Project Lumina

Research monorepo for a **tethered → (eventual) semi-untethered** A12/A13 path
starting from usbliter8 BootROM.

**Not** a claim of public Sileo / package-manager jailbreak on iOS **18.7.5**.

Primary live device: iPhone XR (`n841ap`) on **18.7.5 (22H311)**.

## What works today
1. usbliter8 Pico → Pwned DFU
2. iBSS → Recovery
3. hsbugss XR ramdisk payload chain → `bootx`
4. Root SSH (`alpine`) via `iproxy 2222 22`

## Quick start (Mac)
```bash
# 1) Pico-pwn the XR, then plug it directly into the Mac
# 2) Ensure payloads exist:
#    ~/Projects/usbliter8-xr-ramdisk  (git lfs pull)
# 3) Boot + SSH check:
./boot/lumina-boot.sh

# Reconnect later in the same tethered session:
./boot/lumina-ssh.sh
```

UDID used for usbmux wait: `00008020-00117540340B002E`

## Layout
```text
boot/                     # one-command ramdisk re-entry (do not regress)
docs/STATUS.md            # live project status + Phase A paste area
docs/RESEARCH.md          # Dopamine / DarkSword / LARA index
artifacts/xr-18.7.5/      # dumps from the live XR (mostly gitignored)
research/CUSTOM_BOOT_NEXT.md
research/kexploit/        # isolated kexploit study index (not in boot path)
tools/                    # host helpers / stubs
usbliter8ctl              # pyusb host utility (DFU / CUSTOM_BOOT)
```

## Docs
- [docs/STATUS.md](docs/STATUS.md)
- [docs/RESEARCH.md](docs/RESEARCH.md)
- [boot/README.md](boot/README.md)
- [research/kexploit/README.md](research/kexploit/README.md)

## Hard gates
- No Sileo / userspace jailbreak claim on 18.7.5
- No working-kexploit claim on 18.7.5 / 22H311
- Public LARA matrix ends at 18.7.1 (`18.7.2+` not supported there)
- Kexploit clones stay under `research/kexploit/` only

## usbliter8ctl

`usbliter8ctl` is a `pyusb` host utility for an Apple device already placed
in Pwned DFU by usbliter8.

On macOS, use the Pico only for the race/pwn step. Disconnect the phone from
the Pico and connect it directly to the Mac before running `usbliter8ctl`.
Leaving the phone connected through the Pico can prevent the remote-boot path
from completing.

For day-to-day XR ramdisk boots, prefer the known-good Mac helper paths
configured in `boot/config.env.example` and `./boot/lumina-boot.sh`.

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
