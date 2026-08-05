# kernelcache-ro — offline probe outputs (22H311)

Produced by [`../../../tools/probe_22h311_kernelcache.sh`](../../../tools/probe_22h311_kernelcache.sh).

| File | Probe |
|------|--------|
| `P1_file.txt` / `P1_otool_header.txt` | Mach-O / fileset header |
| `P2_fileset.txt` | Fileset / load-command names |
| `P3_identity.txt` | Darwin / 22H311 / T8020 strings |
| `P4_mitigations.txt` | PPL/PAC/AMFI/… string survey |
| `P5_sha256.txt` / `P5_ls.txt` | Hashes + sizes |
| `P6_watch_classes.txt` | Watch-class string survey (not a CVE claim) |
| `MISSING_PATHS.txt` | Written when inputs absent |

**2026-08-05 (cloud agent):** inputs missing — only `MISSING_PATHS.txt` present.  
No fabricated P1–P6 content. Run the script on the Mac after placing firmware files.
