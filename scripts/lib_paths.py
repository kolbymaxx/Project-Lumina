"""Locate project root and usbliter8ctl for lab scripts."""

from __future__ import annotations

import os
from datetime import datetime
from pathlib import Path

PWND_MARKER = "PWND:[usbliter8]"


def project_root() -> Path:
    return Path(__file__).resolve().parent.parent


def default_payload_dir() -> Path:
    env = os.environ.get("RAMDISK_ROOT") or os.environ.get("PAYLOAD_ROOT")
    if env:
        return Path(env) / "payload"
    # Mac: ~/Projects/...  Windows: %USERPROFILE%\Projects\...
    return Path.home() / "Projects" / "usbliter8-xr-ramdisk" / "payload"


def find_usbliter8ctl() -> Path:
    """
    Search order:
      USBLITER8CTL env
      <root>/host/usbliter8ctl
      <root>/usbliter8ctl
      <root>/../usbliter8/usbliter8ctl
      <root>/../usbliter8-jailbreak/host/usbliter8ctl
    """
    root = project_root()
    candidates = []
    env = os.environ.get("USBLITER8CTL")
    if env:
        candidates.append(Path(env))
    candidates.extend(
        [
            root / "host" / "usbliter8ctl",
            root / "usbliter8ctl",
            root.parent / "usbliter8" / "usbliter8ctl",
            root.parent / "usbliter8-jailbreak" / "host" / "usbliter8ctl",
        ]
    )
    for path in candidates:
        if path.is_file():
            return path.resolve()
    tried = "\n  ".join(str(p) for p in candidates)
    raise FileNotFoundError(
        "usbliter8ctl not found. Set USBLITER8CTL or place the tool at "
        "host/usbliter8ctl.\nTried:\n  {}".format(tried)
    )


def open_log(prefix: str) -> Path:
    logdir = project_root() / "logs"
    logdir.mkdir(parents=True, exist_ok=True)
    stamp = datetime.now().strftime("%Y%m%d-%H%M%S")
    return logdir / "{}-{}.log".format(prefix, stamp)


def logger(log_path: Path):
    def log(msg: str) -> None:
        print(msg, flush=True)
        with log_path.open("a", encoding="utf-8") as fh:
            fh.write(msg + "\n")

    return log
