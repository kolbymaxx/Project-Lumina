# From DFU to SSH — iPhone XR (n841ap) / A12 / 18.7.5

Exact button + command sequence to go from a stock iPhone XR on
**18.7.5 (22H311)** to a **tethered** root SSH session.

**This is not a jailbreak.** No Sileo, no package manager, no persistence
across reboot. Repeat this entire sequence after every reboot or unplug.

Supported combo for this doc: **XR `n841ap` + 18.7.5 (22H311) only**.

## Lab constants

```text
DEVICE: iPhone XR n841ap, A12, iOS 18.7.5 (22H311)
ENTRY:  usbliter8 SecureROM pwn + ICH A12 ramdisk (tethered)
JBROOT: /mnt2/root/jb only (NOT /mnt2/jb, NOT classic /var/jb on disk)
/mnt1 = System (treat RO — do not write JB here)
/mnt2 = Data (writable)
SSH:    iproxy 2222 22, root/alpine
PATH rule: never put JBROOT first until a full-path binary runs without Killed: 9
```

## 0. Requirements

| Need | Detail |
|------|--------|
| Device | iPhone **XR (`n841ap`)**, stock **18.7.5 (22H311)** |
| Host | **Mac** (no supported Windows path for ramdisk/SSH) |
| Pico | Raspberry Pi Pico 2 (RP2350) or other supported RP2350 board, flashed with `usbliter8` — see [`upstream/README.md`](../../upstream/README.md) |
| Cable | Lightning cable for DFU/pwn; prefer **USB-A → Lightning** for Mac boot (USB-C adapters are flaky) |
| ICH ramdisk | `~/Projects/ICH_A12_plus_Ramdisk` built for `n841ap-18.7.5-22H311-ramdisk` (`./setup.sh`, then `./build.sh`) |
| Lumina repo | this tree — root `./usbliter8ctl`, optional `./boot/lumina-boot.sh` / `./boot/lumina-ssh.sh` |
| Brew tools | `irecovery`, `idevice_id`, `sshpass`, `python3` + `pyusb` |

```bash
brew install libusb libirecovery libimobiledevice usbmuxd sshpass
python3 -m pip install pyusb
```

Prefer ICH’s vendored `iproxy` over Homebrew’s (brew `iproxy` can drop):

```text
~/Projects/ICH_A12_plus_Ramdisk/tools/darwin/iproxy
```

Optional host preflight (checks tools, starts `iproxy`, prints SSH):

```bash
./scripts/user/one_shot_mac.sh
```

## 1. Put the phone in DFU mode

Face‑ID iPhones (XR), **while the phone is connected**:

1. Connect the iPhone with the Lightning cable.
2. Hold **Side** + **Volume Down** together for ~**10 seconds**.
3. Release **Side**, keep holding **Volume Down** for another ~**5 seconds**.
4. Release. Screen stays **completely black** (no Apple logo, no recovery graphic).
5. Confirm:

   ```bash
   irecovery -q
   # expect: MODE: DFU
   ```

## 2. Pico pwn (SecureROM)

1. Unplug the iPhone from the Mac.
2. Plug the iPhone (still in DFU) into the **Pico** (usbliter8 firmware powered).
3. Wait (~2 s). Watch the board LED for success per your firmware.
4. On failure: power-cycle the Pico and retry DFU → pwn.
5. Unplug the iPhone from the Pico.

## 3. Connect **directly** to the Mac

Do **not** leave the phone connected through the Pico.

1. Plug the phone **directly** into the Mac (no hub if possible; USB-A preferred).
2. Confirm pwned DFU:

   ```bash
   irecovery -q
   # expect: MODE: DFU ... PWND:[usbliter8]
   ```

   or from the Lumina repo:

   ```bash
   python3 ./usbliter8ctl info
   # expect: Pwned DFU / PWND:[usbliter8]
   ```

## 4. Boot the ramdisk (preferred: ICH)

**Preferred live path** — Mac + ICH A12 ramdisk (direct iBEC → Recovery → `bootx`):

```bash
cd ~/Projects/ICH_A12_plus_Ramdisk
# first time / after IPSW change:
./setup.sh
./build.sh --build 22H311 --with-fw --kpf-set ios18
# every tethered boot after PWND:
./boot.sh
```

Built bootchain expected under something like:

```text
~/Projects/ICH_A12_plus_Ramdisk/bootchain/n841ap-18.7.5-22H311-ramdisk
```

If `./boot.sh` prompts to unplug/replug for Recovery re-enumeration, follow it
(USB-A cable helps).

### Alternate: Lumina wrappers

For the older hsbugss-style 15.1 payload tree (`~/Projects/usbliter8-xr-ramdisk`),
Lumina also ships:

```bash
cd ~/Projects/lumina   # or this clone
cp boot/config.env.example boot/config.env   # first time
./boot/lumina-boot.sh
```

That path can reach SSH + System `/mnt1`, but **Data mount is not the live
lab path** — prefer ICH `boot.sh` + `mount_ich` for `/mnt1` **and** `/mnt2`.
See [`boot/README.md`](../../boot/README.md).

## 5. SSH in

Terminal 1 — prefer ICH vendored `iproxy`:

```bash
~/Projects/ICH_A12_plus_Ramdisk/tools/darwin/iproxy 2222 22
```

Or run the host helper (resolves ICH `iproxy` when present):

```bash
./scripts/user/one_shot_mac.sh
```

Terminal 2:

```bash
sshpass -p alpine ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
  -p 2222 root@127.0.0.1
```

Or via Lumina (brew/`PATH` `iproxy`):

```bash
./boot/lumina-ssh.sh
```

On device, mount volumes (ICH path):

```bash
mount_ich
# /mnt1 = System (18.7.5 / 22H311) — treat RO
# /mnt2 = Data — writable staging only under /mnt2/root/jb (or /mnt2/tmp/…)
```

Credentials: **root** / **alpine**, local port **2222**.

## 6. (Optional) Data-only bootstrap

Staging a Procursus-shaped prefix on Data is **not** a working jailbreak.
When present, use [`scripts/bootstrap/`](../bootstrap/) only:

- Install under **`JBROOT=/mnt2/root/jb`** — never `/mnt1`, never `/mnt2/jb`,
  never classic `/var/jb` on disk.
- **PATH rule:** do not put `JBROOT` first on `PATH` until a full-path binary
  runs without `Killed: 9`, e.g.
  `/mnt2/root/jb/usr/bin/dpkg --version`.
- The SIGKILL / exec fix lives in `scripts/bootstrap/` (e.g. `fix_exec.sh`) —
  **do not reimplement it** in user wrappers; run those scripts after push.

Uninstall (Data-only; never touches `/mnt1`):

```bash
./scripts/bootstrap/uninstall_bootstrap.sh
```

## 7. Losing the session

Unplug, reboot, or crash → stock iOS. **No persistence.** Re-enter from
step 1 (DFU → Pico pwn → direct Mac → ICH `boot.sh`).

## Safety

- **Never write to `/mnt1`.** Sealed System volume — read-only for all JB/bootstrap work.
- **JBROOT is `/mnt2/root/jb` only.** New top-level Data dirs (e.g. `/mnt2/jb`)
  reject file creates; ramdisk `/var` ≠ Data.
- **Uninstall** Data-side staging with
  `./scripts/bootstrap/uninstall_bootstrap.sh` when that tree is present.
- **Tethered = lost on reboot.** Every power-off, reboot, or USB disconnect
  returns the phone to stock iOS until you re-pwn and re-boot the ramdisk.
- **Refuse foreign UDID** `00008020-000231A00EE9002E` (enforced in
  `boot/lib-udid.sh`).
- Only run this on a device you own or have explicit permission to service.

## Troubleshooting

| Symptom | Likely cause / fix |
|---------|-------------------|
| `irecovery -q` empty | Redo DFU (step 1); check cable |
| Pico never reports success | Power-cycle Pico; retry DFU → pwn |
| `PWND:[usbliter8]` missing after Mac plug | Still through Pico, or pwn failed — direct cable + re-pwn |
| ICH `boot.sh` stuck after iBoot send | Unplug/replug when prompted; USB-A; rebuild `--with-fw` |
| SSH connection refused | Start ICH `tools/darwin/iproxy 2222 22` (or `./scripts/user/one_shot_mac.sh`) |
| `Killed: 9` on a `JBROOT` binary | Run `scripts/bootstrap/fix_exec.sh` — do not “fix” by reordering `PATH` |
| Phone boots normal iOS | Session lost — repeat from step 1 |
