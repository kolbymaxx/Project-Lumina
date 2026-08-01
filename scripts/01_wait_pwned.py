#!/usr/bin/env python3
"""Poll usbliter8ctl info until Pwned DFU (PWND:[usbliter8]) or timeout."""

from __future__ import annotations

import argparse
import subprocess
import sys
import time
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from lib_paths import PWND_MARKER, find_usbliter8ctl, logger, open_log  # noqa: E402


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--timeout", type=float, default=180.0, help="seconds (0=forever)")
    ap.add_argument("--interval", type=float, default=1.0)
    args = ap.parse_args()

    log_path = open_log("01_wait_pwned")
    log = logger(log_path)
    log("log: {}".format(log_path))
    log("platform: {}".format(sys.platform))

    try:
        ctl = find_usbliter8ctl()
    except FileNotFoundError as exc:
        log("FAIL: {}".format(exc))
        return 1

    py = sys.executable
    log("ctl: {}".format(ctl))
    log("polling: {} {} info  (want Pwned DFU + {})".format(py, ctl, PWND_MARKER))
    deadline = None if args.timeout <= 0 else time.time() + args.timeout

    while True:
        proc = subprocess.run(
            [py, str(ctl), "info"],
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            text=True,
        )
        out = (proc.stdout or "").rstrip()
        log("usbliter8ctl info rc={}\n{}".format(proc.returncode, out or "(no output)"))

        if proc.returncode == 0 and "Pwned DFU" in out and PWND_MARKER in out:
            log("OK: Pwned DFU ready")
            return 0

        if proc.returncode == 0 and "05ac:1227" in out and PWND_MARKER not in out:
            log("NOTE: DFU present but serial lacks PWND:[usbliter8] — re-run Pico pwn")

        if deadline is not None and time.time() >= deadline:
            log("FAIL: timed out after {}s — no Pwned DFU".format(args.timeout))
            log("hint: Pico-pwn, then connect phone DIRECTLY to host (not through Pico)")
            return 1

        time.sleep(args.interval)


if __name__ == "__main__":
    sys.exit(main())
