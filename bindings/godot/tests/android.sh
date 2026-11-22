#!/usr/bin/env bash
# Runs a test APK of export_android.sh on the device adb reaches
# Usage: bindings/godot/tests/android.sh <apk>
set -euo pipefail
apk=${1:?usage: android.sh <apk>}
package=cc.azuramc.spineconverter.test

adb uninstall "$package" >/dev/null 2>&1 || true
adb install "$apk"
adb logcat -c
adb shell monkey -p "$package" -c android.intent.category.LAUNCHER 1 >/dev/null
log=
for _ in $(seq 120); do
	log=$(adb logcat -d -s godot | tr -d '\r')
	if grep -q "spine-converter godot test: " <<<"$log"; then break; fi
	sleep 1
done
adb uninstall "$package" >/dev/null 2>&1 || true
echo "$log"
grep -q "spine-converter godot test: passed" <<<"$log"
