# Project-Lumina

## usbliter8ctl

`usbliter8ctl` is a `pyusb` host utility for an Apple device already placed
in Pwned DFU by usbliter8.

On macOS, use the Pico only for the race/pwn step. Disconnect the phone from
the Pico and connect it directly to the Mac before running `usbliter8ctl`.
Leaving the phone connected through the Pico can prevent the remote-boot path
from completing.

```sh
python3 -m pip install pyusb
python3 usbliter8ctl info
python3 usbliter8ctl demote
python3 usbliter8ctl boot iBoot_patched.raw
```

The macOS boot path deliberately:

- uses `wValue=0` and `wIndex=0` for every DFU request;
- terminates the download with an empty `DNLOAD` whose payload is `None`;
- polls `DFU_GETSTATUS` and logs each state until
  `MANIFEST_WAIT_RESET`;
- does not set a configuration or claim/release interface 0;
- waits up to two seconds for `CUSTOM_BOOT`;
- omits `DFU_ABORT` by default;
- issues the USB reset required by `MANIFEST_WAIT_RESET`;
- disposes the PyUSB handle before scanning for re-enumeration; and
- reports success only after finding Recovery (`05ac:1281`) or a new device
  identity.

`DFU_ABORT` is standard DFU request 6. Request 4 is `DFU_CLRSTATUS` and is not
used as an abort.

Use `--abort` to test `CUSTOM_BOOT` followed by the corrected `DFU_ABORT`
request, or `--no-abort` to omit the abort explicitly on any platform.
Use `--no-reset` to suppress the post-manifest USB reset:

```sh
python3 usbliter8ctl boot --no-abort iBoot_patched.raw
```

The alternative ordering requested for protocol diagnosis is also available:

```sh
python3 usbliter8ctl boot --boot-before-final-dnload iBoot_patched.raw
```
