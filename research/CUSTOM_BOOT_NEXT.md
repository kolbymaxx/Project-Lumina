# CUSTOM_BOOT research after host-path exhaustion

## Status

On iPhone XR (`n841` / CPID `8020` / CPRV `11` /
`SRTG:[iBoot-3865.0.0.4.7]`), the macOS host path is exhausted:

- DFU image upload succeeds
- empty `DNLOAD` reaches `MANIFEST_WAIT_RESET` (`state=8`, `status=0`)
- `CUSTOM_BOOT` before or after empty `DNLOAD` returns pipe/stall
- USB reset after state 8 does not help
- `DFU_ABORT` is request `6`; Darwin omits it by default
- device remains `05ac:1227` with the same `PWND:[usbliter8]` serial

No further host USB protocol churn.

## 1. Boot a known-good unpatched n841 iBSS.raw

The strongest remaining host-side variable is the payload itself.

| Image | Size | Notes |
| --- | --- | --- |
| Local failing image (`iBoot_patched.raw`) | `0x20f478` / `2159736` | patched raw iBoot/iBSS-style |
| `hsbugss/usbliter8-xr-ramdisk` `payload/iBSS.raw` | `0x20f4e8` / `2159848` | Git LFS; sha256 `c34d01371b6fc98c7e6d10ef6f1a31df0a1883ef56ce5703c92eac26938642f7` |

Delta: **112 bytes**. These are not the same blob.

On the Mac, after a fresh pwn and direct cable to the Mac:

```bash
git clone https://github.com/hsbugss/usbliter8-xr-ramdisk.git
cd usbliter8-xr-ramdisk
git lfs pull
shasum -a 256 payload/iBSS.raw
# expect c34d01371b6fc98c7e6d10ef6f1a31df0a1883ef56ce5703c92eac26938642f7

python3 ../usbliter8ctl boot payload/iBSS.raw
# or their minimal helper:
python3 tools/usbliter8ctl boot payload/iBSS.raw
```

Interpretation:

- If known-good `iBSS.raw` reaches `05ac:1281`, the remote-boot path works
  and the patched local image / load identity is the problem.
- If known-good `iBSS.raw` also stays on `1227`, focus on Pico handler
  runtime / stack-LR state, not patchfinder.

Also compare an independently decrypted unpatched n841 iBSS from the same
IPSW family before concluding the payload is bad.

## 2. Official t8020 handler offsets vs CPRV:11

Official `usb_req_handler/targets/t8020/offsets.h` (prdgmshift / mirrors):

| Symbol | Address |
| --- | --- |
| `HANDLE_USB_REQ` | `0x10000E3EC` |
| `PLATFORM_DEMOTE` | `0x100007CF8` |
| `PLATFORM_SET_REMOTE_BOOT` | `0x100006850` |
| `MAIN_TASK_STACK_LR` | `0x19C01DF08` |
| `JUMP_AWAY` | `0x100001C8C` |

Cross-checks:

1. Paradigm Shift paper A12 listing lands remote-boot setup at
   `BL 0x100006850` and the jump trampoline at `0x100001C8C` —
   exact match for `PLATFORM_SET_REMOTE_BOOT` and `JUMP_AWAY`.
2. Official README uses the same serial example as this XR:
   `CPID:8020 CPRV:11 ... SRTG:[iBoot-3865.0.0.4.7] PWND:[usbliter8]`.
3. Decoding the published `resources/handler_t8020.h` blob recovers the
   same five addresses; see
   [`tools/decode_t8020_handler.py`](../tools/decode_t8020_handler.py).

Conclusion for static offsets: the published t8020 CUSTOM_BOOT constants are
consistent with A12 SecureROM `iBoot-3865.0.0.4.7` / CPRV:11. A wrong
hardcoded ROM address is unlikely unless the flashed UF2 is not the stock
t8020 handler build.

Still open at runtime:

- whether `MAIN_TASK_STACK_LR` still holds the live return slot when DFU is
  sitting in `MANIFEST_WAIT_RESET`
- whether the flashed Pico UF2 actually contains the published
  `handler_t8020` payload

## 3. Compare with hsbugss XR ramdisk helper

`hsbugss/usbliter8-xr-ramdisk/tools/usbliter8ctl` is the minimal official-style
tool with one important correction:

- official upstream helper uses `DFU_ABORT = 4` (`CLRSTATUS`)
- hsbugss helper uses `DFU_ABORT = 6` (correct DFU / handler enum value)
- both: no `set_configuration`, no claim, `wValue=0`/`wIndex=0`, empty
  `DNLOAD` with `None`, then `CUSTOM_BOOT` then `DFU_ABORT`

Their `exploit.sh` boots `payload/iBSS.raw` in the background and polls
`irecovery` for Recovery. That is the comparison path to run after
`git lfs pull`.

## Recommended order on the live XR

1. Confirm Pico UF2 is an official/stock t8020 build.
2. Pwn → direct Mac cable → `python3 usbliter8ctl info`.
3. Boot LFS `payload/iBSS.raw` (unpatched known-good).
4. If that works, bisect the local patched image against unpatched
   decrypted n841 iBSS/iBoot.
5. If that fails, treat CUSTOM_BOOT as a device-side remote-boot / stack-LR
   problem and inspect the flashed handler / live `0x19C01DF08` contents
   with a memrw-capable pwned DFU tool.
