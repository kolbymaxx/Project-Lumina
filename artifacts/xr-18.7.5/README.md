# XR 18.7.5 (22H311) artifacts

Empty staging area for Phase A dumps from the live iPhone XR ramdisk.

Suggested layout after collection:

```text
artifacts/xr-18.7.5/
  boot-logs/                 # created by boot/lumina-boot.sh
  uname.txt
  SystemVersion.plist
  mount.txt
  disks.txt
  kernelcache/               # pulled or IPSW-extracted kernel
  notes.md
```

Do not commit large binaries or personal device dumps unless intentionally
scrubbed. Prefer gitignored local copies; keep STATUS.md paste summaries.
