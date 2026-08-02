# B005 — Build-time TC append of `dpkg` CDHash (**next DFU**)

## Claim / hypothesis
Stock or build-time trustcache membership is why bash lives and `dpkg` dies.
Putting **dpkg’s CDHash** into `trustcache.img4` (via Mac `build.sh` / TC tool),
then **rebuild → re-pwn → boot**, is **necessary** (maybe not sufficient) for
`/var/jb/usr/bin/dpkg --version` to survive AMFI.

## Falsifier
After rebuild + boot, `dpkg --version` still exits **137** → post-TC gate
(launch constraints / CSM / other) still wins even with membership.

## Needs
- Mac: `build.sh` / trustcache tool that can append a CDHash into the payload TC
- Full re-pwn (not live-only sysctl games)
- One controlled exec: `/var/jb/usr/bin/dpkg --version` (or exact staged path)

## Lab test?
- [ ] No (docs only)
- [x] Yes — DFU session per [../DFU_SESSION_TC_APPEND.md](../DFU_SESSION_TC_APPEND.md)

## Experiment steps
1. On Mac: compute CDHash of the **exact** dpkg binary that will be on-device.
2. Append that hash to the build trustcache; rebuild `trustcache.img4` (+ any
   dependent payloads).
3. DFU → usbliter8 → known-good boot chain with the new TC.
4. Remap/stage `/var/jb` as before (B001-safe).
5. Run **one** `dpkg --version`. Record exit code + any AMFI/CS logs available.
6. Fill Result below. Do **not** mass-fakesign (B000).

## Result
- [ ] Supported (hypothesis: TC membership was the missing piece — dpkg runs)
- [ ] Contradicted (still 137 → post-TC; go to B006)
- [x] Unknown

## Status impact
Highest-signal falsifier for “TC membership vs post-TC gate.”  
Does **not** by itself claim Sileo / jailbreak.
