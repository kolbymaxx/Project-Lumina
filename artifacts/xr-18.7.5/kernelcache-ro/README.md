# Offline kernelcache RO probes — 22H311 / A12

**Date:** 2026-08-05  
**Script:** `tools/probe_22h311_kernelcache.sh`  
**Inputs:** `/Users/kolby/Projects/firmware-22H311/kernelcache.{release.iphone11b,payload}`

| File | Probe |
|------|--------|
| `P1_file.txt` / `P1_otool_hv.txt` | Mach-O / FILESET header |
| `P2_fileset.txt` / `P2_fileset_names.txt` | Fileset load cmds + 224 `entry_id` names |
| `P3_identity.txt` | Darwin / XNU identity strings |
| `P4_mitigations.txt` | AMFI/PPL/PAC/sandbox/… string sample |
| `P5_sha256.txt` | SHA-256 + sizes |
| `P6_watch_surface.txt` | copyin/out / OOB / IOUserClient sample |
| `P6b_targeted_watch.txt` | PPL/PAC/LC/TC + auth/copyin sample |

Presence-only mapping. **No claim that any CVE is working on this device.**
