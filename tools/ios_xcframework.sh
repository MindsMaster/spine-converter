#!/usr/bin/env bash
# Joins the iOS libraries of zig-out/dist into zig-out/ios/spine_converter.xcframework
# Needs macOS with Xcode and zig build dist for ios-arm64, iossimulator-arm64 and iossimulator-x64
# Usage: tools/ios_xcframework.sh
set -euo pipefail
root=$(cd "$(dirname "$0")/.." && pwd)
dist=$root/zig-out/dist
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

mkdir "$work/headers"
cp "$root/include/spine_converter.h" "$root/bindings/cpp/spine_converter.hpp" "$work/headers/"
lipo -create -output "$work/libspine_converter.a" \
	"$dist/iossimulator-arm64/libspine_converter.a" "$dist/iossimulator-x64/libspine_converter.a"
rm -rf "$root/zig-out/ios"
xcodebuild -create-xcframework \
	-library "$dist/ios-arm64/libspine_converter.a" -headers "$work/headers" \
	-library "$work/libspine_converter.a" -headers "$work/headers" \
	-output "$root/zig-out/ios/spine_converter.xcframework"
