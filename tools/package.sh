#!/usr/bin/env bash
# Builds every release artifact into one directory with SHA256SUMS
# Needs zig, dotnet, pnpm, an Android NDK in ANDROID_NDK_HOME, the iOS libraries of zig build dist godot from macOS in zig-out, and python3 with the build module unless SKIP_WHEELS is set
# Usage: tools/package.sh <commit> [output dir]
set -euo pipefail
root=$(cd "$(dirname "$0")/.." && pwd)
commit=${1:?usage: package.sh <commit> [output dir]}
out=$(mkdir -p "${2:-$root/zig-out/release}" && cd "${2:-$root/zig-out/release}" && pwd)
version=$("$root/tools/versions.sh")
stage=$(mktemp -d)
trap 'rm -rf "$stage"' EXIT
cd "$root"

# .NET rid, zig triple, archive platform, wheel tag
targets=(
	"win-x64 x86_64-windows windows-x64 win_amd64"
	"win-x86 x86-windows windows-x86 win32"
	"win-arm64 aarch64-windows windows-arm64 win_arm64"
	"osx-x64 x86_64-macos.10.15 macos-x64 macosx_10_15_x86_64"
	"osx-arm64 aarch64-macos.11.0 macos-arm64 macosx_11_0_arm64"
	"linux-x64 x86_64-linux linux-x64 manylinux_2_17_x86_64.manylinux2014_x86_64.musllinux_1_1_x86_64"
	"linux-arm64 aarch64-linux linux-arm64 manylinux_2_17_aarch64.manylinux2014_aarch64.musllinux_1_1_aarch64"
)

zig build dist wasm godot -Dcommit="$commit" -Dandroid-ndk="${ANDROID_NDK_HOME:?ANDROID_NDK_HOME names no Android NDK}"
for target in "${targets[@]}"; do
	read -r rid triple platform _ <<<"$target"
	name="spine-converter-$version-$platform"
	zig build -Dtarget="$triple" -Doptimize=ReleaseFast -Dstrip -Dcommit="$commit" -p "$stage/$name"
	if [[ $rid == win-* ]]; then
		# import library of the dll takes the name of the static one
		rm "$stage/$name/lib/spine_converter.lib"
		cp zig-out/dist-implib/"$rid"/* "$stage/$name/lib/"
		cp zig-out/dist/"$rid"/* "$stage/$name/bin/"
	else
		cp zig-out/dist/"$rid"/* "$stage/$name/lib/"
	fi
	cp LICENSE LICENSE-MIT README.md "$stage/$name/"
	if [[ $rid == win-* ]]; then
		(cd "$stage" && python3 -m zipfile -c "$out/$name.zip" "$name")
	else
		tar -czf "$out/$name.tar.gz" -C "$stage" "$name"
	fi
done
cp zig-out/bin/spine_converter.wasm "$out/spine-converter-$version-wasm32.wasm"

(cd bindings/js && pnpm install --frozen-lockfile && pnpm run build && pnpm pack --pack-destination "$stage")
mv "$stage/spine-converter-$version.tgz" "$out/spine-converter-$version-npm.tgz"

dotnet pack bindings/csharp/SpineConverter -c Release -o "$out"

python3 tools/unity_package.py "$out/cc.azuramc.spine-converter-$version.tgz"
python3 tools/godot_package.py "$out/spine-converter-$version-godot.zip"

if [ -z "${SKIP_WHEELS:-}" ]; then
	cp LICENSE LICENSE-MIT bindings/python/
	for target in "${targets[@]}"; do
		read -r rid _ _ tag <<<"$target"
		rm -f bindings/python/src/spine_converter/*.{dll,dylib,so}
		cp zig-out/dist/"$rid"/* bindings/python/src/spine_converter/
		SPINE_CONVERTER_WHEEL_TAG="py3-none-$tag" python3 -m build --wheel --outdir "$out" bindings/python
	done
	rm -f bindings/python/src/spine_converter/*.{dll,dylib,so}
fi

(cd "$out" && rm -f SHA256SUMS && sha256sum -- * >SHA256SUMS)
