# PROJECT_STATUS — usbliter8 lab automation

**Lab package SoT.** Device inventory twin: [`docs/STATUS.md`](docs/STATUS.md).  
**Not a jailbreak.** No Sileo / full-JB claim on 18.7.5.

## Device
| Field | Value |
|-------|-------|
| Device | iPhone XR (n841ap) |
| SoC | A12 / CPID 8020 |
| NAND iOS | **18.7.5 (22H311)** |
| Entry | Pico usbliter8 → Pwned DFU `05ac:1227` `PWND:[usbliter8]` |
| Lab state | Intentionally erased (no passcode) — empty user Data expected |

## Current (measured) — Mac / ICH path **WORKS**
- Boot+SSH: `~/Projects/ICH_A12_plus_Ramdisk` → `n841ap-18.7.5-22H311-ramdisk`
  - `with_fw`, `kpf_set=ios18`, direct **iBEC** → Recovery → `bootx`
- SSH: `tools/darwin/iproxy 2222 22` + `sshpass -p alpine ssh -p 2222 root@127.0.0.1`
- `mount_ich` → System **`/mnt1`**, Data **`/mnt2`** (empty after erase — expected)
- Prefer Mac/ICH. Windows `usbliter8ctl` iBSS→go **abandoned** for ramdisk use

## Historical / closed negatives
- **15.1** hsbugss ramdisk: Data exit **76**; no DYLD hacks
- Windows: iBEC upload OK but `go` never jumped (stayed `05ac:1281`, no new SRTG)

## Blocked
1. No A12 / 18.7.5 **kexploit** / Sileo bootstrap yet
2. Tethered only — unplug = re-pwn + ICH `boot.sh`

## Next
1. Data-only bootstrap staging: [`scripts/bootstrap/`](scripts/bootstrap/) (`JBROOT=/mnt2/root/jb`, Mac push)
2. Agent ops: [`LAB_AGENT_RULES.md`](LAB_AGENT_RULES.md)
3. Lumina `scripts/01`–`05` remain for host DFU helpers; **live boot = ICH `boot.sh`**

## Explicit non-goals
- Reviving Windows iBEC-go for current ramdisk sessions
- DYLD hacks on 15.1 Data
- Claiming a full jailbreak

## Reconnect
```bash
~/Projects/ICH_A12_plus_Ramdisk/tools/darwin/iproxy 2222 22
sshpass -p alpine ssh -p 2222 root@127.0.0.1
# mount_ich
```

## Host paths
| Role | Mac |
|------|-----|
| Lumina | `~/Projects/lumina` |
| ICH ramdisk | `~/Projects/ICH_A12_plus_Ramdisk` |
| Bootchain | `…/bootchain/n841ap-18.7.5-22H311-ramdisk` |
