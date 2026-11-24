#!/usr/bin/env bash
# Links the C ABI smoke test against each library of the iOS xcframework and runs it in the booted simulator
# Usage: tests/ios.sh after tools/ios_xcframework.sh
set -euo pipefail
root=$(cd "$(dirname "$0")/.." && pwd)
framework=$root/zig-out/ios/spine_converter.xcframework
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

link() {
	xcrun --sdk "$1" clang -target "$2" -std=c99 -Wall -Wextra -Werror -I"$framework/$3/Headers" \
		-o "$work/$4" "$root/tests/abi_smoke.c" "$framework/$3/libspine_converter.a"
}
link iphoneos arm64-apple-ios12.0 ios-arm64 device
link iphonesimulator arm64-apple-ios14.0-simulator ios-arm64_x86_64-simulator simulator-arm64
link iphonesimulator x86_64-apple-ios12.0-simulator ios-arm64_x86_64-simulator simulator-x86_64

simulator=simulator-$(uname -m)
xcrun simctl spawn booted "$work/$simulator"
echo "abi smoke passed on $simulator"
