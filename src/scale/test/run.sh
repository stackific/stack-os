#!/usr/bin/bash
# Tests stack-os-scale against fake /sys/class/drm trees (`task scale:test`).
# Each connector gets a 128-byte EDID that is zero except bytes 21-22 (the
# size in cm), a `modes` file and a `status`; the expected rules come from
# decision 04's table.
set -euo pipefail
here=$(cd "$(dirname "$0")" && pwd)
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

# connector <name> <width-cm> <height-cm> <mode> [status]
connector() {
  local dir="$tmp/drm/card1-$1"
  mkdir -p "$dir"
  head -c 128 /dev/zero >"$dir/edid"
  printf '%b' "\\x$(printf %02x "$2")\\x$(printf %02x "$3")" |
    dd of="$dir/edid" bs=1 seek=21 conv=notrunc status=none
  printf '%s\n' "$4" >"$dir/modes"
  printf '%s\n' "${5:-connected}" >"$dir/status"
}

connector eDP-1 29 18 2560x1600  # 13" laptop panel: 225 DPI, target 135
connector DP-1 60 34 3840x2160   # 27" 4K: 163 DPI, target 110
connector DP-2 53 30 1920x1080   # 24" 1080p: 92 DPI
connector Virtual-1 0 0 1280x800 # no size, as in most VMs
connector HDMI-A-1 60 34 3840x2160 disconnected

run() {
  STACK_OS_DRM="$tmp/drm" STACK_OS_SCALE_OVERRIDES="$tmp/overrides" \
    "$here/../stack-os-scale" "$tmp/monitors.conf"
  grep '^monitor_rule' "$tmp/monitors.conf" | LC_ALL=C sort
}

check() {
  if [[ $1 != "$2" ]]; then
    printf 'FAIL: %s\nexpected:\n%s\ngot:\n%s\n' "$3" "$2" "$1" >&2
    exit 1
  fi
  echo "ok: $3"
}

check "$(run)" "monitor_rule=name:^DP-1\$,scale:1.5
monitor_rule=name:^DP-2\$,scale:1
monitor_rule=name:^Virtual-1\$,scale:1
monitor_rule=name:^eDP-1\$,scale:2" "scale from physical size; disconnected skipped"

before=$(stat -c %Y.%i "$tmp/monitors.conf")
sleep 1
run >/dev/null
check "$(stat -c %Y.%i "$tmp/monitors.conf")" "$before" "unchanged rules leave the file alone"

echo "eDP-1 1.25" >"$tmp/overrides"
check "$(run | grep eDP-1)" 'monitor_rule=name:^eDP-1$,scale:1.25' "override wins"

printf 'eDP-1 1.25\neDP-1 1.5\nDP-1 auto\nDP-2 9\n' >"$tmp/overrides"
check "$(run | grep -E 'eDP-1|DP-1|DP-2')" "monitor_rule=name:^DP-1\$,scale:1.5
monitor_rule=name:^DP-2\$,scale:1
monitor_rule=name:^eDP-1\$,scale:1.5" "last override wins; invalid ones are ignored"
