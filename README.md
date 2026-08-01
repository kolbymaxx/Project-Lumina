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
See earlier notes in [research/CUSTOM_BOOT_NEXT.md](research/CUSTOM_BOOT_NEXT.md).
For day-to-day XR ramdisk boots, prefer the known-good Mac helper paths
configured in `boot/config.env.example`.
