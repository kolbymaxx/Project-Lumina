# Host USB handoff — `usbliter8ctl` (DFU → pwn → boot)

Read-only notes on the host tool: what `1227` vs `1281` mean, when to use
`boot` vs `send`, Mac vs Windows setup, and what to do if the tethered session
drops. Behavior is taken from `./usbliter8ctl` (byte-identical to
`host/usbliter8ctl`), plus existing STATUS / lab scripts. No new capability
claims.

See also: [`PROJECT_STATUS.md`](../PROJECT_STATUS.md) · [`docs/STATUS.md`](STATUS.md) ·
[`README.md`](../README.md#usbliter8ctl) · [`LAB_AGENT_RULES.md`](../LAB_AGENT_RULES.md)

## 1. `05ac:1227` vs `05ac:1281`

Apple vendor `0x05AC` product IDs from `usbliter8ctl`:

```python
VENDOR = 0x05AC
PID_DFU = 0x1227
PID_RECOVERY = 0x1281
```

| PID | Mode | Meaning here |
|-----|------|----------------|
| `05ac:1227` | **DFU** | Normal Apple DFU PID. After Pico usbliter8, the device stays on this PID but the USB serial includes `PWND:[usbliter8]` (`PWND_MARKER`). `info` / `diagnose` label that as **Pwned DFU** only when the marker is present. Bare `1227` without the marker = DFU, **not** pwned — re-run Pico. |
| `05ac:1281` | **Recovery** | Apple Recovery PID. Reached after a successful `CUSTOM_BOOT` (request `8`) leaves SecureROM into the uploaded image. `boot` treats re-enumeration as `05ac:1281` — or a `1227` device with a *new* serial — as success (`scan_after_boot()`). |

**Historical stuck-on-1227** (closed; see
[`research/CUSTOM_BOOT_NEXT.md`](../research/CUSTOM_BOOT_NEXT.md)): a mismatched
local patched image uploaded and reached `MANIFEST_WAIT_RESET`, but never left
SecureROM (same pwned serial on `1227`). Known-good `payload/iBSS.raw` does
re-enumerate as `1281`. Discriminator was the **image**, not host protocol
churn.

**Separate Windows negative** (STATUS / PROJECT_STATUS): DFU→Recovery `boot`
could reach `1281`, but later iBEC `go` / `bootx` stayed on `1281` with no new
`SRTG`. That is a post-Recovery execute failure, not a DFU PID confusion.

## 2. `boot` vs `send`

Subcommands: `info`, `demote`, `boot`, `wait`, `send`, `diagnose`.

| Command | Device state | Status | Role |
|---------|--------------|--------|------|
| `boot IMAGE` | Pwned DFU (`05ac:1227` + marker) | **Implemented** | DFU upload (`DFU_DNLOAD`, `0x800` chunks) → empty `DNLOAD` → poll to `MANIFEST_WAIT_RESET` → `CUSTOM_BOOT` → optional `DFU_ABORT` / USB reset → scan for Recovery. This is the **1227 → 1281** step. |
| `send IMAGE` | Intended: Recovery (`05ac:1281`) | **Not implemented** | Always raises `ToolError` (“send is not implemented… Mac fallback: `irecovery -f`”). Never touches USB. |

**Guidance** (matches `scripts/02_boot_chain.py`):

1. Use `usbliter8ctl boot <iBSS>` for Pwned DFU → Recovery.
2. For Recovery bulk upload (e.g. iBEC), `send` fails fast; on Mac use
   `irecovery -f <iBEC>` (`brew install libirecovery`). `02_boot_chain.py`
   already does this fallback.
3. For **live** XR ramdisk SSH, prefer Mac + ICH
   `~/Projects/ICH_A12_plus_Ramdisk` (`boot.sh`, direct iBEC → `bootx`) —
   not Windows `send`/`go`, and not waiting on `send` to be implemented.
   Lumina `scripts/01`–`05` are host DFU helpers; live boot SoT is ICH.

macOS `boot` defaults (`sys.platform == "darwin"`): omit `DFU_ABORT`, issue
USB reset, skip `set_configuration` / interface claim; tool prints that the
phone must be connected **directly** to the Mac.

## 3. Mac vs Windows host setup

**Mac (authoritative for device work):**

```bash
brew install libusb libirecovery libimobiledevice usbmuxd sshpass
python3 -m pip install pyusb
python3 -c "import usb; import usb.backend.libusb1 as b; print(usb.__version__, b.get_backend())"
python3 usbliter8ctl diagnose
```

- Homebrew `libusb` supplies `libusb-1.0` for PyUSB’s `libusb1` backend.
- No Zadig/WinUSB on Mac (`AGENTS.md`).
- After Pico pwn: disconnect from Pico; plug phone **directly** into the Mac
  before `usbliter8ctl` or ICH / `boot/lumina-boot.sh`.

**Windows (DFU/pwn handoff only):**

- `usbliter8ctl diagnose` warns if the backend is missing:
  `WARN: no libusb backend (Mac: brew install libusb; Windows: provide libusb-1.0)`.
- In practice that means a `libusb-1.0` DLL visible to PyUSB **and** a
  WinUSB-class binding for the Apple DFU/Recovery device (commonly via
  **Zadig**) instead of Apple’s stock driver. This repo does **not** vendor a
  proven Zadig profile — treat that as generic PyUSB guidance, not a
  Lumina-validated Windows recipe.
- Measured STATUS negative: Windows iBSS→iBEC→`go` abandoned (stayed on
  `1281`, no new `SRTG`). Do ramdisk boot on Mac/ICH.

## 4. Session-drop → full re-pwn checklist

Tethered SecureROM entry: unplug / reboot / lost USB link ⇒ full re-pwn.
Aligned with `LAB_AGENT_RULES.md`, `scripts/01_wait_pwned.py`, and
`scripts/05_run_experiment.sh` (`NEED_REPWN`, exit `10`).

1. **Confirm the device is actually gone** (do not ask for re-pwn otherwise):
   - `python3 usbliter8ctl info` (or `diagnose`) — look for `05ac:1227`
     (Pwned DFU) or `05ac:1281` (Recovery).
   - `idevice_id -l` — any UDID means usbmux still sees a device.
   - If either finds a device: fix SSH / iproxy / ramdisk boot; **not** re-pwn
     (`LAB_AGENT_RULES.md` “Device lost → STOP”).
2. **If truly gone** (`info` empty and no usbmux UDID): re-pwn.
   - Pico-pwn the XR again.
   - Connect the phone **directly to the Mac** (not through the Pico).
   - Poll: `python3 scripts/01_wait_pwned.py` (wants Pwned DFU +
     `PWND:[usbliter8]`).
3. **Resume live boot (preferred):** ICH
   `~/Projects/ICH_A12_plus_Ramdisk` → `boot.sh` for the
   `n841ap-18.7.5-22H311-ramdisk` chain. Optional DFU helper only:
   `python3 usbliter8ctl boot <iBSS.raw>` or `./boot/lumina-boot.sh` (legacy
   15.1 payload tree). Do not re-open closed CUSTOM_BOOT protocol churn.
4. **Reconnect SSH:**
   ```bash
   ~/Projects/ICH_A12_plus_Ramdisk/tools/darwin/iproxy 2222 22
   sshpass -p alpine ssh -p 2222 root@127.0.0.1
   # mount_ich
   ```
5. **Agent report format** when re-pwn is required: template in
   `LAB_AGENT_RULES.md` / `scripts/05_run_experiment.sh` (`Need re-pwn`).

## Non-claims

- No new kexploit, PID, or protocol behavior — sourced from `usbliter8ctl`,
  `research/CUSTOM_BOOT_NEXT.md`, STATUS twins, and lab scripts.
- Windows libusb/Zadig notes are generic PyUSB + `diagnose` wording, not an
  end-to-end validated Windows boot path.
- Nothing wired into `boot/` beyond existing wrappers; live SoT remains Mac +
  ICH `boot.sh`.
