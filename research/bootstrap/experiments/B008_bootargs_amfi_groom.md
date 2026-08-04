# B008 — Boot-args AMFI groom (new boot)

## Claim / hypothesis
Adding `amfi_get_out_of_my_way=1` (and/or ICH-supported equivalents such as
`pmap_cs_allow_any_signature=1`) changes the `dpkg` kill behavior.

## Falsifier
Still exit **137** with those args present in `kern.bootargs`.

## Context
Local session live args were: `rd=md0 -v debug=0x2014e` only.  
Repo default in [`boot/lumina-boot.sh`](../../../boot/lumina-boot.sh) already
lists AMFI-related args — **not** proven on the live hsbugss/ICH chain used in
that session. This card requires a **new boot**, not a hot sysctl.

## Lab test?
- [ ] No (docs only)
- [x] Yes — rebuild/boot policy change + re-pwn

## Experiment steps
1. Set bootargs for the chain actually used (document exact string).
2. Full re-pwn → SSH.
3. Confirm `sysctl kern.bootargs` (or equivalent) shows the new args.
4. Remap if needed; one `dpkg --version`; record exit.
5. Fill Result. Keep B005 as the primary TC falsifier — bootargs are secondary.

## Result
- [ ] Supported (args change kill / allow exec)
- [ ] Contradicted (still 137 with args present)
- [x] Unknown

## Status impact
Policy experiment only. Does not replace TC membership test (B005).
