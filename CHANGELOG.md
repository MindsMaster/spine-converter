# Changelog

## 1.1.0

Android and iOS support. The C ABI is unchanged.

| Area | Content |
|---|---|
| Platforms | Android 5.0 and later on arm64 and x86_64, iOS 12 and later on arm64, iOS simulator on arm64 from iOS 14 and on x86_64 |
| C ABI | ABI version 1 as in 1.0.0, see `docs/stability.md` |
| C | Android and iOS archives in the release |
| C# | NuGet package carries the Android arm64 and x64 libraries |
| Unity | Android players on ARM64 and x86-64 with IL2CPP, iOS players on device SDK builds |
| Godot | Android exports on arm64 and x86_64, iOS exports for devices and the simulator |

### Verification

| Set | Result |
|---|---|
| Android emulator | C ABI smoke test on Android 5.0 and 16, Godot 4.3 test app on Android 5.0, Godot 4.3 and 4.7.2 test apps on Android 16 |
| iOS simulator | C ABI smoke test, Godot 4.3 and 4.7.2 test apps |
| Minimum versions | API level 21 and 16 KB pages of every Android library, minimum iOS version of every iOS library |

### Assets

| File | Content |
|---|---|
| `spine-converter-1.1.0-<os>-<arch>.zip` `.tar.gz` | CLI, shared and static library, C and C++ headers for windows-x64, windows-x86, windows-arm64, macos-x64, macos-arm64, linux-x64 and linux-arm64 |
| `spine-converter-1.1.0-android.tar.gz` | shared library per Android ABI, C and C++ headers |
| `spine-converter-1.1.0-ios.tar.gz` | static XCFramework for devices and the simulator with C and C++ headers |
| `spine-converter-1.1.0-wasm32.wasm` | WebAssembly module |
| `spine-converter-1.1.0-npm.tgz` | npm package |
| `SpineConverter.1.1.0.nupkg` | NuGet package with the Android libraries |
| `spine_converter-1.1.0-*.whl` | Python wheels |
| `cc.azuramc.spine-converter-1.1.0.tgz` | Unity package with the Android and iOS libraries |
| `spine-converter-1.1.0-godot.zip` | Godot addon with the Android and iOS libraries |
| `SHA256SUMS` | SHA-256 of every file |

### Limitations

| Case | Behavior |
|---|---|
| Godot iOS exports built with Xcode 26 | Link only with `-ld_classic` in Other Linker Flags |

## 1.0.0

First public release.

| Area | Content |
|---|---|
| Versions | 3.5, 3.6, 3.7, 3.8, 4.0, 4.1, 4.2 and 4.3, upgrade and downgrade |
| Formats | JSON, binary and texture atlases |
| Rewrites | Data whose runtime behavior changed between versions is restructured so the target runtime gives the source pose, see `docs/conversion.md` |
| Report | Every dropped, approximated or rewritten item with a stable code, impact and remedy, see `docs/report.md` |
| C ABI | ABI version 1, stable for every 1.x release, see `docs/stability.md` |
| Bindings | C++, C#, JavaScript and TypeScript, Python, Zig, Unity, Godot |
| Platforms | Windows x64, x86 and arm64, macOS 11 arm64 and 10.15 x64, Linux x64 and arm64, WebAssembly |

### Verification

The official runtime of each version poses the source and the converted data and compares them frame by frame.

| Set | Result |
|---|---|
| Fixtures | 358 passed, 0 failed |
| Generated variants | 26632 passed, 0 failed |
| Official example exports | every pair of adjacent versions and every version to and from 4.3, 0 failed |

### Assets

| File | Content |
|---|---|
| `spine-converter-1.0.0-<os>-<arch>.zip` `.tar.gz` | CLI, shared and static library, C and C++ headers for windows-x64, windows-x86, windows-arm64, macos-x64, macos-arm64, linux-x64 and linux-arm64 |
| `spine-converter-1.0.0-wasm32.wasm` | WebAssembly module |
| `spine-converter-1.0.0-npm.tgz` | npm package |
| `SpineConverter.1.0.0.nupkg` | NuGet package |
| `spine_converter-1.0.0-*.whl` | Python wheels |
| `cc.azuramc.spine-converter-1.0.0.tgz` | Unity package |
| `spine-converter-1.0.0-godot.zip` | Godot addon |
| `SHA256SUMS` | SHA-256 of every file |

### Limitations

| Case | Behavior |
|---|---|
| Runtime behavior the target data cannot represent | Reported, see `docs/conversion.md` |
| Some cases outside the condition of a rewrite | Reported, not yet listed in needs-a-runtime.md |
| Unity players on Android, iOS and WebGL | No native library in the Unity package |
| Godot exports to Android, iOS and Web | No library in the Godot addon |
