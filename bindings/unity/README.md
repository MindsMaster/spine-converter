[English](README.md) | [中文](README.zh-CN.md)

# Unity package

`cc.azuramc.spine-converter` carries the [C# binding](../csharp/README.md) as source in the `SpineConverter` assembly and the native library of every desktop player and of Android.

| Item | Support |
|---|---|
| Unity | 2021.2 or later, API compatibility level .NET Standard 2.1 or .NET Framework |
| Scripting backend | Mono and IL2CPP |
| Editor | Windows x64, macOS, Linux x64 |
| Players | Windows x64 and x86, macOS universal, Linux x64 |
| Android players | ARM64 and x86-64 with IL2CPP |

Android builds with ARMv7 enabled lack its library. iOS and WebGL players have no native library in this package.

## Installation

Download `cc.azuramc.spine-converter-<version>.tgz` from the GitHub release. In the Package Manager window choose Add package from tarball.

## Usage

```csharp
using SpineConverter;

byte[] source = File.ReadAllBytes(path);
Conversion result = Converter.Convert(source, "4.2", Format.Binary);
foreach (ReportEntry entry in result.Report)
    Debug.LogWarning($"{entry.Code} {entry.Path}: {entry.Message}");
```

The members are listed in the [C# binding](../csharp/README.md). The assembly enables unsafe code for itself only.

## Building

```
zig build dist -Dandroid-ndk=<path>
python3 tools/unity_package.py cc.azuramc.spine-converter.tgz
```

`-Dandroid-ndk=<path>` names the Android NDK the Android libraries need. `tools/package.sh` builds the same file for a release.
