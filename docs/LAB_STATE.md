# Lab state — Fork 1 (short)

**Device:** iPhone XR `n841` · A12 · **18.7.5 / 22H311** · UDID `00008020-00117540340B002E`  
**Mission:** [`../research/kexploit/FORK1_STRATEGY.md`](../research/kexploit/FORK1_STRATEGY.md) · living truth: [`STATUS.md`](STATUS.md)

## 1) Verified working (tethered path)

Last lab evidence date: **2026-08-01** (Phase A locked). Docs lock: **2026-08-05** (Fork 1).

- usbliter8 → **Pwned DFU** on XR
- Known-good **iBSS → Recovery** (`05ac:1281`) — CUSTOM_BOOT stuck-on-1227 path is historical, not current ([`../research/CUSTOM_BOOT_NEXT.md`](../research/CUSTOM_BOOT_NEXT.md))
- hsbugss XR ramdisk chain → **`bootx`** + root SSH (`alpine`, `iproxy 2222`)
- System `disk0s1s1` → `/mnt1` **RO** — ProductVersion **18.7.5**, ProductBuildVersion **22H311**
- Also mounted RO in that session: Update, Cryptex, Preboot, bbfs, FactoryData
- Offline kernelcache extract noted on Mac (`kernelcache.payload`, arm64e fileset) — not KRW ([`../research/kexploit/22H311_NOTES.md`](../research/kexploit/22H311_NOTES.md))

## 2) Open blockers only

- **Data** `disk0s1s2` / `s8`: `mount_apfs` exit **76** (`Program version wrong`) on 15.1 ramdisk tooling ([`../research/DATA_MOUNT_SSHRD.md`](../research/DATA_MOUNT_SSHRD.md))
- **No matching public kexploit** for A12 / 18.7.5 (matrix status line)
- **No live KRW** on this XR; PPL / Dopamine-style delivery blocked until a real primitive
- Live USB path needs **Mac + Pico + phone** (cloud cannot run it)

## 3) Next 3 commands (Mac, phone ready)

Prereq (not counted): Pico-pwn XR, then plug phone **directly** into Mac (not through Pico); repo root with `boot/config.env` set; payloads at `~/Projects/usbliter8-xr-ramdisk`.

```bash
./boot/lumina-boot.sh
```

```bash
./boot/lumina-ssh.sh
```

```bash
./boot/lumina-ssh.sh 'cat /mnt1/System/Library/CoreServices/SystemVersion.plist'
```

Expect **18.7.5** / **22H311**. Paste plist output → date in STATUS evidence log.  
**RO only** — no writes, no exploit attempts, no Fork 2.
