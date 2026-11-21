[English](CONTRIBUTING.md) | [中文](CONTRIBUTING.zh-CN.md)

# 参与贡献

## 环境

| 工具 | 用途 |
|---|---|
| [Zig](https://ziglang.org/download/) 0.17.x | 全部 |
| bash | 比对和工具脚本 |
| .NET 8 SDK | C# 绑定、C# 比对程序 |
| Node 与 pnpm | JavaScript 绑定 |
| Python 3.10 及以上 | Python 绑定 |
| [spine-runtimes](https://github.com/EsotericSoftware/spine-runtimes) 的克隆 | 比对所需的官方样例导出和官方运行时 |

```
zig build
zig build test
tools/fetch-corpus.sh <spine-runtimes clone>
tools/fetch-runtimes.sh <spine-runtimes clone>
oracle/all.sh
```

`testdata` 存放取得的导出和运行时，不提交到仓库。

## 检查

`oracle/all.sh` 构建一次后运行全部检查，每个脚本也可单独运行。全部通过后改动才可合入，完整列表见 [AGENTS.md](AGENTS.md)。

| 检查 | 验证内容 |
|---|---|
| `zig build test` | 单元测试与报告代码表 |
| `oracle/codec.sh` | JSON 与 skel 往返转换后姿势不变 |
| `oracle/migrate.sh` | 转换结果在官方运行时中的姿势与源数据一致 |
| `oracle/fixtures.sh` | `oracle/fixtures` 中每一处运行时变化都按列出的方式改写或报告 |
| `oracle/variants.sh` | 变异后的导出保持姿势或报告损失 |
| `oracle/hostile.sh` | 损坏的输入失败时不崩溃、不卡死、不写出无法读取的结果 |

## 绑定

| 绑定 | 测试 |
|---|---|
| C 与 C++ | 包含在 `zig build test` 中 |
| Android | 先 `zig build dist -Drid=android-x64 -Dandroid-ndk=<path>`，`android-arm64` 同样构建，再在 adb 连接设备或模拟器后运行 `tests/android.sh <path>` |
| C# | 先 `zig build dist`，再 `dotnet run --project bindings/csharp/Tests` |
| JavaScript | 先 `zig build wasm`，再在 `bindings/js` 中运行 `pnpm install`、`pnpm run build` 和 `pnpm test` |
| Python | 见 [bindings/python/README.zh-CN.md](bindings/python/README.zh-CN.md) |
| Unity | 先 `zig build dist`，再 `python3 tools/unity_package.py <file>.tgz` |
| Godot | 先 `zig build godot` 和 `python3 tools/godot_package.py <file>.zip`，再 `bindings/godot/tests/run.sh <godot binary> <file>.zip` |

新增的 C ABI 函数须在同一改动中加入所有绑定。

## 设计文档

设计文档只有英文。

| 文档 | 内容 |
|---|---|
| [docs/architecture.md](docs/architecture.md) | 处理流程、编解码、迁移、改写、验证与比对 |
| [docs/changes/README.md](docs/changes/README.md) | 3.5 到 4.3 的所有运行时变化及处理方式 |
| [docs/changes/rewrites.md](docs/changes/rewrites.md) | 改写及其条件 |
| [docs/changes/needs-a-runtime.md](docs/changes/needs-a-runtime.md) | 目标数据无法复现的语义 |
| [docs/changes/oracle.md](docs/changes/oracle.md) | 比对程序修补或无法覆盖的运行时差异 |

## 发布

| 步骤 | 操作 |
|---|---|
| 版本 | 在 `build.zig.zon`、`bindings/js/package.json`、`bindings/python/pyproject.toml`、`bindings/csharp/Directory.Build.props` 和 `bindings/unity/package.json` 中设置，`tools/versions.sh` 检查它们一致 |
| 说明 | 在 `CHANGELOG.md` 中添加 `## <version>` 一节，作为发布说明 |
| 标签 | 推送 `v<version>`，发布工作流用 `tools/package.sh` 构建全部产物并创建草稿发布 |
| 发布 | 检查草稿后发布 |

## 规则

代码、注释、文档和提交规则见 [AGENTS.md](AGENTS.md)。摘要如下：

| 主题 | 规则 |
|---|---|
| 提交 | `type(scope): one sentence`，无正文，一次提交只做一件事 |
| 注释 | 只写代码本身表达不了的内容，如跨文件的同步约束、外部格式的事实或容易踩的坑，写法自行判断 |
| 文档 | 英文为正本，优先使用表格，面向用户的文档译为 `<name>.zh-CN.md`，贡献者文档只有英文 |
| 运行时变化 | 新的语义变化须有用例、报告代码、`docs/report.md` 中的一行和 `docs/changes` 中的一行，并且要么有经比对验证的改写，要么在 `docs/changes/needs-a-runtime.md` 中写明原因 |
| 素材 | 只提交自己制作的导出，不提交第三方美术资源 |

## 问题反馈

| 类型 | 需提供 |
|---|---|
| 姿势错误或加载失败 | 转换器版本、源和目标的版本与格式、使用的命令或调用、stderr 上的报告、加载结果的运行时及其版本、差异所在 |
| 不支持的导出 | 编辑器写入的版本字符串和格式 |
| 功能需求 | 使用场景和涉及的版本 |

请附上能复现问题、且你有权分享的小型导出文件。没有文件，比对工具无法复现该情况。
