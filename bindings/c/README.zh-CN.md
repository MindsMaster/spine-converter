[English](README.md) | [中文](README.zh-CN.md)

# C 库

C ABI 声明于 [include/spine_converter.h](../../include/spine_converter.h)，其他所有绑定都调用它。库只依赖操作系统：Windows 上为 `ntdll.dll`，macOS 上为 `libSystem`，Linux 上没有依赖，glibc 和 musl 系统均可加载，Android 5.0 及以上为 `libc.so` 和 `libm.so`。iOS 12 及以上为与 `libSystem` 链接的静态库，Apple 芯片模拟器为 iOS 14 及以上。

## 链接

发布的平台压缩包包含头文件、动态库和用于链接的库。iOS 压缩包包含带头文件的静态 XCFramework。

| 平台 | 动态库 | 链接 | 宏定义 |
|---|---|---|---|
| Windows | `bin/spine_converter.dll` | `lib/spine_converter.lib`，DLL 的导入库 | `SPC_SHARED` |
| macOS | `lib/libspine_converter.dylib` | 动态库或 `lib/libspine_converter.a` | |
| Linux | `lib/libspine_converter.so` | 动态库或 `lib/libspine_converter.a` | |
| Android | `lib/<abi>/libspine_converter.so`，`<abi>` 为 `arm64-v8a` 或 `x86_64` | 动态库 | |
| iOS | | `spine_converter.xcframework` | |

```
cc app.c -Ispine-converter/include -Lspine-converter/lib -lspine_converter
```

`zig build` 将静态库构建到 `zig-out/lib`，`zig build dist` 将各平台的动态库构建到 `zig-out/dist/<rid>`。Android 的库仅在 `-Dandroid-ndk=<path>` 指定 Android NDK 时构建，iOS 的库仅在装有 Xcode 的 macOS 上构建。

## 用法

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

## 函数

| 函数 | 返回 |
|---|---|
| `spc_abi_version()` | 库的 ABI 版本，与 `SPC_ABI_VERSION` 比较 |
| `spc_library_version()` | 版本文本，如 `1.0.0+commit` |
| `spc_status_string(status)` | 状态的文字说明 |
| `spc_detect(data, length, out)` | 格式和版本，数据不是 Spine 数据时返回 `SPC_ERR_UNKNOWN_FORMAT` |
| `spc_convert(data, length, options, allocator, out)` | 状态，结果写入 `out` |
| `spc_result_status(result)` | 转换的状态 |
| `spc_result_data(result, length)` | 输出字节，失败时为 NULL |
| `spc_result_report(result, length)` | 报告 JSON 数组，见 [docs/report.zh-CN.md](../../docs/report.zh-CN.md) |
| `spc_result_loss_count(result)` | 丢弃与近似的条目数 |
| `spc_result_max_impact(result)` | 报告中最严重的影响 |
| `spc_result_remedy_count(result, remedy)` | 具有该补救方式的条目数 |
| `spc_result_error(result)` | 错误文本，成功时为空 |
| `spc_result_free(result)` | 释放结果及其返回的所有内存 |

| `spc_options` 字段 | 值 |
|---|---|
| `struct_size` | `sizeof(spc_options)` |
| `target_version` | 如 `"4.3"` 或 `"3.8.99"`，NULL 保持源版本 |
| `target_format` | `SPC_FORMAT_JSON` 或 `SPC_FORMAT_BINARY`，`SPC_FORMAT_UNKNOWN` 保持源格式 |
| `flags` | `SPC_FLAG_FAIL_ON_LOSS`、`SPC_FLAG_PRETTY_JSON`、`SPC_FLAG_NO_REWRITE`，未知位返回 `SPC_ERR_INVALID_ARGUMENT` |
| `atlas` `atlas_length` | 3.5 或 3.6 骨骼的图集文本，可保留被裁剪区域的网格 UV，没有时为 NULL |

`options` 为 NULL 时保持源版本和格式。图集只能转换为图集。

## 内存与线程

| 规则 | 说明 |
|---|---|
| 所有权 | 结果拥有其返回的所有指针，直到 `spc_result_free` |
| 失败 | 分配成功时，失败也会在 `out` 中返回结果，同样需要释放 |
| 输入 | 缓冲区只在调用期间读取 |
| 分配器 | NULL 使用内部分配器，`spc_allocator` 使本次转换的所有分配都经过其 `alloc` 和 `free` |
| 线程 | 所有函数都是线程安全的 |
| 字符串 | UTF-8，以 NUL 结尾 |

版本之间的兼容性规则见 [docs/stability.zh-CN.md](../../docs/stability.zh-CN.md)。
