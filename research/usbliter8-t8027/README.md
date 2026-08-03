# t8027 (A12X) usbliter8 stubs

**Not wired into `boot/`.** SecureROM pwn on A12X is **not implemented**.

Bring-up memo (identity fields, full t8020 constant inventory, USB-C note, checklist):

→ [docs/research/usbliter8-t8027-bringup.md](../../docs/research/usbliter8-t8027-bringup.md)

Offset derivation plan (next research phase — no invented addresses):

→ [OFFSET_DERIVATION.md](OFFSET_DERIVATION.md)

SecureROM acquisition notes (where to seek `4172.0.0.100.14`, verify, feed stubs):

→ [SECUREROM_ACQUISITION.md](SECUREROM_ACQUISITION.md)

Symbolization worksheet (t8020 baseline + empty t8027 candidate tables):

→ [SYMBOL_WORKSHEET.md](SYMBOL_WORKSHEET.md)

First RE pass (strings, SRAM/PAC findings, ranked targets):

→ [FIRST_RE_PASS.md](FIRST_RE_PASS.md)

PAC + control-flow problem (why t8020 ROP assumptions fail; analysis plan):

→ [PAC_AND_CONTROL_FLOW.md](PAC_AND_CONTROL_FLOW.md)

Local ROM blobs (gitignored): `artifacts/*.bin` — never commit.

## What this directory is

Empty **TODO-offset stubs** mirroring the upstream usbliter8 per-target layout for CPID `0x8027` / t8027. Closest implemented tree is t8020.

`upstream/usbliter8/` is gitignored. When filling offsets from a real t8027 SecureROM map:

1. Clone upstream per [upstream/README.md](../../upstream/README.md).
2. Copy `stubs/t8020_t8006_shellcode/targets/t8027/` → `upstream/usbliter8/t8020_t8006_shellcode/targets/t8027/`.
3. Copy `stubs/usb_req_handler/targets/t8027/` → `upstream/usbliter8/usb_req_handler/targets/t8027/`.
4. Use `stubs/exploit_cpid_switch.snippet.c` and `stubs/t8027_config.snippet.c` as templates inside local `exploit.c` — only after offsets are real.
5. Regenerate `resources/{shellcode,handler}_t8027.h`; hand-author descriptors — **do not invent** binary blobs here.

## Rules

- No invented `0x…` addresses in these stubs.
- Do not add `resources/*_t8027.h` until offsets are filled and built.
- Do not commit the nested `upstream/usbliter8/` clone.
