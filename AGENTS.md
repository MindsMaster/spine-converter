# Contributor and AI agent rules

## Layout

| Path | Role |
|---|---|
| `include/spine_converter.h` | public C ABI |
| `src/abi.zig` | C ABI exports, the only file that sees C types |
| `src/root.zig` | Zig module root |
| `src/convert.zig` | pipeline from bytes to bytes |
| `src/detect.zig` | format and version detection |
| `src/json.zig` | JSON codec for every version |
| `src/binary.zig` | table of binary codecs |
| `src/binary/` | binary primitives and one codec per minor version |
| `src/migrate.zig` | chain of adjacent migrations |
| `src/migrate/` | one module per adjacent version pair, plus the shared helpers `singular.zig` `order.zig` |
| `src/atlas.zig` | texture atlas text for every version |
| `src/Version.zig` `src/Document.zig` `src/Report.zig` | shared data types |
| `src/edit.zig` | in-place JSON tree edits shared by migrations |
| `cli/` | command line tool |
| `bindings/c/` | docs of the C ABI |
| `bindings/cpp/` | header-only C++ wrapper of the C ABI |
| `bindings/csharp/` | C# binding of the C ABI and its tests |
| `bindings/unity/` | Unity package manifest, assembly definition and docs, packed by `tools/unity_package.py` |
| `bindings/godot/` | GDExtension over the C ABI and its test project, packed by `tools/godot_package.py` |
| `oracle/` | dumpers built from official runtimes, pose comparator, check scripts, fixtures |
| `tests/` | ABI smoke test, corpus runner and damaged input generator |
| `tools/` | scripts that export corpus and runtimes from spine-runtimes, release and package builders |
| `web/` | browser converter over the JS binding, deployed to GitHub Pages by `.github/workflows/pages.yml` |
| `docs/` | user docs `conversion` `report` `stability`, each with a `.zh-CN.md` translation |
| `docs/architecture.md` `docs/changes/` | contributor docs in English only, `docs/changes/README.md` indexes the runtime changes |

## Dependencies

| Module | May import |
|---|---|
| `abi.zig` `cli/` `tests/` `bindings/` | nothing under `src/` except the module root, `bindings/godot` also imports `abi.zig` |
| `convert.zig` | detect, json, binary, migrate, atlas and shared types |
| a codec in `src/binary/` | shared types and `src/binary/` primitives, never another codec |
| a migration in `src/migrate/` | shared types, `edit.zig`, `src/binary/tree.zig` and the shared helpers in `src/migrate/`, never another migration |

`binary.zig` and `migrate.zig` each hold one table. A new version adds one file and one table row.

A reader follows any operation from `convert.zig` to a primitive within three files. No interfaces, managers or wrappers with a single implementation.

Codecs follow the order of `SkeletonBinary.java` in the matching spine-runtimes branch so they can be diffed against it.

## Comments

Write no comments by default on constants, locals, fields, functions and types. Do not restate what a name already says.

No file or function overview blocks. No design intent, performance claims, implementation steps or debugging history. History belongs in commit messages.

Target density is about one comment per 70 lines of ordinary logic.

Only four kinds of comments are worth writing.

| Kind | Example |
|---|---|
| Sync constraint across files or languages | `/// Values mirror spc_status in spine_converter.h` |
| External contract fact from a format, OS API or third party | `/// Byte count plus one prefix zero is null` |
| Name differs from behavior | `// actually event driven not polling` |
| Real trap that intuition gets wrong | `// arena frees the memory holding its own allocator` |

Facts about real external legacy artifacts, such as old export formats, are external contracts and stay. Notes about what an old implementation used to do are history and go.

Public headers count density per field. About a quarter of fields may carry a comment. Public ABI comments remove ambiguity about ownership, lifetime, NULL meaning and flag effects.

### Form

The form rules bind AI agents, which tend to over-comment. Human contributors follow the four kinds above and judge the form themselves.

A comment describing the next item uses the doc form of the language: Zig `///` and `//!`, C and C++ `/** */`. Line comments are only for function bodies and between statements.

A comment is a signpost, not an explanation. Keep it under about 8 English words.

No periods. Replace commas, semicolons and colons with spaces where possible. No parenthetical asides, dashes or lead-in words. Compress reasons into noun phrases. No numbers or causal chains.

No section separators, bold, arrows or numbered lists.

Comment only where code looks redundant or arbitrary: a magic string or number, a branch that looks removable, an odd indirection such as a deferred call or an extra copy.

Tests carry no long assertion messages. The test name is the description. Diagnostic arguments that print actual values stay.

Never remove lint suppressions, formatter directives, license headers or shebangs. Delete commented-out code.

## Docs

Docs follow the same tone. Short statements, tables over prose, no bold, arrows, numbered lists, parenthetical asides or dashes. State facts, not the reasoning behind them.

English is the source. Docs for users, the root README and each binding README get a translation beside them as `<name>.zh-CN.md`, and a change updates both. Contributor docs stay English only. Each binding documents its install and use in its own README, the root README links to it.

## Code

Zig code is formatted by `zig fmt`. C and C++ are formatted by hand with a 100 column limit. A call or signature that does not fit puts one parameter per line and the closing parenthesis on its own line.

```c
SPC_API spc_status spc_convert(
    const uint8_t *data,
    size_t length,
    const spc_options *options,
    const spc_allocator *allocator,
    spc_result **out
);
```

Do not extract helpers for one-off operations or abstract for hypothetical needs.

Do not validate states internal code cannot produce. Validate only at system boundaries: user input, files and the C ABI.

Remove probes, diagnostic logging and fixes made under disproven assumptions once the problem is located.

Confirm the root cause with data before fixing. Do not stack patches.

New code reads like the surrounding code in naming, idioms and comment density.

## Commits

Format `type(scope): one sentence` with no body.

| Part | Rule |
|---|---|
| type | feat, fix, perf, refactor, chore |
| scope | affected module such as detect, abi, binary, migrate, oracle, build |
| sentence | the result, not the mechanism, short and plain |

One commit does one thing.

```
feat(detect): detect format and version of every Spine export
fix(oracle): sample half frames to avoid stepped keys
```

## Verification

Run before delivering. `oracle/all.sh` builds once and runs all of it at once, each script also runs alone.

```
zig fmt --check src cli tests oracle bindings/godot/src build.zig
zig build test
zig build -Doptimize=ReleaseSafe
zig build corpus -Doptimize=ReleaseSafe
zig build oracle
oracle/selfcheck.sh 3.5 3.6 3.7 3.8 4.0 4.1 4.2 4.3
oracle/codec.sh 3.5 3.6 3.7 3.8 4.0 4.1 4.2 4.3
oracle/atlas.sh 3.5 3.6 3.7 3.8 4.0 4.1 4.2 4.3
oracle/fixtures.sh
oracle/migrate.sh 3.5 3.6 && oracle/migrate.sh 3.6 3.5
oracle/migrate.sh 3.6 3.7 && oracle/migrate.sh 3.7 3.6
oracle/migrate.sh 3.7 3.8 && oracle/migrate.sh 3.8 3.7
oracle/migrate.sh 3.8 4.0 && oracle/migrate.sh 4.0 3.8
oracle/migrate.sh 4.0 4.1 && oracle/migrate.sh 4.1 4.0
oracle/migrate.sh 4.1 4.2 && oracle/migrate.sh 4.2 4.1
oracle/migrate.sh 4.2 4.3 && oracle/migrate.sh 4.3 4.2
oracle/migrate.sh 3.8 4.3 && oracle/migrate.sh 4.3 3.8
oracle/migrate.sh 3.7 4.3 && oracle/migrate.sh 4.3 3.7
oracle/migrate.sh 3.6 4.3 && oracle/migrate.sh 4.3 3.6
oracle/migrate.sh 3.5 4.3 && oracle/migrate.sh 4.3 3.5
oracle/csharp.sh 3.5 3.6 3.7 3.8 4.0 4.1 4.2 4.3
oracle/hostile.sh
oracle/variants.sh
zig build dist
dotnet run --project bindings/csharp/Tests
```

The oracle scripts run their cases in parallel, `ORACLE_JOBS` at once and every core by default. A case holds a token from a fifo while it runs, and `oracle/all.sh` shares one fifo through `ORACLE_POOL` so concurrent scripts never run more cases than that. Each case keeps its dumps in its own directory under `ORACLE_TMP`, `/tmp` by default, and removes them when done. Output comes in case order once every case has finished. A Debug CLI makes the oracle many times slower. The C# dumpers need `dotnet` with the .NET 8 SDK on `PATH`, or `DOTNET` naming it.

Cross builds install into their own prefix such as `zig build -Dtarget=x86_64-windows -p zig-out/x86_64-windows`. `zig build dist` installs the shared libraries into `zig-out/dist/<rid>`, named by .NET runtime identifier. The C# tests load the library of the host from there and need `zig build dist` first.

Report anything not compiled or not run. Report failing tests with their output.
