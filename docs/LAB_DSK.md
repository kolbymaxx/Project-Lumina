# Lab protocol — first on-device DS-K attempt

**Human runs this on device.** Cloud VM cannot.  
Track: **DS-K** only. No DS-Full pages. No fake success.

## Preconditions

- [ ] Entry choice recorded in STATUS (**E1** / **E2** / **E3** / **E4**)  
- [ ] Local clone of `opa334/darksword-kexploit` per `third_party/README.md`  
- [ ] Build identity known (`22H311` or vulnerable sandbed build)  
- [ ] Panic logging ready (Mac Console / sysdiagnose / photo of panic text)  
- [ ] Offsets: either rebuilt for target build **or** explicitly “upstream 15.x defaults” noted as risk  

## Steps

### 1) Deploy host

Using the chosen entry path, install either:

- upstream `darksword-pe` binary inside a minimal wrapper app, **or**  
- Lumina `src/host` once wired  

Record: signing method, bundle id, which entitlements actually embedded (`codesign -d --entitlements :-`).

### 2) Run DS-K init

From device (SSH via companion / app UI / attached debugger — whatever entry allows):

```text
# Example — adjust to how the host exposes logs:
# run darksword-pe or host "Run KRW" action
```

Capture **full stdout/stderr** and unified log snippets around the run.

### 3) Capture

| Artifact | Required |
|----------|----------|
| Return codes / exit status | yes |
| Printed slide / addresses (if any) | yes |
| syslog / oslog excerpt | yes |
| Panic string (if any) | yes |
| Device still boots to same build? | yes |

### 4) Classify (pick one)

`SUCCESS_KRW` / `FAIL_PATCHED` / `FAIL_OFFSETS` / `FAIL_ENTRY` / `FAIL_PANIC` / `UNKNOWN`

Guidance:

- Never launched / codesign / sandbox deny → `FAIL_ENTRY`  
- Immediate structured failure mentioning version/patch → lean `FAIL_PATCHED`  
- Far into race then inconsistent reads / wrong magic → lean `FAIL_OFFSETS`  
- Panic backtrace in VFS/cluster/IOSurface → `FAIL_PANIC` (still useful)  
- Stable kread matches expected kernel constant → `SUCCESS_KRW` only  

### 5) Update STATUS

Paste into STATUS lab result table: date, build, entry, result code, short notes, hypothesis **H1/H2/H3**.

**No spin.** literature already says patched — a clean `FAIL_PATCHED` is progress.

## Automatic branch on failure @ 22H311

If result is `FAIL_PATCHED` or `FAIL_OFFSETS` on **22H311**:

1. Keep the log (do not delete).  
2. Open / follow [BUILD_vulnerable_target.md](BUILD_vulnerable_target.md).  
3. Prefer a disposable **pre-18.7.2** 18.x device/build as the DS-K sandbed (**H3**).

## Session log template

```text
### DS-K session YYYY-MM-DD
- Device / build:
- Entry (E1–E4):
- Binary / commit:
- Entitlements observed:
- Action:
- Expected:
- Observed (stdout/log):
- Panic:
- Result code:
- Hypothesis supported:
- Next:
```

## Related

- [STATUS.md](STATUS.md)
- [ENTRY.md](ENTRY.md)
- [KRW.md](KRW.md)
- [DARKSWORD.md](DARKSWORD.md)
