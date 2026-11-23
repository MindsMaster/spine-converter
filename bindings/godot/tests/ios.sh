#!/usr/bin/env bash
# Runs a test app of export_ios.sh in the booted simulator
# Usage: bindings/godot/tests/ios.sh <app>
set -euo pipefail
app=${1:?usage: ios.sh <app>}
bundle=cc.azuramc.spineconverter.test
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

xcrun simctl uninstall booted "$bundle" >/dev/null 2>&1 || true
xcrun simctl install booted "$app"
# newer Godot prints to the unified log only
xcrun simctl spawn booted log stream --level info --style compact --predicate "subsystem == \"$bundle\"" >"$work/log" 2>&1 &
stream=$!
xcrun simctl launch --console-pty booted "$bundle" >"$work/console" 2>&1 &
for _ in $(seq 120); do
	if grep -q "spine-converter godot test: " "$work/console" "$work/log"; then break; fi
	sleep 1
done
xcrun simctl terminate booted "$bundle" >/dev/null 2>&1 || true
kill "$stream"
wait || true
xcrun simctl uninstall booted "$bundle" >/dev/null 2>&1 || true
cat "$work/console" "$work/log"
grep -q "spine-converter godot test: passed" "$work/console" "$work/log"
