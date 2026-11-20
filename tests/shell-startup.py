#!/usr/bin/env python3
"""Measure interactive readiness in a PTY, after rc files, without installing tools."""
import errno
import json
import os
import pty
import select
import signal
import time


def measure(shell):
    start = time.perf_counter()
    pid, fd = pty.fork()
    if pid == 0:
        os.execvp(shell, [shell, "-i"])
    # The literal marker is constructed only in the child; input echo cannot
    # prematurely satisfy the readiness check.
    os.write(fd, b"printf '\\036DOTFILES_READY\\037'; exit\n")
    data = b""
    reaped = False
    deadline = start + 30
    try:
        while time.perf_counter() < deadline:
            if select.select([fd], [], [], 0.2)[0]:
                try:
                    chunk = os.read(fd, 65536)
                except OSError as exc:
                    if exc.errno == errno.EIO:
                        break
                    raise
                if not chunk:
                    break
                data += chunk
                if b"\x1eDOTFILES_READY\x1f" in data:
                    elapsed = (time.perf_counter() - start) * 1000
                    os.waitpid(pid, 0)
                    reaped = True
                    return round(elapsed, 2)
        raise RuntimeError(f"{shell}: interactive readiness marker missing")
    finally:
        os.close(fd)
        if not reaped:
            try:
                os.kill(pid, signal.SIGKILL)
            except ProcessLookupError:
                pass
            os.waitpid(pid, 0)


for executable in ("bash", "zsh"):
    samples = [measure(executable) for _ in range(6)]
    print(json.dumps({"shell": executable, "first_ms": samples[0],
                      "warm_ms": samples[1:], "scope": "PTY interactive-ready, not GUI prompt paint"}))
