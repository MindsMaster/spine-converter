[English](README.md) | [中文](README.zh-CN.md)

# Godot extension

The addon is a GDExtension that registers the class `SpineConverter`. Its static methods call the C ABI in process and are available to GDScript and every other Godot language.

| Item | Support |
|---|---|
| Godot | 4.3 or later, single precision builds |
| Editor and exports | Windows x86_64, x86_32 and arm64, macOS universal, Linux x86_64 and arm64 |
| Exports | Android arm64 and x86_64 |
| Tests | `tests/run.sh` on Godot 4.3 and 4.7.2, `tests/android.sh` on Android 5.0 and 16 |

Android exports with `armeabi-v7a` or `x86` enabled fail for want of a library. iOS and Web exports have no library in this addon.

## Installation

Extract `spine-converter-<version>-godot.zip` into the project folder so that `addons/spine_converter/spine_converter.gdextension` exists, then restart the editor.

On macOS a downloaded library carries the quarantine attribute. `xattr -dr com.apple.quarantine addons/spine_converter` removes it.

## Usage

```gdscript
var source := FileAccess.get_file_as_bytes("res://hero.skel")
var result := SpineConverter.convert(source, "4.2", SpineConverter.FORMAT_BINARY)
if result.status != SpineConverter.STATUS_OK:
	push_error(result.error)
	return
for entry in result.report:
	push_warning("%s %s: %s" % [entry.code, entry.path, entry.message])
FileAccess.open("user://hero-42.skel", FileAccess.WRITE).store_buffer(result.data)
```

| Method | Returns |
|---|---|
| `convert(data, target_version = "", target_format = FORMAT_UNKNOWN, flags = 0, atlas = PackedByteArray())` | result Dictionary |
| `detect(data)` | Dictionary with `status`, `format`, `version`, `major`, `minor`, `patch` |
| `describe(status)` | text of a status |
| `library_version()` | version text |

An empty `target_version` and `FORMAT_UNKNOWN` keep the source version and format. The atlas text of a 3.5 or 3.6 skeleton keeps mesh UVs of stripped regions. `detect` gives `FORMAT_UNKNOWN` when the data is not Spine data.

| Result key | Value |
|---|---|
| `status` | `STATUS_` constant |
| `error` | text, empty on `STATUS_OK` |
| `data` | converted bytes, empty on failure |
| `report` | Array of Dictionary with `code`, `severity`, `impact`, `step`, `path`, `message`, `remedy`, see [docs/report.md](../../docs/report.md) |
| `loss_count` | dropped and approximated entries |
| `max_impact` | `IMPACT_` constant |

| Enum | Constants |
|---|---|
| `Status` | `STATUS_OK`, `STATUS_INVALID_ARGUMENT`, `STATUS_UNKNOWN_FORMAT`, `STATUS_UNSUPPORTED_VERSION`, `STATUS_MALFORMED`, `STATUS_OUT_OF_MEMORY`, `STATUS_LOSSY_REJECTED` |
| `Format` | `FORMAT_UNKNOWN`, `FORMAT_JSON`, `FORMAT_BINARY`, `FORMAT_ATLAS` |
| `Impact` | `IMPACT_NONE`, `IMPACT_EDITOR`, `IMPACT_CONTROL`, `IMPACT_POSE`, `IMPACT_RENDER` |
| `Flags` | `FLAG_FAIL_ON_LOSS`, `FLAG_PRETTY_JSON`, `FLAG_NO_REWRITE` |

Failures are reported in `status` and `error`. An argument of the wrong type is a script error.

Godot .NET projects can use the [C# binding](../csharp/README.md) from the NuGet package instead.

## Building

```
zig build godot -Dandroid-ndk=<path>
python3 tools/godot_package.py spine-converter-godot.zip
bindings/godot/tests/run.sh <godot binary> spine-converter-godot.zip
```

`-Dandroid-ndk=<path>` names the Android NDK the Android libraries need. `tests/export_android.sh <godot binary> <addon zip> <apk>` exports the test project and needs the Android export templates, `ANDROID_HOME` and `JAVA_HOME`. `tests/android.sh <apk>` runs it on the device or emulator on adb.

`tools/package.sh` builds the same file for a release.
