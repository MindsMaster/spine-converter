[English](README.md) | [中文](README.zh-CN.md)

# Godot 扩展

该插件是一个 GDExtension，注册 `SpineConverter` 类。其静态方法在进程内调用 C ABI，可供 GDScript 及其他所有 Godot 语言使用。

| 项目 | 支持 |
|---|---|
| Godot | 4.3 及以上，单精度构建 |
| 编辑器与导出 | Windows x86_64、x86_32 和 arm64，macOS universal，Linux x86_64 和 arm64 |
| 导出 | Android arm64 和 x86_64，iOS 12 及以上与 iOS 模拟器 |
| 测试 | `tests/run.sh`，在 Godot 4.3 和 4.7.2 上运行，`tests/android.sh`，在 Android 5.0 和 16 上运行，`tests/ios.sh`，在 iOS 模拟器中运行 |

勾选 `armeabi-v7a` 或 `x86` 的 Android 导出会因缺少库而失败。Web 导出在该插件中没有对应的库。Xcode 26 只能用旧版链接器链接 iOS 导出，需在 Other Linker Flags 中加入 `-ld_classic`。

## 安装

将 `spine-converter-<version>-godot.zip` 解压到项目目录，使 `addons/spine_converter/spine_converter.gdextension` 存在，然后重启编辑器。

在 macOS 上，下载的库带有隔离属性，可用 `xattr -dr com.apple.quarantine addons/spine_converter` 移除。

## 用法

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

| 方法 | 返回 |
|---|---|
| `convert(data, target_version = "", target_format = FORMAT_UNKNOWN, flags = 0, atlas = PackedByteArray())` | 结果 Dictionary |
| `detect(data)` | 含 `status`、`format`、`version`、`major`、`minor`、`patch` 的 Dictionary |
| `describe(status)` | 状态的文字说明 |
| `library_version()` | 版本文本 |

`target_version` 为空且 `target_format` 为 `FORMAT_UNKNOWN` 时，保持源数据的版本和格式。对于 3.5 或 3.6 的骨骼，传入图集文本可保留被裁剪区域的网格 UV。数据不是 Spine 数据时，`detect` 返回 `FORMAT_UNKNOWN`。

| 结果键 | 值 |
|---|---|
| `status` | `STATUS_` 常量 |
| `error` | 错误文本，`STATUS_OK` 时为空 |
| `data` | 转换后的字节，失败时为空 |
| `report` | Dictionary 数组，键为 `code`、`severity`、`impact`、`step`、`path`、`message`、`remedy`，见 [docs/report.zh-CN.md](../../docs/report.zh-CN.md) |
| `loss_count` | 丢弃与近似的条目数 |
| `max_impact` | `IMPACT_` 常量 |

| 枚举 | 常量 |
|---|---|
| `Status` | `STATUS_OK`、`STATUS_INVALID_ARGUMENT`、`STATUS_UNKNOWN_FORMAT`、`STATUS_UNSUPPORTED_VERSION`、`STATUS_MALFORMED`、`STATUS_OUT_OF_MEMORY`、`STATUS_LOSSY_REJECTED` |
| `Format` | `FORMAT_UNKNOWN`、`FORMAT_JSON`、`FORMAT_BINARY`、`FORMAT_ATLAS` |
| `Impact` | `IMPACT_NONE`、`IMPACT_EDITOR`、`IMPACT_CONTROL`、`IMPACT_POSE`、`IMPACT_RENDER` |
| `Flags` | `FLAG_FAIL_ON_LOSS`、`FLAG_PRETTY_JSON`、`FLAG_NO_REWRITE` |

失败通过 `status` 和 `error` 返回。参数类型错误时产生脚本错误。

Godot .NET 项目也可以改用 NuGet 包中的 [C# 绑定](../csharp/README.zh-CN.md)。

## 构建

```
zig build godot -Dandroid-ndk=<path>
python3 tools/godot_package.py spine-converter-godot.zip
bindings/godot/tests/run.sh <godot binary> spine-converter-godot.zip
```

`-Dandroid-ndk=<path>` 指定 Android 库所需的 Android NDK。`tests/export_android.sh <godot binary> <addon zip> <apk>` 导出测试项目，需要 Android 导出模板、`ANDROID_HOME` 和 `JAVA_HOME`。`tests/android.sh <apk>` 在 adb 连接的设备或模拟器上运行它。iOS 的库仅在装有 Xcode 的 macOS 上构建。`tests/export_ios.sh <godot binary> <addon zip> <app>` 用 iOS 导出模板导出测试项目并为模拟器构建。`tests/ios.sh <app>` 在已启动的模拟器中运行它。

`tools/package.sh` 为发布构建同一文件。
