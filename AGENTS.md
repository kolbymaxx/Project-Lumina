# AGENTS.md

## Cursor Cloud specific instructions

Project Lumina is a **Mac + USB hardware** research repo (iPhone XR / A12, Pico 2, usbliter8). The cloud VM can verify host tooling and docs; it cannot run the live BootROM → ramdisk path without the phone + Pico.

### Scope defaults
- Day-to-day device work: local macOS Sequoia clone of this repo (Option C sync via `git push` / `git pull`).
- Cloud agents: layout/docs/scripts + Python/`usbliter8ctl` smoke checks only. Do **not** invent kexploit claims or wire anything under `research/` into `boot/`.

### Layout map (FILTER + STATUS)
| Intent | Path |
|--------|------|
| Live status (DS-K main line) | `docs/STATUS.md` |
| DarkSword dossier / lab protocol | `docs/DARKSWORD.md`, `docs/LAB_DSK.md`, `docs/ENTRY.md` |
| KRW harness + Lumina IPA host | `src/krw/`, `Lumina/`, `scripts/clone_darksword_kexploit.sh`, `third_party/README.md` |
| PPL (after KRW only) | `docs/PPL.md`, `research/ppl/` |
| Applicability filter / historical notes | `docs/RESEARCH.md` + `research/*` |
| Tethered boot helpers (out of scope for DS-K track) | `boot/`, `./usbliter8ctl` |

There is no separate `research/FILTER.md`; the filter is the applicability tables in `docs/RESEARCH.md`.

### Host tools
**macOS Sequoia (authoritative for device work):**
```bash
brew install libusb libirecovery libimobiledevice usbmuxd sshpass
python3 -m pip install pyusb
python3 -c "import usb; import usb.backend.libusb1 as b; print(usb.__version__, b.get_backend())"
idevice_id --version
irecovery -V
iproxy 2>&1 | head -1
```
No Zadig/WinUSB — use Mac libusb.

**Linux cloud VM (docs/tooling only):** `python3` + `pyusb`, `libusb-1.0`, `libimobiledevice-utils`, `irecovery`, `iproxy` (`libusbmuxd-tools`), `sshpass`. Device USB enumeration will usually be empty here.

### Upstream usbliter8
- Official URL `https://github.com/prdgmshift/usbliter8` currently **404** (org has 0 public repos).
- Setup clone (gitignored nested tree): see `upstream/README.md` → `upstream/usbliter8/`.
- Root `./usbliter8ctl` is the Lumina-enhanced Mac control tool; upstream’s copy is smaller/older. Prefer root for `boot/` flows.

### Standard commands (do not duplicate long-form docs)
- Boot/SSH wrappers + brew/pip prereqs: `boot/README.md`
- Project overview: `README.md`
- Smoke without a device:
  ```bash
  python3 usbliter8ctl -h
  python3 usbliter8ctl info   # expect: no DFU/Recovery device
  python3 tools/decode_t8020_handler.py
  ```
- Live XR path (Mac + hardware only): Pico-pwn → direct USB to Mac → `./boot/lumina-boot.sh` (needs `boot/config.env` from `boot/config.env.example` and `~/Projects/usbliter8-xr-ramdisk` with git LFS).

### Gotchas
- `boot/config.env` is gitignored; never commit UDID/local paths that diverge from `docs/STATUS.md`.
- Refuse the foreign hsbugss sample UDID `00008020-000231A00EE9002E` (enforced in `boot/lib-udid.sh`).
- After Pico pwn, connect the phone **directly** to the Mac — not through the Pico — before `usbliter8ctl` / `lumina-boot.sh`.
