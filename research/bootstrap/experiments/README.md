# Bootstrap experiment cards

AMFI / trustcache / `/var/jb` staging on the tethered ramdisk.  
Template shape mirrors kexploit cards: Claim → Result → Status impact.

| ID | Theme | Result |
|----|-------|--------|
| B000 | Single fakesign bash copy | **Fatal** — skip unless new chain |
| B001 | `/var/jb` tmpfs remap kills SSH? | **Supported: No** (PHASE1_OK) |
| B002 | Remap alone → dpkg runs? | **Supported: No** (still 137) |
| B003 | Missing platform ents vs bash? | **Supported: No** (same ents, different CDHash) |
| B004 | `num_loadable` secret slot? | **Supported: No** (stays 0) |
| B005 | Build-time TC append of dpkg CDHash | **Open** — next DFU |
| B006 | AMFI TC stub actually hits? | **Open** — after B005 |
| B007 | Live CS counters / ldid evidence | **Open** — cheap, non-clearing |
| B008 | Boot-args AMFI groom | **Open** — new boot |

Index: [../README.md](../README.md)  
Next DFU: [../DFU_SESSION_TC_APPEND.md](../DFU_SESSION_TC_APPEND.md)
