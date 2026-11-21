[English](CONTRIBUTING.md) | [中文](CONTRIBUTING.zh-CN.md)

# Contributing

## Environment

| Tool | Needed for |
|---|---|
| [Zig](https://ziglang.org/download/) 0.17.x | everything |
| bash | oracle and tool scripts |
| .NET 8 SDK | C# binding, C# oracle dumpers |
| Node with pnpm | JavaScript binding |
| Python 3.10 or later | Python binding |
| a clone of [spine-runtimes](https://github.com/EsotericSoftware/spine-runtimes) | example exports and official runtimes for the oracle |

```
zig build
zig build test
tools/fetch-corpus.sh <spine-runtimes clone>
tools/fetch-runtimes.sh <spine-runtimes clone>
oracle/all.sh
```

`testdata` holds the fetched exports and runtimes and is never committed.

## Checks

`oracle/all.sh` builds once and runs every check, each script also runs alone. A change is ready when all of them pass, the list is in [AGENTS.md](AGENTS.md).

| Check | Proves |
|---|---|
| `zig build test` | unit tests and the report code table |
| `oracle/codec.sh` | JSON and skel round trips keep the poses of the source |
| `oracle/migrate.sh` | converted data poses like the source in the official runtimes |
| `oracle/fixtures.sh` | each runtime change in `oracle/fixtures` is rewritten or reported as listed |
| `oracle/variants.sh` | mutated exports keep poses or report the loss |
| `oracle/hostile.sh` | damaged input fails without a crash, hang or unreadable output |

## Bindings

| Binding | Test |
|---|---|
| C and C++ | part of `zig build test` |
| Android | `zig build dist -Drid=android-x64 -Dandroid-ndk=<path>` and the same for `android-arm64`, then `tests/android.sh <path>` with a device or emulator on adb |
| C# | `dotnet run --project bindings/csharp/Tests` after `zig build dist` |
| JavaScript | `pnpm install`, `pnpm run build` and `pnpm test` in `bindings/js` after `zig build wasm` |
| Python | see [bindings/python/README.md](bindings/python/README.md) |
| Unity | `zig build dist`, then `python3 tools/unity_package.py <file>.tgz` |
| Godot | `zig build godot`, `python3 tools/godot_package.py <file>.zip`, then `bindings/godot/tests/run.sh <godot binary> <file>.zip` |

A new C ABI function reaches every binding in the same change.

## Design documents

| Document | Content |
|---|---|
| [docs/architecture.md](docs/architecture.md) | pipeline, codecs, migrations, rewrites, verification and the oracle |
| [docs/changes/README.md](docs/changes/README.md) | every runtime change from 3.5 to 4.3 and its handling |
| [docs/changes/rewrites.md](docs/changes/rewrites.md) | rewrites and their conditions |
| [docs/changes/needs-a-runtime.md](docs/changes/needs-a-runtime.md) | semantics no target data reproduces |
| [docs/changes/oracle.md](docs/changes/oracle.md) | runtime differences the oracle patches or misses |

## Releases

| Step | Action |
|---|---|
| version | set it in `build.zig.zon`, `bindings/js/package.json`, `bindings/python/pyproject.toml`, `bindings/csharp/Directory.Build.props` and `bindings/unity/package.json`, `tools/versions.sh` checks they agree |
| notes | add a `## <version>` section to `CHANGELOG.md`, it becomes the release text |
| tag | push `v<version>`, the release workflow builds every artifact with `tools/package.sh` and opens a draft release |
| publish | review the draft and publish it |

## Rules

Code, comment, doc and commit rules are in [AGENTS.md](AGENTS.md). In short:

| Topic | Rule |
|---|---|
| Commits | `type(scope): one sentence`, no body, one change per commit |
| Comments | only what the code cannot say, such as a sync constraint, an external format fact or a trap, the form is up to you |
| Docs | English is the source, tables over prose, user docs translated as `<name>.zh-CN.md`, contributor docs English only |
| Runtime changes | a new semantics change gets a fixture, a report code, a row in `docs/report.md` and a row in `docs/changes`, then either a rewrite proven by the oracle or a row in `docs/changes/needs-a-runtime.md` with the reason |
| Assets | commit only exports you made yourself, never third party art |

## Issues

| Kind | Include |
|---|---|
| Wrong pose or load failure | converter version, source and target version and format, the command or call, the report on stderr, the runtime and version that loads the result, what differs |
| Unsupported export | the version string the editor wrote and the format |
| Feature | the use case and the versions involved |

Attach a small export that shows the problem and that you have the right to share. Without one, the oracle cannot reproduce the case.
