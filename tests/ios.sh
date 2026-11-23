#!/usr/bin/env bash
# Links the C ABI smoke test against each iOS library of zig-out/dist and runs it in the booted simulator
# Usage: tests/ios.sh
set -euo pipefail
root=$(cd "$(dirname "$0")/.." && pwd)
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

link() {
	xcrun --sdk "$1" clang -target "$2" -std=c99 -Wall -Wextra -Werror -I"$root/include" \
		-o "$work/$3" "$root/tests/abi_smoke.c" "$root/zig-out/dist/$3/libspine_converter.a"
}
link iphoneos arm64-apple-ios12.0 ios-arm64
link iphonesimulator arm64-apple-ios14.0-simulator iossimulator-arm64
link iphonesimulator x86_64-apple-ios12.0-simulator iossimulator-x64

case $(uname -m) in
	arm64) rid=iossimulator-arm64 ;;
	*) rid=iossimulator-x64 ;;
esac
xcrun simctl spawn booted "$work/$rid"
echo "abi smoke passed on $rid"
