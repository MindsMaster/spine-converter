#!/usr/bin/env bash
# Runs the C ABI smoke test against zig-out/dist on the device adb reaches
# Usage: tests/android.sh <android ndk>
set -euo pipefail
ndk=${1:?usage: android.sh <android ndk>}
root=$(cd "$(dirname "$0")/.." && pwd)
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

abi=$(adb shell getprop ro.product.cpu.abi | tr -d '\r')
api=$(adb shell getprop ro.build.version.sdk | tr -d '\r')
case $abi in
	arm64-v8a) rid=android-arm64 triple=aarch64-linux-android ;;
	x86_64) rid=android-x64 triple=x86_64-linux-android ;;
	*) echo "no library for $abi" && exit 1 ;;
esac
host=$(uname -s | tr '[:upper:]' '[:lower:]')-x86_64
"$ndk/toolchains/llvm/prebuilt/$host/bin/clang" --target="${triple}21" -std=c99 -Wall -Wextra -Werror \
	-I"$root/include" -L"$root/zig-out/dist/$rid" -lspine_converter -o "$work/abi_smoke" "$root/tests/abi_smoke.c"

dir=/data/local/tmp/spine-converter
adb shell rm -rf "$dir"
adb shell mkdir -p "$dir"
adb push "$work/abi_smoke" "$root/zig-out/dist/$rid/libspine_converter.so" "$dir/" >/dev/null
# adb shell before Android 7 drops the exit status
out=$(adb shell "cd $dir && LD_LIBRARY_PATH=. ./abi_smoke; echo exit=\$?" | tr -d '\r')
echo "$out"
adb shell rm -rf "$dir"
if [[ $out != *exit=0 ]]; then
	echo "abi smoke failed on $abi API $api"
	exit 1
fi
echo "abi smoke passed on $abi API $api"
