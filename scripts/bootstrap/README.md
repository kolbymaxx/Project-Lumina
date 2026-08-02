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

### Single source of truth: `env.sh`
`scripts/bootstrap/env.sh` is the **only** place `JBROOT` (and `STAGE`) are
defaulted:

```bash
export JBROOT="${JBROOT:-/mnt2/root/jb}"
export STAGE="${STAGE:-/mnt2/tmp/lumina-bootstrap}"
```

Every Mac-side script (`push_bootstrap.sh`, `verify_bootstrap.sh`,
`uninstall_bootstrap.sh`, `fix_exec.sh`) sources it directly. It is also staged
to the device alongside each `remote_*.sh` script, which source it from their
own directory (`$STAGE/env.sh`) so the default stays identical on both sides.
Override by exporting `JBROOT`/`STAGE` before invoking any wrapper — never
hardcode a package-root path in a script body.

**Forbidden package roots:** `/mnt2/jb` (new top-level under Data) and classic
`/var/jb` on disk. Stage package files only under `$JBROOT` or `$STAGE`
(`/mnt2/tmp/lumina-bootstrap`).

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

## Fix exec (Killed: 9) before using PATH
Procursus rootless binaries have `LC_RPATH=/var/jb/usr/lib`. On ICH, `/` is
APFS RO so `/var/jb` cannot be created in place; `mount_tmpfs` on `/private/var`
then `ln -s $JBROOT /var/jb` is a **session rpath shim only** (not a package
root). Binaries also need platform-style entitlements (`platform.plist`) via
ramdisk `ldid` (`-P -Cadhoc`).

```bash
./scripts/bootstrap/fix_exec.sh
# success: /mnt2/root/jb/usr/bin/dpkg --version prints a version (not Killed: 9)
```

Do **not** put `$JBROOT/usr/bin` first on `PATH` until that full-path test works.

`prep_bootstrap.sh` in the tarball hardcodes `/var/jb` and loops on `uialert`.
Use `prep_bootstrap.lumina.sh` (pushed by `fix_exec.sh`) instead.

## Verify
```bash
./scripts/bootstrap/verify_bootstrap.sh
# exit 0 = full bootstrap with dpkg; exit 2 = skeleton only
```

On device (system PATH only until dpkg runs):
```bash
export PATH=/usr/bin:/bin:/usr/sbin:/sbin
export JBROOT=/mnt2/root/jb
"$JBROOT/usr/bin/dpkg" --version
```

## Uninstall (Data only — no sealed-system damage)
```bash
./scripts/bootstrap/uninstall_bootstrap.sh
```
Removes only `/mnt2/root/jb` (or your `JBROOT`) and `/mnt2/tmp/lumina-bootstrap`.
Never touches `/mnt1`. Session `/var/jb` tmpfs mapping is ephemeral (ramdisk).

## Obtain a bootstrap tarball (host-side)
Pin a **documented Procursus iphoneos-arm64 rootless** bootstrap yourself; convert
to `.tar.gz` on the Mac if needed. Archives with top-level `var/jb/` or `usr/`
are both accepted by `remote_install.sh` (archive prefix only — contents are
merged into `$JBROOT`, never installed to host `/var/jb`).
