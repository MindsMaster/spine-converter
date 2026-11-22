[English](README.md) | [中文](README.zh-CN.md)

# C# 绑定

`SpineConverter` 用 `DllImport` 绑定 C ABI，目标框架为 .NET Standard 2.1 和 .NET 8。源码按 C# 9 编译，[Unity 包](../unity/README.zh-CN.md) 使用同一份文件。.NET 8 版本兼容 AOT。`Native` 按 `include/spine_converter.h` 逐个映射入口函数。`Converter` 把每个结果复制为托管数据，并在返回前释放原生结果。

```
dotnet add package SpineConverter
```

`SpineConverter` 软件包在 `runtimes/<rid>/native` 下带有各桌面平台以及 Android arm64 和 x64 的原生库，由 .NET 自动加载对应的一个。不使用软件包时，库按名称 `spine_converter` 从默认搜索路径加载，需将 `zig-out/dist/<rid>` 中的文件放在应用旁边，或注册 `NativeLibrary` 解析器。

| 成员 | 用途 |
|---|---|
| `Converter.Detect(data)` | 格式与版本，非 Spine 数据时为 `Format.Unknown` |
| `Converter.Convert(data, targetVersion, targetFormat, flags, atlas)` | 返回 `Conversion`，包含输出字节、报告、损失数和最高影响 |
| `ConvertFlags` | `FailOnLoss`、`PrettyJson` 和 `NoRewrite`，对应 `SPC_FLAG_` 位 |
| `Converter.AbiVersion` `Converter.LibraryVersion` | 已加载库的版本，ABI 不匹配时抛出异常 |
| `Converter.Describe(status)` | 状态的文字说明 |
| `ConverterException` | 所有失败都抛出，`Status` 为 C ABI 状态 |

目标版本为 null 且格式为 `Format.Unknown` 时保留源版本和格式。传入 3.5 或 3.6 骨骼的图集可保留裁剪区域上网格的 UV，与 `--atlas` 相同。报告条目见 [docs/report.zh-CN.md](../../docs/report.zh-CN.md)。

```
zig build dist
dotnet run --project bindings/csharp/Tests
dotnet pack bindings/csharp/SpineConverter -c Release
```

测试调用了每个 ABI 函数，覆盖成功、错误、有损输出和图集。
