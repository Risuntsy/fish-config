#!/usr/bin/env python3
"""Initialize a labwc --session command and expose its connection details by ID."""

import argparse
from contextlib import ExitStack, contextmanager
from enum import IntEnum
import errno
import json
import os
from pathlib import Path
import re
import signal
import socket
import subprocess
import sys
import tempfile
import time


class ExitCode(IntEnum):
    """Exit status:
      0  Success: help/lookup completed, or the session command exited successfully.
      1  Wrapper failure: duplicate/missing session, startup/I/O error, or labwc ended.
      2  Usage error: missing command/ID, invalid ID, or invalid command-line options.
      128 + signal  Terminated by a signal (HUP=129, INT=130, TERM=143).

    The session command's own exit code is returned unchanged. It can also be 1 or 2;
    those values alone do not distinguish a command failure from a wrapper failure.
    SIGNAL_BASE is an offset for signal statuses, not a standalone wrapper result.
    """

    SUCCESS = 0
    ERROR = 1
    USAGE_ERROR = 2
    SIGNAL_BASE = 128


class ArgumentParser(argparse.ArgumentParser):
    def error(self, message):
        self.print_usage(sys.stderr)
        self.exit(ExitCode.USAGE_ERROR, f"{self.prog}: error: {message}\n")


def session_id(value):
    if not re.fullmatch(r"[A-Za-z0-9_-]{1,128}", value):
        raise argparse.ArgumentTypeError(
            "session ID must be 1–128 letters, digits, underscores or hyphens"
        )
    return value


def runtime_dir():
    return Path(os.environ.get("XDG_RUNTIME_DIR") or tempfile.gettempdir())


def record_dir(identifier):
    return runtime_dir() / f"labwc-daily-sessions-{os.getuid()}" / identifier


@contextmanager
def reserve_session(identifier):
    """Claim the ID before startup; publish details only after initialization."""
    if identifier is None:
        yield None
        return

    directory = record_dir(identifier)
    directory.parent.mkdir(mode=0o700, parents=True, exist_ok=True)
    try:
        directory.mkdir(mode=0o700)
    except FileExistsError:
        raise RuntimeError(f"session ID {identifier} is already in use") from None
    try:
        yield directory
    finally:
        (directory / "info.json").unlink(missing_ok=True)
        (directory / "info.tmp").unlink(missing_ok=True)
        directory.rmdir()


def get_session(identifier):
    try:
        details = (record_dir(identifier) / "info.json").read_text()
    except FileNotFoundError:
        raise RuntimeError(
            f"session {identifier} does not exist or is not ready"
        ) from None
    print(details, end="")


def configure_output(auto_output):
    # The headless backend names its virtual monitor HEADLESS-1.
    output_name = "HEADLESS-1"
    if auto_output:
        result = subprocess.run(
            ["wlr-randr"], check=True, capture_output=True, text=True
        )
        outputs = result.stdout.split()
        if not outputs:
            raise RuntimeError("no output found")
        output_name = outputs[0]
    subprocess.run(
        ["wlr-randr", "--output", output_name, "--custom-mode", "1920x1080"], check=True
    )
    return output_name


def stop_process(process):
    if process.poll() is None:
        process.terminate()
        try:
            process.wait(timeout=5)
        except subprocess.TimeoutExpired:
            process.kill()
            process.wait()


def wait_for_command(process):
    # labwc can exit without terminating its session command.
    compositor_pid = os.environ.get("LABWC_PID")
    if not compositor_pid:
        return process.wait()

    compositor_pid = int(compositor_pid)
    while True:
        try:
            return process.wait(timeout=0.1)
        except subprocess.TimeoutExpired:
            try:
                os.kill(compositor_pid, 0)
            except ProcessLookupError:
                raise RuntimeError("labwc session ended") from None


def reserve_vnc_port():
    """Pass a bound socket to wayvnc so concurrent sessions cannot reuse its port."""
    listener = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    try:
        for port in range(5900, 65536):
            try:
                listener.bind(("127.0.0.1", port))
            except OSError as error:
                if error.errno == errno.EADDRINUSE:
                    continue
                raise
            listener.listen()
            return listener
        raise RuntimeError("no available VNC port")
    except BaseException:
        listener.close()
        raise


def start_wayvnc(stack, output_name):
    control_socket = runtime_dir() / f"labwc-daily-wayvnc-{os.getpid()}.ctl"
    stack.callback(control_socket.unlink, missing_ok=True)
    with reserve_vnc_port() as listener:
        port = listener.getsockname()[1]
        process = subprocess.Popen(
            [
                "wayvnc",
                f"--socket={control_socket}",
                "--output",
                output_name,
                f"fd:{listener.fileno()}",
            ],
            pass_fds=(listener.fileno(),),
        )
        stack.callback(stop_process, process)

    deadline = time.monotonic() + 5
    while time.monotonic() < deadline:
        if process.poll() is not None:
            raise RuntimeError("wayvnc exited during startup")
        if control_socket.exists():
            try:
                ready = subprocess.run(
                    ["wayvncctl", f"--socket={control_socket}", "version"],
                    stdout=subprocess.DEVNULL,
                    stderr=subprocess.DEVNULL,
                    timeout=0.5,
                )
                if ready.returncode == ExitCode.SUCCESS:
                    print(f"wayVNC listening on 127.0.0.1:{port}", file=sys.stderr)
                    return port
            except subprocess.TimeoutExpired:
                pass
        time.sleep(0.05)
    raise RuntimeError("wayvnc did not become ready within 5 seconds")


def run_session(args):
    display = os.environ.get("WAYLAND_DISPLAY")
    if not display:
        raise RuntimeError(
            "WAYLAND_DISPLAY is missing; run this command via labwc --session"
        )

    with ExitStack() as processes, reserve_session(args.session_id) as directory:
        output_name = configure_output(args.auto_output)
        port = None if args.disable_wayvnc else start_wayvnc(processes, output_name)
        if directory is not None:
            details = {"wayland_display": display, "vnc_port": port}
            temporary = directory / "info.tmp"
            temporary.write_text(json.dumps(details) + "\n")
            temporary.replace(directory / "info.json")

        process = subprocess.Popen(args.command)
        processes.callback(stop_process, process)
        status = wait_for_command(process)
        return status if status >= 0 else ExitCode.SIGNAL_BASE - status


def terminate(signum, _frame):
    # Ignore further termination signals while context managers clean up.
    for watched in (signal.SIGHUP, signal.SIGINT, signal.SIGTERM):
        signal.signal(watched, signal.SIG_IGN)
    raise SystemExit(ExitCode.SIGNAL_BASE + signum)


def main():
    help_options = {
        "epilog": ExitCode.__doc__,
        "formatter_class": argparse.RawDescriptionHelpFormatter,
    }
    parser = ArgumentParser(description=__doc__, **help_options)
    commands = parser.add_subparsers(dest="action", required=True)
    run = commands.add_parser("run", help="run inside labwc --session", **help_options)
    run.add_argument("--session-id", type=session_id)
    run.add_argument("--auto-output", action="store_true")
    run.add_argument("--disable-wayvnc", action="store_true")
    run.add_argument("command", nargs=argparse.REMAINDER)
    get = commands.add_parser(
        "get",
        help="print an active session's connection details as JSON",
        **help_options,
    )
    get.add_argument("session_id", type=session_id)
    args = parser.parse_args()

    if args.action == "run":
        if args.command[:1] == ["--"]:
            args.command.pop(0)
        if not args.command:
            run.error("a session command is required")
        for watched in (signal.SIGHUP, signal.SIGINT, signal.SIGTERM):
            signal.signal(watched, terminate)

    try:
        if args.action == "get":
            get_session(args.session_id)
            return ExitCode.SUCCESS
        return run_session(args)
    except (OSError, RuntimeError, subprocess.CalledProcessError) as error:
        print(f"labwc-daily-session: {error}", file=sys.stderr)
        return ExitCode.ERROR


if __name__ == "__main__":
    sys.exit(main())
