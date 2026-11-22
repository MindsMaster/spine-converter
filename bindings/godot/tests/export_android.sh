#!/usr/bin/env bash
# Installs the addon zip into the test project and exports it as a debug APK
# Needs the Android export templates of the Godot binary, ANDROID_HOME and JAVA_HOME
# Usage: bindings/godot/tests/export_android.sh <godot binary> <addon zip> <apk>
set -euo pipefail
godot=${1:?usage: export_android.sh <godot binary> <addon zip> <apk>}
zip=${2:?usage: export_android.sh <godot binary> <addon zip> <apk>}
apk=$(realpath "${3:?usage: export_android.sh <godot binary> <addon zip> <apk>}")
project=$(cd "$(dirname "$0")/project" && pwd)
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
rm -rf "$project/addons" "$project/.godot"
python3 -m zipfile -e "$zip" "$project"

keytool -genkeypair -keystore "$work/debug.keystore" -alias androiddebugkey -storepass android -keypass android \
	-dname "CN=Android Debug,O=Android,C=US" -keyalg RSA -validity 10000 >/dev/null 2>&1
export GODOT_ANDROID_KEYSTORE_DEBUG_PATH=$work/debug.keystore
export GODOT_ANDROID_KEYSTORE_DEBUG_USER=androiddebugkey
export GODOT_ANDROID_KEYSTORE_DEBUG_PASSWORD=android

# the first import writes .godot/extension_list.cfg and exits with a restart request
timeout 300 "$godot" --headless --path "$project" --import || true
timeout 300 "$godot" --headless --path "$project" --import
timeout 600 "$godot" --headless --path "$project" --export-debug Android "$apk"
