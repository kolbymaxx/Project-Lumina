#!/usr/bin/env python3
"""Partial-ZIP fetch of iPhone11,8 18.7.5 (22H311) kernelcache from Apple CDN.

Docs / RO corpus only. Does not download the full ~8GB IPSW.
Not a kexploit. Not wired into boot/.
"""
from __future__ import annotations

import argparse
import hashlib
import struct
import sys
import urllib.request
import zlib
from pathlib import Path

DEFAULT_URL = (
    "https://updates.cdn-apple.com/2026WinterFCS/fullrestores/"
    "047-53269/25427FD8-2F38-4E14-88D6-AA5BA5FE340B/"
    "iPhone11,8_18.7.5_22H311_Restore.ipsw"
)
TARGET_NAME = "kernelcache.release.iphone11b"


def http_range(url: str, start: int, end: int) -> bytes:
    req = urllib.request.Request(url, headers={"Range": f"bytes={start}-{end}"})
    with urllib.request.urlopen(req, timeout=600) as resp:
        return resp.read()


def content_length(url: str) -> int:
    req = urllib.request.Request(url, method="HEAD")
    with urllib.request.urlopen(req, timeout=60) as resp:
        return int(resp.headers["Content-Length"])


def find_cd(url: str, size: int) -> tuple[int, int]:
    tail_start = max(0, size - 1024 * 1024)
    tail = http_range(url, tail_start, size - 1)
    loc = tail.rfind(b"PK\x06\x07")
    if loc < 0:
        raise RuntimeError("ZIP64 locator not found")
    eocd_off = struct.unpack_from("<Q", tail, loc + 8)[0]
    eocd = http_range(url, eocd_off, eocd_off + 128)
    if eocd[:4] != b"PK\x06\x06":
        raise RuntimeError("ZIP64 EOCD missing")
    cd_size = struct.unpack_from("<Q", eocd, 40)[0]
    cd_off = struct.unpack_from("<Q", eocd, 48)[0]
    return cd_off, cd_size


def parse_cd_for_target(cd: bytes, name: str):
    pos = 0
    while pos + 46 <= len(cd) and cd[pos : pos + 4] == b"PK\x01\x02":
        comp_size, uncomp_size = struct.unpack_from("<II", cd, pos + 20)
        name_len, extra_len, comment_len = struct.unpack_from("<HHH", cd, pos + 28)
        local_hdr = struct.unpack_from("<I", cd, pos + 42)[0]
        method = struct.unpack_from("<H", cd, pos + 10)[0]
        entry_name = cd[pos + 46 : pos + 46 + name_len].decode("utf-8", "replace")
        extra = cd[pos + 46 + name_len : pos + 46 + name_len + extra_len]
        if (
            comp_size == 0xFFFFFFFF
            or uncomp_size == 0xFFFFFFFF
            or local_hdr == 0xFFFFFFFF
        ):
            epos = 0
            while epos + 4 <= len(extra):
                eid, elen = struct.unpack_from("<HH", extra, epos)
                edata = extra[epos + 4 : epos + 4 + elen]
                off = 0
                if eid == 1:
                    if uncomp_size == 0xFFFFFFFF:
                        uncomp_size = struct.unpack_from("<Q", edata, off)[0]
                        off += 8
                    if comp_size == 0xFFFFFFFF:
                        comp_size = struct.unpack_from("<Q", edata, off)[0]
                        off += 8
                    if local_hdr == 0xFFFFFFFF:
                        local_hdr = struct.unpack_from("<Q", edata, off)[0]
                epos += 4 + elen
        if entry_name == name:
            return local_hdr, method, comp_size, uncomp_size
        pos += 46 + name_len + extra_len + comment_len
    raise RuntimeError(f"{name} not found in central directory")


def extract_member(url: str, local_off: int, method: int, comp_size: int) -> bytes:
    lh = http_range(url, local_off, local_off + 256)
    if lh[:4] != b"PK\x03\x04":
        raise RuntimeError("local header missing")
    name_len, extra_len = struct.unpack_from("<HH", lh, 26)
    data_start = local_off + 30 + name_len + extra_len
    blob = http_range(url, data_start, data_start + comp_size - 1)
    if len(blob) != comp_size:
        raise RuntimeError("short read")
    if method == 0:
        return blob
    if method == 8:
        return zlib.decompress(blob, -zlib.MAX_WBITS)
    raise RuntimeError(f"unsupported compression method {method}")


def sha256_file(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as f:
        for chunk in iter(lambda: f.read(1024 * 1024), b""):
            h.update(chunk)
    return h.hexdigest()


def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--url", default=DEFAULT_URL)
    ap.add_argument(
        "--out-dir",
        type=Path,
        default=Path("artifacts/xr-18.7.5/firmware-22H311"),
    )
    ap.add_argument("--extract-payload", action="store_true",
                    help="also run pyimg4 to write kernelcache.payload")
    args = ap.parse_args(argv)

    args.out_dir.mkdir(parents=True, exist_ok=True)
    im4p = args.out_dir / TARGET_NAME

    print(f"HEAD {args.url}", flush=True)
    size = content_length(args.url)
    print(f"IPSW size={size}", flush=True)
    cd_off, cd_size = find_cd(args.url, size)
    cd = http_range(args.url, cd_off, cd_off + cd_size - 1)
    local_off, method, comp_size, uncomp_size = parse_cd_for_target(cd, TARGET_NAME)
    print(
        f"found {TARGET_NAME} method={method} comp={comp_size} uncomp={uncomp_size}",
        flush=True,
    )
    data = extract_member(args.url, local_off, method, comp_size)
    im4p.write_bytes(data)
    print(f"wrote {im4p} sha256={sha256_file(im4p)} size={im4p.stat().st_size}")

    if args.extract_payload:
        payload = args.out_dir / "kernelcache.payload"
        import subprocess

        subprocess.check_call(
            [
                sys.executable,
                "-m",
                "pyimg4",
                "im4p",
                "extract",
                "-i",
                str(im4p),
                "-o",
                str(payload),
            ]
        )
        print(
            f"wrote {payload} sha256={sha256_file(payload)} size={payload.stat().st_size}"
        )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
