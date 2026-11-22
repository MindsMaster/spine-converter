[English](README.md) | [中文](README.zh-CN.md)

# Unity 包

`cc.azuramc.spine-converter` 以源码形式包含 [C# 绑定](../csharp/README.zh-CN.md)，编译为 `SpineConverter` 程序集，并附带各桌面平台以及 Android 的原生库。

| 项目 | 支持 |
|---|---|
| Unity | 2021.2 及以上，API 兼容级别 .NET Standard 2.1 或 .NET Framework |
| 脚本后端 | Mono 与 IL2CPP |
| 编辑器 | Windows x64、macOS、Linux x64 |
| 播放器 | Windows x64 与 x86、macOS universal、Linux x64 |
| Android 播放器 | ARM64 与 x86-64，使用 IL2CPP |

启用 ARMv7 的 Android 构建缺少其原生库。本包不含 iOS 和 WebGL 播放器的原生库。

## 安装

从 GitHub Release 下载 `cc.azuramc.spine-converter-<version>.tgz`，在 Package Manager 窗口中选择 Add package from tarball。

## 使用

```csharp
using SpineConverter;

byte[] source = File.ReadAllBytes(path);
Conversion result = Converter.Convert(source, "4.2", Format.Binary);
foreach (ReportEntry entry in result.Report)
    Debug.LogWarning($"{entry.Code} {entry.Path}: {entry.Message}");
```

成员列表见 [C# 绑定](../csharp/README.zh-CN.md)。该程序集仅对自身启用 unsafe 代码。

## 构建

```
zig build dist -Dandroid-ndk=<path>
python3 tools/unity_package.py cc.azuramc.spine-converter.tgz
```

`-Dandroid-ndk=<path>` 指定 Android 库所需的 Android NDK。发布时由 `tools/package.sh` 生成同一文件。
