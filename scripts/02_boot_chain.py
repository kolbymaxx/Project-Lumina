#!/usr/bin/env python3
"""
Boot chain via usbliter8ctl:

  info → (optional demote) → boot iBSS → wait 05ac:1281 → send iBEC

If usbliter8ctl send is unimplemented, Mac falls back to irecovery -f.
Windows: non-zero exit if send unimplemented and irecovery missing.
Does not boot the full ramdisk. Never claims Data mount.
"""

from __future__ import annotations

import argparse
import os
import shutil
import subprocess
import sys
import time
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from lib_paths import (  # noqa: E402
    PWND_MARKER,
    default_payload_dir,
    find_usbliter8ctl,
    logger,
    open_log,
)


def main() -> int:
    payload = default_payload_dir()
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument(
        "--ibss",
        type=Path,
        default=Path(os.environ.get("IBSS", str(payload / "iBSS.raw"))),
    )
    ap.add_argument(
        "--ibec",
        type=Path,
        default=Path(os.environ.get("IBEC", str(payload / "iBEC.raw"))),
        help="iBEC path (required unless --skip-ibec)",
    )
    ap.add_argument("--demote", action="store_true")
    ap.add_argument("--timeout", type=float, default=60.0)
    ap.add_argument("--skip-ibec", action="store_true", help="stop after Recovery")
    args = ap.parse_args()

    log_path = open_log("02_boot_chain")
    log = logger(log_path)
    py = sys.executable
    log("log: {}".format(log_path))
    log("platform: {}".format(sys.platform))

    try:
        ctl = find_usbliter8ctl()
    except FileNotFoundError as exc:
        log("FAIL: {}".format(exc))
        return 1

    log("ctl: {}".format(ctl))
    if not args.ibss.is_file():
        log("FAIL: missing iBSS {}".format(args.ibss))
        return 1

    def run_ctl(ctl_args, check=True) -> subprocess.CompletedProcess:
        cmd = [py, str(ctl)] + ctl_args
        log("### " + " ".join(cmd))
        proc = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
        if proc.stdout:
            log(proc.stdout.rstrip())
        log("rc={}".format(proc.returncode))
        if check and proc.returncode != 0:
            raise RuntimeError(
                "usbliter8ctl {} failed rc={}".format(ctl_args[0], proc.returncode)
            )
        return proc

    try:
        info = run_ctl(["info"], check=False)
        out = info.stdout or ""
        if info.returncode != 0 or "Pwned DFU" not in out or PWND_MARKER not in out:
            log("FAIL: need Pwned DFU (run scripts/01_wait_pwned.py)")
            return 1

        if args.demote:
            run_ctl(["demote"])
        else:
            log("skip demote (pass --demote to enable)")

        log("### {} {} boot {}".format(py, ctl, args.ibss))
        boot = subprocess.Popen(
            [py, str(ctl), "boot", str(args.ibss)],
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            text=True,
        )

        deadline = time.time() + args.timeout
        recovered = False
        while time.time() < deadline:
            probe = subprocess.run(
                [py, str(ctl), "info"],
                stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT,
                text=True,
            )
            pout = probe.stdout or ""
            if "05ac:1281" in pout or ("Recovery" in pout and "Pwned DFU" not in pout):
                recovered = True
                log("OK: Recovery via info:\n{}".format(pout.rstrip()))
                if boot.poll() is None:
                    boot.terminate()
                    try:
                        boot.wait(timeout=3)
                    except subprocess.TimeoutExpired:
                        boot.kill()
                break
            if boot.poll() is not None:
                bout, _ = boot.communicate()
                if bout:
                    log(bout.rstrip())
                log("boot process exited rc={}".format(boot.returncode))
                break
            time.sleep(0.5)

        if boot.poll() is None:
            boot.terminate()
            try:
                bout, _ = boot.communicate(timeout=3)
            except subprocess.TimeoutExpired:
                boot.kill()
                bout = ""
            if bout:
                log(bout.rstrip())

        if not recovered:
            log("### usbliter8ctl wait --pid 1281 (timeout {}s)".format(args.timeout))
            wait_proc = subprocess.Popen(
                [py, str(ctl), "wait", "--pid", "1281"],
                stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT,
                text=True,
            )
            wdeadline = time.time() + args.timeout
            while time.time() < wdeadline and wait_proc.poll() is None:
                time.sleep(0.25)
            if wait_proc.poll() is None:
                wait_proc.terminate()
                try:
                    wout, _ = wait_proc.communicate(timeout=2)
                except subprocess.TimeoutExpired:
                    wait_proc.kill()
                    wout = ""
                if wout:
                    log(wout.rstrip())
                log("FAIL: timed out waiting for 05ac:1281")
                return 1
            wout, _ = wait_proc.communicate()
            if wout:
                log(wout.rstrip())
            if wait_proc.returncode != 0:
                log("FAIL: wait rc={}".format(wait_proc.returncode))
                return 1
            recovered = True
            log("OK: wait found 05ac:1281")

        if args.skip_ibec:
            log("STOP after Recovery (--skip-ibec). Next: send iBEC / ramdisk chain.")
            return 0

        if not args.ibec.is_file():
            log("FAIL: missing iBEC {}".format(args.ibec))
            log("hint: pass --ibec PATH or --skip-ibec")
            return 1

        send = run_ctl(["send", str(args.ibec)], check=False)
        if send.returncode == 0:
            log("OK: usbliter8ctl send iBEC")
            return 0

        log("NOTE: usbliter8ctl send failed/unimplemented — trying irecovery -f (Mac path)")
        irecovery = shutil.which("irecovery")
        if not irecovery:
            log("FAIL: irecovery not on PATH")
            log("Mac: brew install libirecovery")
            log("Windows: install irecovery or implement usbliter8ctl send — aborting")
            return 1
        cmd = [irecovery, "-f", str(args.ibec)]
        log("### " + " ".join(cmd))
        proc = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
        if proc.stdout:
            log(proc.stdout.rstrip())
        log("irecovery rc={}".format(proc.returncode))
        if proc.returncode != 0:
            log("FAIL: irecovery -f iBEC failed")
            return 1
        log("OK: iBEC uploaded via irecovery -f")
        log("Next: irecovery -c go (if required) then ramdisk/firmware chain")
        return 0

    except RuntimeError as exc:
        log("FAIL: {}".format(exc))
        return 1


if __name__ == "__main__":
    sys.exit(main())
