# CUSTOM_BOOT research notes (historical → resolved)

## Current state (2026-08-01, iMac / XR)

**Resolved for the known-good path.** On iPhone XR (`n841ap`) iOS **18.7.5
(22H311)**:

- usbliter8 Pwned DFU works
- macOS remote iBSS boot → **`05ac:1281`** works (PR #2 host path)
- hsbugss `usbliter8-xr-ramdisk` full chain + root SSH works

Do **not** treat “stuck on `05ac:1227`” as the live status. That described an
earlier debug phase with a mismatched patched image / host sequencing.

See [docs/STATUS.md](../docs/STATUS.md) for current verified state.

## What was true during the stuck-on-1227 debug phase

While iterating the macOS host tool against a patched local image, we saw:

- DFU image upload succeed
- empty `DNLOAD` reach `MANIFEST_WAIT_RESET` (`state=8`, `status=0`)
- `CUSTOM_BOOT` return pipe/stall
- device remain `05ac:1227` with the same `PWND:[usbliter8]` serial

Host USB protocol churn was exhausted; the discriminating test was booting
known-good `payload/iBSS.raw`.

## Discriminating image comparison

| Image | Size | Outcome |
| --- | --- | --- |
| Local patched (`iBoot_patched.raw`) | `0x20f478` / `2159736` | stayed on DFU during debug |
| `hsbugss/.../payload/iBSS.raw` | `0x20f4e8` / `2159848` | **boots to Recovery `05ac:1281`** |

Delta: **112 bytes**. Not the same blob. Prefer known-good iBSS for the
ramdisk chain.

```bash
# known-good path (current)
python3 usbliter8ctl boot payload/iBSS.raw
# or
./boot/lumina-boot.sh
```

## Official t8020 handler offsets vs CPRV:11

Official `usb_req_handler/targets/t8020/offsets.h` (still useful reference):

| Symbol | Address |
| --- | --- |
| `HANDLE_USB_REQ` | `0x10000E3EC` |
| `PLATFORM_DEMOTE` | `0x100007CF8` |
| `PLATFORM_SET_REMOTE_BOOT` | `0x100006850` |
| `MAIN_TASK_STACK_LR` | `0x19C01DF08` |
| `JUMP_AWAY` | `0x100001C8C` |

These match the Paradigm Shift A12 paper listings and the published
`handler_t8020` blob (`tools/decode_t8020_handler.py`). Static offsets were
not the blocker once the known-good iBSS was used.

## Next research (not CUSTOM_BOOT host churn)

1. Phase A ramdisk ground truth — mount / disks / System+Data (see STATUS)
2. Keep kexploit study isolated under `research/kexploit/` — **no
   implementation in this phase**
3. Do not regress the working macOS iBSS → Recovery → ramdisk → SSH path
