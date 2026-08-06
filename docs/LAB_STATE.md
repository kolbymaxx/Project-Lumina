# Lab state — Fork 1 (XR A12 / 18.7.5)

**Updated:** 2026-08-05 (Data Session A: System on `disk1s1`)  
**Fork:** [`../research/kexploit/FORK1_STRATEGY.md`](../research/kexploit/FORK1_STRATEGY.md)  
**Status detail:** [`STATUS.md`](STATUS.md)

Device: n841 / A12 / **18.7.5 (22H311)** — UDID `00008020-00117540340B002E`

## 1) Verified working (tethered path)

Last evidence date: **2026-08-01** (Phase A inventory locked).

- usbliter8 Pwned DFU on XR (direct Mac USB)
- macOS remote iBSS → Recovery `05ac:1281` (known-good `payload/iBSS.raw`)
- hsbugss XR ramdisk chain + root SSH (`alpine`, `iproxy` → local **2222**)
- Ramdisk: iOS **15.1** restore (`19B5042h`), root `/dev/md0` HFS RO
- RO mounts OK: System `/mnt1` (**18.7.5 / 22H311**), Update `/mnt4`, Cryptex `/mnt6`, Preboot `/mnt3`, bbfs `/mnt5`, FactoryData `/mnt7`
- Host wrappers: `./boot/lumina-boot.sh`, `./boot/lumina-ssh.sh` (UDID matches this XR)
- Offline (Mac, 2026-08-02): `kernelcache.payload` for 22H311 restored — RE corpus only, not a kexploit
- Offline RO probes (2026-08-05): `./tools/probe_22h311_kernelcache.sh` → `artifacts/xr-18.7.5/kernelcache-ro/` (see `22H311_NOTES.md`)

Sources: `STATUS.md`, `CUSTOM_BOOT_NEXT.md`, `kexploit/22H311_NOTES.md`.

## 2) Open blockers only

- **Data mount** — `disk0s1s2` / `disk0s1s8`: `mount_apfs -o rdonly` → exit **76** (`Program version wrong`) on 15.1 tools; no working A12/18.7.5 Data mount claimed
- **No public kexploit** for A12 / 18.7.5 — no KRW / root-on-booted-OS / Dopamine-style path
- **Userspace bootstrap** — blocked until a real kernel primitive exists
- **Nothing under `research/` wired into `boot/`** (intentional)

## 3) Next 3 Mac commands (phone + this XR)

Prerequisite (manual): phone already in **`PWND:[usbliter8]`** DFU on a **direct** Mac cable; repo at `/Users/kolby/Projects/lumina`; `boot/config.env` present; ramdisk tree at `~/Projects/usbliter8-xr-ramdisk`.

```bash
cd /Users/kolby/Projects/lumina && ./boot/lumina-boot.sh
./boot/lumina-ssh.sh
./boot/lumina-ssh.sh 'cat /mnt1/System/Library/CoreServices/SystemVersion.plist'
```

Expect in the third command’s output: **ProductVersion 18.7.5** and **ProductBuildVersion 22H311** (Device session 01 / T011 identity confirm). Then fill T011 Result; stop — no exploit attempts.

Data mount next (RO only): [`../research/DATA_MOUNT_LIVE_PLAN.md`](../research/DATA_MOUNT_LIVE_PLAN.md) — Session A on current 15.1 path before any 16.0 ramdisk trial.
