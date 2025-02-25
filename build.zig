const std = @import("std");

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const build_tools = b.option(bool, "tools", "Build the gifsicle tools") orelse true;
    const dynamic = b.option(bool, "dynamic", "Build dynamic library") orelse false;
    const terminalAvailable = b.option(bool, "terminal", "Output gif to terminal") orelse true;

    const gifsicle_upstream = b.dependency("gifsicle_upstream", .{});

    const lib_config = .{
        .name = "gifsicle",
        .target = target,
        .optimize = optimize,
        .link_libc = true,
        .pic = true,
    };
    const lib = if (dynamic) b.addSharedLibrary(lib_config) else b.addStaticLibrary(lib_config);

    lib.addIncludePath(gifsicle_upstream.path("include"));

    const version = "1.95-zig"; // TODO: import version

    const t = lib.rootModuleTarget();

    const is32Bit = t.ptrBitWidth() == 32;
    const isWindows = t.os.tag == .windows;

    const haveX11 = !isWindows;

    // std.Target.x86.featureSetHas(t.getCpuFeatures(), .simd);
    const config_h = b.addConfigHeader(.{ .style = .{ .cmake = b.path("winconf.h.in") }, .include_path = "config.h" }, .{
        .GIF_ALLOCATOR_DEFINED = 1,
        .HAVE_INT64_T = 1,
        .X_DISPLAY_MISSING = @intFromBool(!haveX11),
        .HAVE_MKSTEMP = @intFromBool(!isWindows),
        .HAVE_POW = 1,
        .HAVE_STRERROR = 1,
        .HAVE_STRTOUL = 1,
        .HAVE_UINT64_T = 1, // search for unused types
        .HAVE_UINTPTR_T = 1,
        .OUTPUT_GIF_TO_TERMINAL = if (terminalAvailable) null else @as(?u1, 1),
        .ENABLE_THREADS = @intFromBool(!isWindows), // pthread.h not on windows
        .HAVE_SIMD = 1, // TODO: check target and enable as needed
        .HAVE_VECTOR_SIZE_VECTOR_TYPES = 1,
        //HAVE___BUILTIN_SHUFFLEVECTOR
        //HAVE___SYNC_ADD_AND_FETCH

        .HAVE_STDINT_H = 1,
        .HAVE_INTTYPES_H = 1,
        .HAVE_SYS_STAT_H = 1,
        .HAVE_SYS_TYPES_H = 1,
        .HAVE_UNISTD_H = @intFromBool(terminalAvailable),

        .SIZEOF_FLOAT = 4,
        .SIZEOF_UNSIGNED_INT = 4,
        .SIZEOF_VOID_P = @as(u8, if (is32Bit) 4 else 8),
        .SIZEOF_UNSIGNED_LONG = @as(u8, if (is32Bit or isWindows) 4 else 8),

        .PATHNAME_SEPARATOR = if (isWindows) "\\\\" else "/",
        .RANDOM = "rand",
        .GIF_FREE = "free",
        .IS_WINDOWS = @intFromBool(isWindows),

        .VERSION = version,
    });

    lib.root_module.addCMacro("HAVE_CONFIG_H", "1");

    lib.installHeader(gifsicle_upstream.path("src/gifsicle.h"), "gifsicle.h");
    lib.installHeadersDirectory(gifsicle_upstream.path("include"), ".", .{});

    lib.addConfigHeader(config_h);
    lib.installConfigHeader(config_h);
    lib.addCSourceFiles(.{ .root = gifsicle_upstream.path("."), .files = &gifsicle_sources, .flags = gifsicle_cflags });
    b.installArtifact(lib);

    ////

    const gifsicle = b.addExecutable(.{
        .name = "gifsicle-cli",
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });
    gifsicle.linkLibrary(lib);
    // gifsicle.addConfigHeader(config_h);
    gifsicle.addCSourceFile(.{ .file = gifsicle_upstream.path("src/gifsicle.c"), .flags = &.{} });

    const gifview = b.addExecutable(.{
        .name = "gifview-cli",
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });
    gifview.linkLibrary(lib);
    // gifview.addConfigHeader(config_h);
    gifview.addCSourceFiles(.{ .root = gifsicle_upstream.path("."), .files = &gifview_sources });
    gifview.linkSystemLibrary2("X11", .{});
    gifview.root_module.addCMacro("HAVE_CONFIG_H", "1");

    const gifdiff = b.addExecutable(.{
        .name = "gifdiff-cli",
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });
    gifdiff.linkLibrary(lib);
    // gifdiff.addConfigHeader(config_h);
    gifdiff.addCSourceFile(.{ .file = gifsicle_upstream.path("src/gifdiff.c"), .flags = &.{} });

    if (build_tools) {
        b.installArtifact(gifsicle);

        if (!dynamic) {
            if (haveX11) b.installArtifact(gifview);
            b.installArtifact(gifdiff);
        }
    }
}

const gifsicle_sources = [_][]const u8{
    "src/clp.c",
    "src/fmalloc.c",
    "src/giffunc.c",
    "src/gifread.c",
    "src/gifunopt.c",
    "src/gifwrite.c",
    "src/merge.c",
    "src/optimize.c",
    "src/quantize.c",
    "src/support.c",
    "src/xform.c",
};

const gifview_sources = [_][]const u8{
    "src/gifview.c",
    "src/gifx.c",
};

const gifsicle_cflags: []const []const u8 = &.{
    // "-std=c89",
    // "-W", "-Wall"
};
