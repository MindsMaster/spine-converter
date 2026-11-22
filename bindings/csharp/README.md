[English](https://github.com/MindsMaster/spine-converter/blob/main/bindings/csharp/README.md) | [中文](https://github.com/MindsMaster/spine-converter/blob/main/bindings/csharp/README.zh-CN.md)

# C# binding

`SpineConverter` binds the C ABI with `DllImport` and targets .NET Standard 2.1 and .NET 8. The sources compile as C# 9, so the same files serve the [Unity package](https://github.com/MindsMaster/spine-converter/blob/main/bindings/unity/README.md). The .NET 8 build is AOT compatible. `Native` maps `include/spine_converter.h` one function per entry point. `Converter` copies every result into managed data and frees the native result before it returns.

```
dotnet add package SpineConverter
```

The `SpineConverter` package carries the native library of every desktop platform and of Android arm64 and x64 under `runtimes/<rid>/native` and .NET loads the right one. Without the package, the library loads as `spine_converter` from the default search path, so ship the file of `zig-out/dist/<rid>` beside the application or register a `NativeLibrary` resolver.

| Member | Use |
|---|---|
| `Converter.Detect(data)` | format and version, `Format.Unknown` for data that is not Spine data |
| `Converter.Convert(data, targetVersion, targetFormat, flags, atlas)` | a `Conversion` with the output bytes, the report and its loss count and most severe impact |
| `ConvertFlags` | `FailOnLoss`, `PrettyJson` and `NoRewrite`, matching the `SPC_FLAG_` bits |
| `Converter.AbiVersion` `Converter.LibraryVersion` | versions of the loaded library, a mismatched ABI throws |
| `Converter.Describe(status)` | text of a status |
| `ConverterException` | thrown on every failure, `Status` holds the C ABI status |

A null target version and `Format.Unknown` keep the source version and format. The atlas of a 3.5 or 3.6 skeleton keeps the mesh UVs of stripped regions, as `--atlas` does. Report entries follow [docs/report.md](https://github.com/MindsMaster/spine-converter/blob/main/docs/report.md).

```
zig build dist
dotnet run --project bindings/csharp/Tests
dotnet pack bindings/csharp/SpineConverter -c Release
```

The tests call every ABI function and cover success, errors, lossy output and atlases.
