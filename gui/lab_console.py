#!/usr/bin/env python3
"""Optional lab console: buttons shell out to scripts and show stdout."""

from __future__ import annotations

import subprocess
import sys
import threading
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SCRIPTS = ROOT / "scripts"


def main() -> int:
    try:
        import tkinter as tk
        from tkinter import scrolledtext
    except ImportError:
        print(
            "FAIL: tkinter not available — run scripts from the terminal",
            file=sys.stderr,
        )
        return 1

    win = tk.Tk()
    win.title("usbliter8 lab console")
    win.geometry("780x520")

    text = scrolledtext.ScrolledText(win, wrap=tk.WORD, font=("Menlo", 11))
    text.pack(fill=tk.BOTH, expand=True, padx=8, pady=8)

    def append(msg: str) -> None:
        text.insert(tk.END, msg)
        text.see(tk.END)

    def run_cmd(argv) -> None:
        def worker() -> None:
            append("\n$ {}\n".format(" ".join(str(a) for a in argv)))
            try:
                proc = subprocess.Popen(
                    argv,
                    cwd=str(ROOT),
                    stdout=subprocess.PIPE,
                    stderr=subprocess.STDOUT,
                    text=True,
                )
                assert proc.stdout is not None
                for line in proc.stdout:
                    append(line)
                rc = proc.wait()
                append("[exit {}]\n".format(rc))
            except Exception as exc:  # show in GUI
                append("FAIL: {}\n".format(exc))

        threading.Thread(target=worker, daemon=True).start()

    bar = tk.Frame(win)
    bar.pack(fill=tk.X, padx=8, pady=4)

    actions = [
        ("DFU checklist", ["bash", str(SCRIPTS / "00_check_env.sh")]),
        ("Wait for PWND", [sys.executable, str(SCRIPTS / "01_wait_pwned.py")]),
        (
            "Run boot chain",
            [sys.executable, str(SCRIPTS / "02_boot_chain.py"), "--skip-ibec"],
        ),
        ("Ramdisk report", ["bash", str(SCRIPTS / "03_ramdisk_ssh.sh")]),
    ]

    for label, argv in actions:
        tk.Button(bar, text=label, command=lambda a=argv: run_cmd(a)).pack(
            side=tk.LEFT, padx=4
        )

    append("usbliter8 lab console\nROOT={}\n".format(ROOT))
    append("Mac preferred. Windows: missing tools fail in the log pane.\n")
    append("Data mount on 15.1 is NOT assumed (expect exit 76).\n")

    win.mainloop()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
