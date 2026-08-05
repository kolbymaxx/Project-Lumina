# KRW backend attribution

No live kexploit backend is integrated yet.

When one is added, record:

| Field | Value |
|-------|-------|
| Project name | |
| Upstream URL | |
| Commit / tag | |
| License file path | `research/kexploit/<name>/LICENSE` (or vendored copy) |
| What we use | (e.g. PE only / KRW API only) |
| What we do **not** ship | (e.g. WebKit stages, spyware payload) |
| 22H311 viability note | link under `research/kexploit/viability/` |

Root `.gitignore` already ignores common study clones under `research/kexploit/`.  
Prefer submodule or documented clone instructions over dumping blobs into git.
