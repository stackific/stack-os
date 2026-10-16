#!/usr/bin/env python3
"""Boot test for the Stack OS disk (001-07), run inside the VM container.

Boots /output/qcow2/disk.qcow2 on a snapshot (the disk never changes) with
KVM and UEFI firmware (OVMF code plus a scratch copy of its variable store),
a serial console and a QEMU monitor on Unix sockets. Then:

1. waits for the login prompt on the serial console (systemd starts a getty
   there because the disk's kernel console includes ttyS0);
2. logs in as the test user and checks what only a booted system shows:
   Btrfs on /sysroot and zram as the only swap (the package checks are
   `task image:check`'s job);
3. types the same login into tuigreet on the graphical console with the
   monitor's `sendkey`, waits on the serial console until the user's
   stack-os-shell.service is active and Mango runs, and saves a screendump
   of the session to /output/screenshots/vm-session.png.

Exits non-zero on the first failed check, or as soon as QEMU stops.

With --interactive it boots the same machine with a VNC display on port 5900
and the serial console on stdio instead (`task vm:run`).
"""
import os
import shutil
import socket
import subprocess
import sys
import time

DISK = "/output/qcow2/disk.qcow2"
SHOT = "/output/screenshots/vm-session.png"
SERIAL = "/tmp/serial.sock"
MONITOR = "/tmp/monitor.sock"
OVMF = "/usr/share/edk2/ovmf"
VARS = "/tmp/OVMF_VARS.fd"
USER, PASSWORD = "test", "test"

qemu = None


def machine():
  """The QEMU command line shared by the test and `task vm:run`."""
  shutil.copy(f"{OVMF}/OVMF_VARS.fd", VARS)
  return [
    "qemu-system-x86_64", "-machine", "q35", "-enable-kvm", "-cpu", "host",
    "-m", "4096", "-smp", "4",
    "-drive", f"if=pflash,format=raw,readonly=on,file={OVMF}/OVMF_CODE.fd",
    "-drive", f"if=pflash,format=raw,file={VARS}",
    "-drive", f"file={DISK},if=virtio,snapshot=on",
    "-device", "virtio-vga",
  ]


def alive():
  """Fails the test at once if QEMU has stopped."""
  if qemu.poll() is not None:
    sys.exit(f"\nFAIL: QEMU exited with status {qemu.returncode}")


def connect(path, timeout=60):
  """Connects to one of QEMU's Unix sockets once it exists."""
  deadline = time.time() + timeout
  while time.time() < deadline:
    alive()
    try:
      s = socket.socket(socket.AF_UNIX)
      s.connect(path)
      return s
    except OSError:
      time.sleep(0.5)
  sys.exit(f"FAIL: QEMU socket {path} never appeared")


class Serial:
  """The VM's serial console: send lines, wait for text."""

  def __init__(self, sock):
    self.sock = sock
    self.sock.settimeout(1)
    self.seen = ""

  def wait(self, text, timeout):
    """Reads until text appears; returns what came before it."""
    deadline = time.time() + timeout
    while time.time() < deadline:
      if text in self.seen:
        before, self.seen = self.seen.split(text, 1)
        return before
      alive()
      try:
        data = self.sock.recv(4096).decode(errors="replace")
      except socket.timeout:
        continue
      sys.stdout.write(data)
      sys.stdout.flush()
      self.seen += data
    sys.exit(f"\nFAIL: no {text!r} within {timeout}s")

  def send(self, line):
    """Sends one line, as if typed and followed by Enter."""
    self.sock.sendall((line + "\n").encode())

  def run(self, command, timeout=30):
    """Runs a shell command and returns its output. The markers are split
    with quotes in the sent line, so the echoed command line never matches
    them; only the shell's output does."""
    self.send(f"echo @@B''EGIN; {command}; echo @@E''ND")
    self.wait("@@BEGIN", timeout)
    return self.wait("@@END", timeout).replace("\r", "").strip()

  def until(self, command, expected, timeout):
    """Reruns a command until it prints the expected output."""
    deadline = time.time() + timeout
    while time.time() < deadline:
      if self.run(command) == expected:
        return
      time.sleep(2)
    sys.exit(f"\nFAIL: {command!r} never printed {expected!r} within {timeout}s")


def monitor(sock, command):
  """Sends one human-monitor command to QEMU."""
  sock.sendall((command + "\n").encode())
  time.sleep(0.2)


def type_text(sock, text):
  """Types lowercase text into the graphical console, one key at a time."""
  for ch in text:
    monitor(sock, f"sendkey {ch}")


CHECKS = {
  "btrfs root": ("findmnt -no FSTYPE /sysroot", lambda o: o == "btrfs"),
  "zram only swap": ("swapon --show=NAME --noheadings", lambda o: o.split() == ["/dev/zram0"]),
}


def test():
  """The boot test; see the module docstring."""
  global qemu
  os.makedirs(os.path.dirname(SHOT), exist_ok=True)
  qemu = subprocess.Popen(machine() + [
    "-display", "none",
    "-serial", f"unix:{SERIAL},server,nowait",
    "-monitor", f"unix:{MONITOR},server,nowait",
  ])
  try:
    serial = Serial(connect(SERIAL))
    mon = connect(MONITOR)

    serial.wait("login:", 300)
    serial.send(USER)
    serial.wait("assword:", 30)
    serial.send(PASSWORD)
    serial.wait("$ ", 60)
    for name, (command, ok) in CHECKS.items():
      output = serial.run(command)
      if not ok(output):
        sys.exit(f"\nFAIL: {name}: {output!r}")
      print(f"\nok: {name}")

    # tuigreet on the graphical console: user, password, then the session.
    serial.until("systemctl is-active greetd.service", "active", 60)
    time.sleep(2)  # tuigreet draws after greetd starts it
    type_text(mon, USER)
    monitor(mon, "sendkey ret")
    time.sleep(2)
    type_text(mon, PASSWORD)
    monitor(mon, "sendkey ret")
    serial.until("pgrep -xc mango", "1", 90)
    serial.until("systemctl --user is-active stack-os-shell.service", "active", 60)
    print("\nok: Mango and the shell service are running")
    time.sleep(3)  # let the bar draw its first frame
    monitor(mon, f"screendump {SHOT} -f png")
    time.sleep(2)
    if not os.path.exists(SHOT) or not os.path.getsize(SHOT):
      sys.exit("FAIL: no session screenshot")
    print(f"ok: session screenshot {SHOT}")
  finally:
    qemu.terminate()
    try:
      qemu.wait(timeout=30)
    except subprocess.TimeoutExpired:
      qemu.kill()


if __name__ == "__main__":
  if sys.argv[1:] == ["--interactive"]:
    os.execvp("qemu-system-x86_64", machine() + ["-display", "vnc=0.0.0.0:0", "-serial", "mon:stdio"])
  test()
