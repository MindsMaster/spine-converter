[English](README.md) | [中文](README.zh-CN.md)

# C library

The C ABI is declared in [include/spine_converter.h](../../include/spine_converter.h). Every other binding calls it. The libraries need only the operating system: `ntdll.dll` on Windows, `libSystem` on macOS, nothing on Linux, where glibc and musl systems both load them, and `libc.so` with `libm.so` on Android 5.0 and later. iOS 12 and later get a static library that links with `libSystem`, the Apple silicon simulator iOS 14 and later.

## Linking

The platform archives of a release hold the header, the shared library and a library to link against.

| Platform | Shared library | Link with | Define |
|---|---|---|---|
| Windows | `bin/spine_converter.dll` | `lib/spine_converter.lib`, import library of the DLL | `SPC_SHARED` |
| macOS | `lib/libspine_converter.dylib` | the shared library or `lib/libspine_converter.a` | |
| Linux | `lib/libspine_converter.so` | the shared library or `lib/libspine_converter.a` | |

```
cc app.c -Ispine-converter/include -Lspine-converter/lib -lspine_converter
```

`zig build` builds the static library into `zig-out/lib` and `zig build dist` the shared library of every platform into `zig-out/dist/<rid>`. The Android libraries build only with `-Dandroid-ndk=<path>` naming an Android NDK, the iOS libraries only on macOS with Xcode.

## Usage

```c
#include <spine_converter.h>

spc_options options = {
    .struct_size = sizeof options,
    .target_version = "4.3",
    .target_format = SPC_FORMAT_BINARY,
};
spc_result *result = NULL;
spc_status status = spc_convert(data, length, &options, NULL, &result);
if (status == SPC_OK) {
    size_t size;
    const uint8_t *skel = spc_result_data(result, &size);
    size_t report_length;
    const char *report = spc_result_report(result, &report_length);
} else {
    fprintf(stderr, "%s\n", result ? spc_result_error(result) : spc_status_string(status));
}
spc_result_free(result);
```

## Functions

| Function | Returns |
|---|---|
| `spc_abi_version()` | ABI version of the library, compare with `SPC_ABI_VERSION` |
| `spc_library_version()` | version text such as `1.0.0+commit` |
| `spc_status_string(status)` | text of a status |
| `spc_detect(data, length, out)` | format and version, `SPC_ERR_UNKNOWN_FORMAT` when the data is not Spine data |
| `spc_convert(data, length, options, allocator, out)` | status, and a result in `out` |
| `spc_result_status(result)` | status of the conversion |
| `spc_result_data(result, length)` | output bytes, NULL on failure |
| `spc_result_report(result, length)` | report JSON array, see [docs/report.md](../../docs/report.md) |
| `spc_result_loss_count(result)` | dropped and approximated entries |
| `spc_result_max_impact(result)` | most severe impact of the report |
| `spc_result_remedy_count(result, remedy)` | entries with that remedy |
| `spc_result_error(result)` | error text, empty on success |
| `spc_result_free(result)` | frees the result and everything it returned |

| `spc_options` field | Value |
|---|---|
| `struct_size` | `sizeof(spc_options)` |
| `target_version` | such as `"4.3"` or `"3.8.99"`, NULL keeps the source version |
| `target_format` | `SPC_FORMAT_JSON` or `SPC_FORMAT_BINARY`, `SPC_FORMAT_UNKNOWN` keeps the source format |
| `flags` | `SPC_FLAG_FAIL_ON_LOSS`, `SPC_FLAG_PRETTY_JSON`, `SPC_FLAG_NO_REWRITE`, unknown bits fail with `SPC_ERR_INVALID_ARGUMENT` |
| `atlas` `atlas_length` | atlas text of a 3.5 or 3.6 skeleton, keeps mesh UVs of stripped regions, NULL when absent |

A NULL `options` keeps the source version and format. An atlas converts only to an atlas.

## Memory and threads

| Rule | Detail |
|---|---|
| ownership | the result owns every pointer it returns until `spc_result_free` |
| failure | `out` holds a result on failure too when allocation succeeded, free it the same way |
| input | buffers are read only during the call |
| allocator | NULL uses the internal allocator, an `spc_allocator` routes every allocation of the conversion through its `alloc` and `free` |
| threads | every function is thread-safe |
| strings | UTF-8 and NUL-terminated |

Compatibility rules between releases are listed in [docs/stability.md](../../docs/stability.md).
