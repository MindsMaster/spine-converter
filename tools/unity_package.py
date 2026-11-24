"""Builds the Unity package tarball from bindings/unity, the C# binding and zig-out/dist

Usage: python3 tools/unity_package.py <output.tgz>
"""

import hashlib
import io
import json
import struct
import sys
import tarfile
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
UNITY = ROOT / "bindings" / "unity"
DIST = ROOT / "zig-out" / "dist"
NAME = json.loads((UNITY / "package.json").read_text())["name"]

# Unity player and editor settings per plugin
PLUGINS = {
    "Windows/x86_64/spine_converter.dll": ("win-x64", "Windows", "x86_64", "Win64", "x86_64"),
    "Windows/x86/spine_converter.dll": ("win-x86", None, None, "Win", "x86"),
    "Linux/x86_64/libspine_converter.so": ("linux-x64", "Linux", "x86_64", "Linux64", "x86_64"),
    "macOS/libspine_converter.dylib": ("osx", "OSX", "AnyCPU", "OSXUniversal", "AnyCPU"),
    "Android/arm64-v8a/libspine_converter.so": ("android-arm64", None, None, "Android", "ARM64"),
    "Android/x86_64/libspine_converter.so": ("android-x64", None, None, "Android", "X86_64"),
    "iOS/libspine_converter.a": ("ios-arm64", None, None, "iPhone", "AnyCPU"),
}
PLAYERS = ("Win", "Win64", "Linux64", "OSXUniversal")


def guid(path):
    """Stable across builds so upgrades keep references"""
    return hashlib.md5(f"{NAME}/{path}".encode()).hexdigest()


def tail(importer):
    return f"{importer}:\n  externalObjects: {{}}\n  userData: \n  assetBundleName: \n  assetBundleVariant: \n"


def folder_meta(path):
    return f"fileFormatVersion: 2\nguid: {guid(path)}\nfolderAsset: yes\n" + tail("DefaultImporter")


def file_meta(path):
    head = f"fileFormatVersion: 2\nguid: {guid(path)}\n"
    if path.endswith(".cs"):
        return head + (
            "MonoImporter:\n  externalObjects: {}\n  serializedVersion: 2\n  defaultReferences: []\n"
            "  executionOrder: 0\n  icon: {instanceID: 0}\n  userData: \n  assetBundleName: \n  assetBundleVariant: \n"
        )
    if path.endswith(".asmdef"):
        return head + tail("AssemblyDefinitionImporter")
    if path == "package.json":
        return head + tail("PackageManifestImporter")
    if path.endswith(".md"):
        return head + tail("TextScriptImporter")
    plugin = PLUGINS.get(path.removeprefix("Runtime/Plugins/"))
    if plugin is None:
        return head + tail("DefaultImporter")
    _, editor_os, editor_cpu, player, player_cpu = plugin
    data = ["  - first:\n      Any: \n    second:\n      enabled: 0\n      settings: {}\n"]
    editor = f"        CPU: {editor_cpu}\n        DefaultValueInitialized: true\n        OS: {editor_os}\n" if editor_os else "        CPU: AnyCPU\n"
    data.append(f"  - first:\n      Editor: Editor\n    second:\n      enabled: {1 if editor_os else 0}\n      settings:\n{editor}")
    for p in PLAYERS:
        on = p == player
        data.append(f"  - first:\n      Standalone: {p}\n    second:\n      enabled: {1 if on else 0}\n      settings:\n        CPU: {player_cpu if on else 'None'}\n")
    if player == "Android":
        data.append(f"  - first:\n      Android: Android\n    second:\n      enabled: 1\n      settings:\n        CPU: {player_cpu}\n")
    if player == "iPhone":
        data.append(
            "  - first:\n      iPhone: iOS\n    second:\n      enabled: 1\n      settings:\n"
            "        AddToEmbeddedBinaries: false\n        CPU: AnyCPU\n        CompileFlags: \n        FrameworkDependencies: \n"
        )
    return head + (
        "PluginImporter:\n  externalObjects: {}\n  serializedVersion: 2\n  iconMap: {}\n  executionOrder: {}\n"
        "  defineConstraints: []\n  isPreloaded: 0\n  isOverridable: 0\n  isExplicitlyReferenced: 0\n"
        "  validateReferences: 1\n  platformData:\n" + "".join(data) +
        "  userData: \n  assetBundleName: \n  assetBundleVariant: \n"
    )


def universal(*slices):
    """Fat Mach-O so one plugin serves both Mac CPUs"""
    align = 14
    header = struct.pack(">II", 0xCAFEBABE, len(slices))
    offset = 1 << align
    arches, body = b"", b""
    for data in slices:
        magic, cputype, cpusubtype = struct.unpack_from("<IiI", data)
        assert magic == 0xFEEDFACF, "expects 64-bit Mach-O"
        arches += struct.pack(">iIIII", cputype, cpusubtype & 0x00FFFFFF, offset + len(body), len(data), align)
        body += data
        body += b"\0" * (-len(body) % (1 << align))
    return header + arches + b"\0" * (offset - len(header) - len(arches)) + body


def files():
    yield "package.json", (UNITY / "package.json").read_bytes()
    for doc in ("README.md", "README.zh-CN.md"):
        yield doc, (UNITY / doc).read_bytes()
    yield "LICENSE", (ROOT / "LICENSE").read_bytes()
    yield "LICENSE-MIT", (ROOT / "LICENSE-MIT").read_bytes()
    yield "Runtime/SpineConverter.asmdef", (UNITY / "Runtime" / "SpineConverter.asmdef").read_bytes()
    for source in sorted((ROOT / "bindings" / "csharp" / "SpineConverter").glob("*.cs")):
        yield f"Runtime/{source.name}", source.read_bytes()
    for path, (rid, *_) in PLUGINS.items():
        if rid == "osx":
            data = universal(*((DIST / r / "libspine_converter.dylib").read_bytes() for r in ("osx-arm64", "osx-x64")))
        else:
            data = (DIST / rid / Path(path).name).read_bytes()
        yield f"Runtime/Plugins/{path}", data


def main():
    entries = dict(files())
    folders = {str(p) for path in entries for p in Path(path).parents if str(p) != "."}
    for folder in folders:
        entries[f"{folder}.meta"] = folder_meta(folder).encode()
    for path in [p for p in entries if not p.endswith(".meta")]:
        entries[f"{path}.meta"] = file_meta(path).encode()
    with tarfile.open(sys.argv[1], "w:gz") as tar:
        for path in sorted(entries):
            info = tarfile.TarInfo(f"package/{path}")
            info.size = len(entries[path])
            info.mode = 0o644
            tar.addfile(info, io.BytesIO(entries[path]))


if __name__ == "__main__":
    main()
