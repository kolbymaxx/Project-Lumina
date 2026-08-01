# PROJECT_STATUS — usbliter8 lab automation

**Source of truth for this lab package.** Device inventory twin: `docs/STATUS.md`.  
**Not a jailbreak.** No Sileo / full-JB claim on 18.7.5.

## Device
| Field | Value |
|-------|-------|
| Device | iPhone XR (n841ap) |
| SoC | A12 |
| NAND iOS | **18.7.5 (22H311)** |
| Entry | Pico usbliter8 → Pwned DFU `05ac:1227` `PWND:[usbliter8]` |

## Current (measured)
- Host: `host/usbliter8ctl` — `info`, `wait`, `boot`, `demote`, `diagnose`; `send` is placeholder (Mac: `irecovery -f`)
- Boot: optional demote → boot patched iBSS → Recovery `05ac:1281` → send iBEC → 15.1 ramdisk → SSH
- Mac SSH: `idevice_id`, `iproxy 2222 22`, `ssh -p 2222 root@127.0.0.1` / password `alpine`
- System volume at **`/mnt1`**
- Data `/dev/disk0s1s2`: `mount_apfs` → **exit 76** (`Program version wrong`)
- Newer System `mount_apfs` on 15.1: dyld missing **`_malloc_type_malloc`** (libSystem too old)

## Blocked
1. Data mount on the **15.1** ramdisk (exit 76) — APFS/userspace generation mismatch
2. Transplanting newer `mount_apfs` onto 15.1 without matching libSystem
3. **HARD RULE:** no `DYLD_LIBRARY_PATH` (or similar) hacks for Data on 15.1
4. No A12 / 18.7.5 kernel exploit in this package

## Next
1. Treat 15.1 Data + DYLD paths as **closed negatives**
2. Build/boot a **newer restore ramdisk** — `ramdisk/NOTES_NEXT.md`
3. Use `scripts/01`–`04` for re-entry; logs under `logs/`

## Explicit non-goals
- Working Data mount / Data R/W on the **15.1** ramdisk
- DYLD hacks for Data
- Claiming a full jailbreak, Sileo, or kexploit
- Inventing USB stacks beyond `usbliter8ctl` + `irecovery`

## Host paths
| | Mac | Windows |
|---|-----|---------|
| Repo | `~/Projects/lumina` | `%USERPROFILE%\Projects\lumina` |
| Payloads | `~/Projects/usbliter8-xr-ramdisk/payload` | same under `%USERPROFILE%\Projects\...` |
| Tool override | `export USBLITER8CTL=...` | `set USBLITER8CTL=...` |
| Live XR USB | Mac libusb (preferred) | libusb possible; prefer Mac for proven SSH path |
