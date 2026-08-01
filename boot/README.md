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

UDID resolution (`boot/lib-udid.sh`):

1. explicit `LUMINA_UDID` from env / `config.env`
2. else the single connected `idevice_id` device
3. else this XR: `00008020-00117540340B002E`

The foreign hsbugss sample UDID `00008020-000231A00EE9002E` is refused.

## SSH again
```bash
./boot/lumina-ssh.sh
```

## Collect Phase A
```bash
./boot/lumina-ssh.sh 'bash -s' < boot/collect-ground-truth.sh | tee artifacts/xr-18.7.5/ground-truth.txt
```

Paste the output into `docs/STATUS.md`.
