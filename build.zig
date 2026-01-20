const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    _ = b.addModule("see-zig-sdk", .{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    const lib = b.addLibrary(.{
        .linkage = .static,
        .name = "see-zig-sdk",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });

    b.installArtifact(lib);

    const main_tests = b.addTest(.{
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });

    const run_main_tests = b.addRunArtifact(main_tests);

    const test_step = b.step("test", "Run library tests");
    test_step.dependOn(&run_main_tests.step);

    const examples = [_][]const u8{
        "shorten",
        "text",
        "file",
    };

    for (examples) |ex_name| {
        const ex_exe = b.addExecutable(.{
            .name = ex_name,
            .root_module = b.createModule(.{
                .root_source_file = b.path(b.fmt("examples/{s}.zig", .{ex_name})),
                .target = target,
                .optimize = optimize,
            }),
        });
        ex_exe.root_module.addImport("see-zig-sdk", lib.root_module);

        const run_ex = b.addRunArtifact(ex_exe);
        // Pass arguments to the example if needed
        if (b.args) |args| {
            run_ex.addArgs(args);
        }

        const run_step = b.step(b.fmt("example-{s}", .{ex_name}), b.fmt("Run the {s} example", .{ex_name}));
        run_step.dependOn(&run_ex.step);
    }
}
