#!/bin/sh
# Compile gate: fails if Godot cannot import the project or parse a script.
#
#   tools/compile_check.sh [path-to-godot-4.3-binary]
#
# Godot must be 4.3.x. If no argument is given, $GODOT_BIN is used, then `godot`.
# A headless editor import is the only thing that actually compiles every .gd
# file, so it is what "checked clean" has to mean.
cd "$(dirname "$0")/.." || exit 1

GODOT="${1:-${GODOT_BIN:-godot}}"
if ! command -v "$GODOT" >/dev/null 2>&1 && [ ! -x "$GODOT" ]; then
	echo "compile_check: godot binary not found ($GODOT)" >&2
	exit 2
fi

LOG="$(mktemp)"
trap 'rm -f "$LOG"' EXIT

import_once() {
	"$GODOT" --headless --path . --editor --quit >"$LOG" 2>&1
}

import_once
STATUS=$?

# Godot 4.3 can segfault in the very first import of a large project (a
# worker-thread notification race, not a code error). When the engine dies
# without naming a script or asset, wipe the import cache and try once more.
if [ "$STATUS" -ne 0 ] && ! grep -q "SCRIPT ERROR" "$LOG" && ! grep -q "Error loading image" "$LOG"; then
	echo "compile_check: engine exited $STATUS with no code error — retrying once" >&2
	rm -rf .godot
	import_once
	STATUS=$?
fi

fail=0
if [ "$STATUS" -ne 0 ]; then
	echo "compile_check: godot exited $STATUS" >&2
	fail=1
fi

# Scripts that fail to parse, and assets Godot refuses to load (a WebP or PNG
# saved under a .jpg name does this), both mean the game cannot start.
if grep -q "SCRIPT ERROR" "$LOG"; then
	grep -A2 "SCRIPT ERROR" "$LOG" >&2
	fail=1
fi
if grep -q "Error loading image" "$LOG"; then
	grep -A1 "Error loading image" "$LOG" >&2
	fail=1
fi

if [ "$fail" -eq 0 ]; then
	echo "compile_check: clean"
else
	echo "compile_check: FAILED (full log below)" >&2
	cat "$LOG" >&2
fi
exit "$fail"
