# Lumina boot wrappers

One-command re-entry to the known-good XR ramdisk SSH session.

## Prerequisites (Mac)
- Device already in `PWND:[usbliter8]` DFU on a **direct** Mac cable
- Payload tree at `~/Projects/usbliter8-xr-ramdisk` (`git lfs pull` done)
- Tools: `irecovery`, `iproxy`, `idevice_id`, `sshpass`, `python3`, `pyusb`

```bash
brew install libirecovery libimobiledevice usbmuxd sshpass
python3 -m pip install pyusb
```

## Configure
```bash
cp boot/config.env.example boot/config.env
# edit paths if needed; UDID defaults to this XR
```

## Boot
```bash
./boot/lumina-boot.sh
```

This uses UDID `00008020-00117540340B002E` for the usbmux wait (not the
foreign hardcoded id from upstream `exploit.sh`).

## SSH again
```bash
./boot/lumina-ssh.sh
```

## Collect Phase A
```bash
./boot/lumina-ssh.sh 'bash -s' < boot/collect-ground-truth.sh | tee artifacts/xr-18.7.5/ground-truth.txt
```

Paste the output into `docs/STATUS.md`.
