# Minimal Data-volume bootstrap (ICH ramdisk / XR 18.7.5)

**Scope:** reversible staging under **`/mnt2` only**. Never install into sealed `/mnt1`.

Not a jailbreak. Does not enable Sileo by itself. Provides a Procursus-**shaped**
prefix on Data, pushed from the Mac (device has no `curl` / `dpkg` yet).

## Evidence mapping
| Ramdisk path | Role |
|--------------|------|
| `/` (`md0`) | RO ramdisk tools (`ldid`, `tar`) — ephemeral |
| `/mnt1` | Sealed System — **do not install** |
| `/mnt2` | Data (`protect`) — only install surface |

### Important Data restriction (measured)
Creating a **new top-level directory** under `/mnt2` (e.g. `/mnt2/jb`) allows
`mkdir` but **file creates fail** with `Operation not permitted`.

Writable for files (verified):
- `/mnt2/tmp/...`
- `/mnt2/root/...`
- `/mnt2/mobile/tmp/...`

Therefore default **`JBROOT=/mnt2/root/jb`** (not `/mnt2/jb`).

On a normal/JB boot that maps Data → `/private/var`, this is approximately
**`/var/root/jb`**, not classic `/var/jb`. Session tools must use `JBROOT`
explicitly; do not assume `/var/jb` exists in the ramdisk (ramdisk `/var` ≠ Data).

## Target layout
```text
/mnt2/root/jb/                     # JBROOT (default)
  .lumina_bootstrap                # marker
  .procursus_strapped              # if bootstrap ships it
  usr/bin  usr/sbin  usr/lib …
  Library/  etc/  var/
/mnt2/tmp/lumina-bootstrap/        # staging (tarball + remote_*.sh); wipe anytime
```

## Mac prerequisites
```bash
~/Projects/ICH_A12_plus_Ramdisk/tools/darwin/iproxy 2222 22
# Procursus iphoneos-arm64 rootless bootstrap as .tar or .tar.gz on the Mac
# (decompress .zst on Mac first — device has no zstd)
```

## Push + install
```bash
cd ~/Projects/lumina
# layout only:
./scripts/bootstrap/push_bootstrap.sh --skeleton
# full tarball:
export BOOTSTRAP_TAR=/path/to/bootstrap.tar.gz
./scripts/bootstrap/push_bootstrap.sh
# optional ad-hoc ldid on usr/bin after extract:
LUMINA_LDID=1 ./scripts/bootstrap/push_bootstrap.sh
```

**Noexec:** `/mnt2` rejects shebang exec. Wrappers run
`/bin/bash /mnt2/tmp/lumina-bootstrap/remote_*.sh`.

**No heredocs on device** (RO ramdisk breaks bash temp files).

## Verify
```bash
./scripts/bootstrap/verify_bootstrap.sh
# exit 0 = full bootstrap with dpkg; exit 2 = skeleton only
```

On device:
```bash
export JBROOT=/mnt2/root/jb
export PATH="$JBROOT/usr/bin:$JBROOT/usr/sbin:$PATH"
ls -la "$JBROOT"
cat "$JBROOT/.lumina_bootstrap"
# if dpkg present:
dpkg --version
```

## Uninstall (Data only — no sealed-system damage)
```bash
./scripts/bootstrap/uninstall_bootstrap.sh
```
Removes only `/mnt2/root/jb` (or your `JBROOT`) and `/mnt2/tmp/lumina-bootstrap`.
Never touches `/mnt1`.

## Obtain a bootstrap tarball (host-side)
Pin a **documented Procursus iphoneos-arm64 rootless** bootstrap yourself; convert
to `.tar.gz` on the Mac if needed. Archives with top-level `var/jb/` or `usr/`
are both accepted by `remote_install.sh`.
