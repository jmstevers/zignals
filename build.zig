const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const dep_opts = .{ .target = target, .optimize = optimize };

    const zignals = b.addModule("zignals", .{
        .root_source_file = b.path("src/root.zig"),
    });
    _ = zignals;

    {
        const tests = b.addTest(.{
            .root_source_file = b.path("src/tests.zig"),
            .target = target,
            .optimize = optimize,
            .test_runner = .{
                .mode = .simple,
                .path = b.path("test_runner.zig"),
            },
            .use_llvm = false,
        });

        const run_test = b.addRunArtifact(tests);
        run_test.has_side_effects = true;

        const test_step = b.step("test", "Run tests");
        test_step.dependOn(&run_test.step);
    }

    {
        const bench = b.addTest(.{
            .root_source_file = b.path("src/bench.zig"),
            .target = target,
            .optimize = .ReleaseFast,
            .test_runner = .{
                .mode = .simple,
                .path = b.path("test_runner.zig"),
            },
        });

        const zbench = b.dependency("zbench", dep_opts).module("zbench");
        bench.root_module.addImport("zbench", zbench);

        const run_bench = b.addRunArtifact(bench);
        run_bench.has_side_effects = true;

        const bench_step = b.step("bench", "Run benchmarks");
        bench_step.dependOn(&run_bench.step);
    }
}
