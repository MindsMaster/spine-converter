"""Builds the Godot addon zip from bindings/godot and zig-out/godot

Usage: python3 tools/godot_package.py <output.zip> [feature tag ...]
Feature tags limit the libraries, for example linux.x86_64 or macos
"""

import sys
import zipfile
from pathlib import Path

from unity_package import ROOT, universal

GODOT = ROOT / "bindings" / "godot"
BUILT = ROOT / "zig-out" / "godot"
PREFIX = "addons/spine_converter/"
LIBRARIES = {
    "windows.x86_64": "spine_converter_godot.dll",
    "windows.x86_32": "spine_converter_godot.dll",
    "windows.arm64": "spine_converter_godot.dll",
    "linux.x86_64": "libspine_converter_godot.so",
    "linux.arm64": "libspine_converter_godot.so",
    "android.arm64": "libspine_converter_godot.so",
    "android.x86_64": "libspine_converter_godot.so",
}
MACOS = "libspine_converter_godot.dylib"


def files(tags):
    yield "spine_converter.gdextension", (GODOT / "spine_converter.gdextension").read_bytes()
    for doc in ("README.md", "README.zh-CN.md"):
        yield doc, (GODOT / doc).read_bytes()
    yield "LICENSE", (ROOT / "LICENSE").read_bytes()
    yield "LICENSE-MIT", (ROOT / "LICENSE-MIT").read_bytes()
    for tag, library in LIBRARIES.items():
        if not tags or tag in tags:
            yield f"bin/{tag}/{library}", (BUILT / tag / library).read_bytes()
    if not tags or "macos" in tags:
        yield f"bin/macos/{MACOS}", universal(*((BUILT / tag / MACOS).read_bytes() for tag in ("macos.arm64", "macos.x86_64")))


def main():
    with zipfile.ZipFile(sys.argv[1], "w", zipfile.ZIP_DEFLATED) as archive:
        for path, data in sorted(files(sys.argv[2:])):
            # fixed time keeps the archive reproducible
            info = zipfile.ZipInfo(PREFIX + path, (2020, 2, 2, 0, 0, 0))
            info.external_attr = 0o644 << 16
            info.compress_type = zipfile.ZIP_DEFLATED
            archive.writestr(info, data)


if __name__ == "__main__":
    main()
