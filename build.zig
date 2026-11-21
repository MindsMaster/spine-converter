const std = @import("std");
const version = @import("build.zig.zon").version;

/// number is major * 100 + minor, the SPINE_VERSION of the dumper source
const Oracle = struct { version: []const u8, number: u32, source: []const u8, runtime: []const u8 = "spine-cpp" };
const oracles = [_]Oracle{
    .{ .version = "3.5", .number = 305, .source = "oracle/dump_c.c", .runtime = "spine-c" },
    .{ .version = "3.6", .number = 306, .source = "oracle/dump_c.c", .runtime = "spine-c" },
    .{ .version = "3.7", .number = 307, .source = "oracle/dump.cpp" },
    .{ .version = "3.8", .number = 308, .source = "oracle/dump.cpp" },
    .{ .version = "4.0", .number = 400, .source = "oracle/dump.cpp" },
    .{ .version = "4.1", .number = 401, .source = "oracle/dump.cpp" },
    .{ .version = "4.2", .number = 402, .source = "oracle/dump.cpp" },
    .{ .version = "4.3", .number = 403, .source = "oracle/dump_4.3.cpp" },
};

/// rid is the .NET runtime identifier the C# binding loads from, godot the feature tag of the Godot extension
const Dist = struct { triple: []const u8, rid: []const u8, godot: []const u8, libc: LibC = .zig };
/// Zig ships no bionic
const LibC = enum { zig, ndk };
const dists = [_]Dist{
    .{ .triple = "x86_64-windows", .rid = "win-x64", .godot = "windows.x86_64" },
    .{ .triple = "aarch64-windows", .rid = "win-arm64", .godot = "windows.arm64" },
    .{ .triple = "x86-windows", .rid = "win-x86", .godot = "windows.x86_32" },
    .{ .triple = "aarch64-macos.11.0", .rid = "osx-arm64", .godot = "macos.arm64" },
    .{ .triple = "x86_64-macos.10.15", .rid = "osx-x64", .godot = "macos.x86_64" },
    .{ .triple = "x86_64-linux", .rid = "linux-x64", .godot = "linux.x86_64" },
    .{ .triple = "aarch64-linux", .rid = "linux-arm64", .godot = "linux.arm64" },
    .{ .triple = "aarch64-linux-android.21", .rid = "android-arm64", .godot = "android.arm64", .libc = .ndk },
    .{ .triple = "x86_64-linux-android.21", .rid = "android-x64", .godot = "android.x86_64", .libc = .ndk },
};

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const info = b.addOptions();
    info.addOption([]const u8, "version", libraryVersion(b));
    build_info = info.createModule();
    const core = b.addModule("spine_converter", coreOptions(b, target, optimize));
    core.addAnonymousImport("report.md", .{ .root_source_file = b.path("docs/report.md") });
    core.addAnonymousImport("report.zh-CN.md", .{ .root_source_file = b.path("docs/report.zh-CN.md") });

    const lib = b.addLibrary(.{
        .name = "spine_converter",
        .linkage = .static,
        .root_module = abiModule(b, core),
    });
    const strip = b.option(bool, "strip", "Strip debug info from the CLI and the static library");
    lib.root_module.strip = strip;
    b.installArtifact(lib);
    b.installFile("include/spine_converter.h", "include/spine_converter.h");
    b.installFile("bindings/cpp/spine_converter.hpp", "include/spine_converter.hpp");

    const dist = b.step("dist", "Build the shared library for every release platform");
    const godot = b.step("godot", "Build the Godot extension for every release platform");
    const only = b.option([]const u8, "rid", "Build dist and godot for this runtime identifier only");
    const ndk = b.option([]const u8, "android-ndk", "Android NDK to build the Android targets with, skipped without");
    for (dists) |d| {
        if (only) |rid| if (!std.mem.eql(u8, rid, d.rid)) continue;
        const query = std.Target.Query.parse(.{ .arch_os_abi = d.triple }) catch unreachable;
        const resolved = b.resolveTargetQuery(query);
        const libc: ?std.Build.LazyPath = switch (d.libc) {
            .zig => null,
            .ndk => if (ndk) |path| androidLibC(b, path, resolved.result) else {
                if (only != null) {
                    const fail = b.addFail(b.fmt("{s} needs -Dandroid-ndk", .{d.rid}));
                    dist.dependOn(&fail.step);
                    godot.dependOn(&fail.step);
                }
                continue;
            },
        };
        // Google Play page size requirement
        const max_page_size: ?u64 = if (libc != null) 16 * 1024 else null;
        const core_module = b.createModule(coreOptions(b, resolved, .ReleaseFast));
        if (libc != null) core_module.link_libc = true;
        const abi = abiModule(b, core_module);
        const shared = b.addLibrary(.{
            .name = "spine_converter",
            .linkage = .dynamic,
            .root_module = abi,
        });
        shared.root_module.strip = true;
        shared.setLibCFile(libc);
        shared.link_z_max_page_size = max_page_size;
        const dir: std.Build.InstallDir = .{ .custom = b.fmt("dist/{s}", .{d.rid}) };
        dist.dependOn(&b.addInstallArtifact(shared, .{
            .dest_dir = .{ .override = dir },
            .implib_dir = if (query.os_tag == .windows) .{ .override = .{ .custom = b.fmt("dist-implib/{s}", .{d.rid}) } } else .disabled,
            .pdb_dir = .disabled,
            .h_dir = .disabled,
        }).step);

        const extension = b.addLibrary(.{
            .name = "spine_converter_godot",
            .linkage = .dynamic,
            .root_module = b.createModule(.{
                .root_source_file = b.path("bindings/godot/src/extension.zig"),
                .target = abi.resolved_target,
                .optimize = .ReleaseFast,
                .strip = true,
                .imports = &.{.{ .name = "abi", .module = abi }},
            }),
        });
        extension.setLibCFile(libc);
        extension.link_z_max_page_size = max_page_size;
        godot.dependOn(&b.addInstallArtifact(extension, .{
            .dest_dir = .{ .override = .{ .custom = b.fmt("godot/{s}", .{d.godot}) } },
            .implib_dir = .disabled,
            .pdb_dir = .disabled,
            .h_dir = .disabled,
        }).step);
    }

    const wasm_target = b.resolveTargetQuery(.{ .cpu_arch = .wasm32, .os_tag = .freestanding });
    const wasm = b.addExecutable(.{
        .name = "spine_converter",
        .root_module = abiModule(b, b.createModule(coreOptions(b, wasm_target, .ReleaseSmall))),
    });
    wasm.entry = .disabled;
    wasm.root_module.strip = true;
    wasm.rdynamic = true;
    b.step("wasm", "Build the WebAssembly module").dependOn(&b.addInstallArtifact(wasm, .{}).step);

    const cli = b.addExecutable(.{
        .name = "spine-converter",
        .root_module = importing(b, "cli/main.zig", core, optimize),
    });
    cli.root_module.strip = strip;
    b.installArtifact(cli);
    const run_cli = b.addRunArtifact(cli);
    run_cli.addPassthruArgs();
    b.step("run", "Run the CLI").dependOn(&run_cli.step);

    const test_step = b.step("test", "Run unit and ABI tests");
    test_step.dependOn(&b.addRunArtifact(b.addTest(.{ .root_module = core })).step);
    const abi_smoke = b.addExecutable(.{
        .name = "abi_smoke",
        .root_module = b.createModule(.{ .target = target, .optimize = optimize, .link_libc = true }),
    });
    abi_smoke.root_module.addCSourceFile(.{
        .file = b.path("tests/abi_smoke.c"),
        .flags = &.{ "-std=c99", "-Wall", "-Wextra", "-Werror" },
    });
    abi_smoke.root_module.addIncludePath(b.path("include"));
    abi_smoke.root_module.linkLibrary(lib);
    test_step.dependOn(&b.addRunArtifact(abi_smoke).step);
    const cpp_smoke = b.addExecutable(.{
        .name = "cpp_smoke",
        .root_module = b.createModule(.{ .target = target, .optimize = optimize, .link_libcpp = true }),
    });
    cpp_smoke.root_module.addCSourceFile(.{
        .file = b.path("tests/cpp_smoke.cpp"),
        .flags = &.{ "-std=c++17", "-Wall", "-Wextra", "-Werror" },
    });
    cpp_smoke.root_module.addIncludePath(b.path("include"));
    cpp_smoke.root_module.addIncludePath(b.path("bindings/cpp"));
    cpp_smoke.root_module.linkLibrary(lib);
    test_step.dependOn(&b.addRunArtifact(cpp_smoke).step);

    const corpus = b.addExecutable(.{
        .name = "corpus",
        .root_module = importing(b, "tests/corpus.zig", core, optimize),
    });
    const run_corpus = b.addRunArtifact(corpus);
    run_corpus.addPassthruArgs();
    b.step("corpus", "Check every file of testdata/corpus").dependOn(&run_corpus.step);

    const hostile = b.addExecutable(.{
        .name = "hostile",
        .root_module = importing(b, "tests/hostile.zig", b.createModule(coreOptions(b, target, .ReleaseSafe)), .ReleaseSafe),
    });

    const oracle_step = b.step("oracle", "Build oracle dumpers from testdata/runtimes");
    oracle_step.dependOn(&b.addInstallArtifact(hostile, .{}).step);
    const compare = b.addExecutable(.{
        .name = "pose-compare",
        .root_module = b.createModule(.{
            .root_source_file = b.path("oracle/compare.zig"),
            .target = target,
            .optimize = .ReleaseSafe,
        }),
    });
    oracle_step.dependOn(&b.addInstallArtifact(compare, .{}).step);
    const scope = b.addExecutable(.{
        .name = "pose-scope",
        .root_module = importing(b, "oracle/scope.zig", core, .ReleaseSafe),
    });
    oracle_step.dependOn(&b.addInstallArtifact(scope, .{}).step);
    for (oracles) |oracle| {
        const dumper = oracleDumper(b, target, oracle) orelse continue;
        oracle_step.dependOn(&b.addInstallArtifact(dumper, .{}).step);
    }
}

var build_info: *std.Build.Module = undefined;

fn coreOptions(b: *std.Build, target: std.Build.ResolvedTarget, optimize: std.builtin.OptimizeMode) std.Build.Module.CreateOptions {
    return .{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
        .imports = b.allocator.dupe(std.Build.Module.Import, &.{.{ .name = "build_info", .module = build_info }}) catch @panic("OOM"),
    };
}

/// Semver build metadata carries the commit
fn libraryVersion(b: *std.Build) []const u8 {
    const commit = b.option([]const u8, "commit", "Commit appended to the version, default from git") orelse gitCommit(b) orelse return version;
    return if (commit.len == 0) version else b.fmt("{s}+{s}", .{ version, commit });
}

/// Null outside a git checkout of this package
fn gitCommit(b: *std.Build) ?[]const u8 {
    b.root.access(b.graph.io, ".git", .{}) catch return null;
    const root = b.root.toString(b.allocator) catch @panic("OOM");
    const dir = if (root.len == 0) "." else root;
    var code: u8 = undefined;
    // configure reruns only when these files change
    b.dependOnFileContents(b.path(".git/HEAD"));
    if (b.runAllowFail(&.{ "git", "-C", dir, "symbolic-ref", "-q", "HEAD" }, &code, .ignore)) |ref| {
        const loose = b.fmt(".git/{s}", .{std.mem.trim(u8, ref, " \r\n")});
        const exists = if (b.root.access(b.graph.io, loose, .{})) true else |_| false;
        b.dependOnFileContents(b.path(if (exists) loose else ".git/packed-refs"));
    } else |_| {}
    const out = b.runAllowFail(&.{ "git", "-C", dir, "rev-parse", "--short=12", "HEAD" }, &code, .ignore) catch return null;
    return std.mem.trim(u8, out, " \r\n");
}

fn abiModule(b: *std.Build, core: *std.Build.Module) *std.Build.Module {
    return b.createModule(.{
        .root_source_file = b.path("src/abi.zig"),
        .target = core.resolved_target,
        .optimize = core.optimize,
        .imports = &.{.{ .name = "spine_converter", .module = core }},
    });
}

/// Libc file over the NDK sysroot, crt objects per API level
fn androidLibC(b: *std.Build, ndk: []const u8, target: std.Target) std.Build.LazyPath {
    const host = switch (b.graph.host.result.os.tag) {
        .windows => "windows-x86_64",
        .macos => "darwin-x86_64",
        else => "linux-x86_64",
    };
    const usr = b.pathJoin(&.{ ndk, "toolchains", "llvm", "prebuilt", host, "sysroot", "usr" });
    const triple = b.fmt("{t}-linux-android", .{target.cpu.arch});
    const crt = b.pathJoin(&.{ usr, "lib", triple, b.fmt("{d}", .{target.os.version_range.linux.android}) });
    return b.addWriteFiles().add("libc.txt", b.fmt(
        \\include_dir={s}
        \\sys_include_dir={s}
        \\cc_dir={s}
        \\crt_dir={s}
        \\msvc_lib_dir=
        \\kernel32_lib_dir=
        \\darwin_sdk_dir=
        \\
    , .{ b.pathJoin(&.{ usr, "include" }), b.pathJoin(&.{ usr, "include", triple }), crt, crt }));
}

fn importing(b: *std.Build, path: []const u8, core: *std.Build.Module, optimize: std.builtin.OptimizeMode) *std.Build.Module {
    return b.createModule(.{
        .root_source_file = b.path(path),
        .target = core.resolved_target,
        .optimize = optimize,
        .imports = &.{.{ .name = "spine_converter", .module = core }},
    });
}

/// Null when tools/fetch-runtimes.sh has not exported the version
fn oracleDumper(b: *std.Build, target: std.Build.ResolvedTarget, oracle: Oracle) ?*std.Build.Step.Compile {
    const runtime = b.fmt("testdata/runtimes/{s}/{s}", .{ oracle.version, oracle.runtime });
    const source_dir = b.fmt("{s}/src/spine", .{runtime});
    const c = std.mem.eql(u8, oracle.runtime, "spine-c");
    const sources = sourceFiles(b, source_dir, if (c) ".c" else ".cpp") orelse return null;
    const standard = if (c) "-std=gnu99" else "-std=c++11";
    const dumper = b.addExecutable(.{
        .name = b.fmt("oracle-{s}", .{oracle.version}),
        .root_module = b.createModule(.{ .target = target, .optimize = .ReleaseSafe, .link_libc = c, .link_libcpp = !c }),
    });
    dumper.root_module.addIncludePath(b.path(b.fmt("{s}/include", .{runtime})));
    dumper.root_module.addCSourceFile(.{
        .file = b.path(oracle.source),
        .flags = &.{ standard, b.fmt("-DSPINE_VERSION={d}", .{oracle.number}) },
    });
    // spine-c shifts into the sign bit and copies zero bytes from null
    const flags: []const []const u8 = if (c) &.{ standard, "-w", "-fno-sanitize=shift,nonnull-attribute" } else &.{ standard, "-w" };
    dumper.root_module.addCSourceFiles(.{ .root = b.path(source_dir), .files = sources, .flags = flags });
    return dumper;
}

fn sourceFiles(b: *std.Build, sub_path: []const u8, extension: []const u8) ?[]const []const u8 {
    const io = b.graph.io;
    var dir = b.root.root_dir.handle.openDir(io, b.pathJoin(&.{ b.root.sub_path, sub_path }), .{ .iterate = true }) catch return null;
    defer dir.close(io);
    var files: std.ArrayList([]const u8) = .empty;
    var it = dir.iterate();
    while (it.next(io) catch return null) |entry| {
        if (entry.kind == .file and std.mem.endsWith(u8, entry.name, extension)) {
            files.append(b.allocator, b.dupe(entry.name)) catch @panic("OOM");
        }
    }
    return files.items;
}
