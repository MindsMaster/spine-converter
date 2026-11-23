#!/usr/bin/env bash
# Installs the addon zip into the test project, exports it for iOS and builds the simulator app
# Needs the iOS export templates of the Godot binary and Xcode
# Usage: bindings/godot/tests/export_ios.sh <godot binary> <addon zip> <app>
set -euo pipefail
godot=${1:?usage: export_ios.sh <godot binary> <addon zip> <app>}
zip=${2:?usage: export_ios.sh <godot binary> <addon zip> <app>}
app=${3:?usage: export_ios.sh <godot binary> <addon zip> <app>}
project=$(cd "$(dirname "$0")/project" && pwd)
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
rm -rf "$project/addons" "$project/.godot"
python3 -m zipfile -e "$zip" "$project"

# the first import writes .godot/extension_list.cfg and exits with a restart request
"$godot" --headless --path "$project" --import || true
"$godot" --headless --path "$project" --import
"$godot" --headless --path "$project" --export-debug iOS "$work/test.ipa"
xcode=$(xcodebuild -project "$work/test.xcodeproj" -showBuildSettings | awk '$1 == "XCODE_VERSION_ACTUAL" { print $3; exit }')
# export templates hold an x86_64 simulator engine only
# Xcode 26 linker breaks GDExtension exports
xcodebuild -quiet -project "$work/test.xcodeproj" -scheme test -configuration Debug \
	-destination "generic/platform=iOS Simulator" -derivedDataPath "$work/build" \
	ARCHS=x86_64 "LD_CLASSIC_$xcode=-ld_classic" CODE_SIGNING_ALLOWED=NO build
rm -rf "$app"
cp -R "$work/build/Build/Products/Debug-iphonesimulator/test.app" "$app"
