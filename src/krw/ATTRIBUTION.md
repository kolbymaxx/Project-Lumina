# KRW / DS-K attribution

| Field | Value |
|-------|--------|
| Project | opa334/darksword-kexploit |
| Upstream URL | https://github.com/opa334/darksword-kexploit |
| Commit / tag | fill after `./scripts/clone_darksword_kexploit.sh` (example seen: `0ee563282e7235f8355ffc1fbf23ac6fd0f98040`) |
| License | **None published** — do not redistribute in this git repo |
| Local path | `third_party/darksword-kexploit/` (gitignored) |
| Lumina patch | `third_party/patches/darksword-library.patch` (FAILURE/longjmp + rename main) |
| What we use | Kernel PE / KRW path (**DS-K**) via `darksword_lib` + `krw_*` |
| What we do **not** ship | DS-Full WebKit stages, spyware payloads, upstream sources in git |

Secondary reference:

| Field | Value |
|-------|--------|
| Project | htimesnine/DarkSword-RCE |
| URL | https://github.com/htimesnine/DarkSword-RCE |
| License | **None published** |
| Role | Leak provenance / teacher |
