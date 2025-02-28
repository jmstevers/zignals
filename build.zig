const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const dep_opts = .{ .target = target, .optimize = optimize };

    const max_dependencies = b.option(
        u8,
        "max_dependencies",
        "Set the maximum number of dependencies",
    ) orelse 16;
    const max_subscribers = b.option(
        u8,
        "max_subscribers",
        "Set the maximum number of subscribers",
    ) orelse 16;

    const options = b.addOptions();
    options.addOption(u32, "max_dependencies", max_dependencies);
    options.addOption(u32, "max_subscribers", max_subscribers);

    const zignals = b.addModule("zignals", .{
        .root_source_file = b.path("src/root.zig"),
    });

    zignals.addOptions("config", options);

    {
        const tests = b.addTest(.{
            .root_source_file = b.path("src/tests.zig"),
            .target = target,
            .optimize = optimize,
            .test_runner = .{
                .mode = .simple,
                .path = b.path("test_runner.zig"),
            },
        });

        tests.root_module.addOptions("config", options);

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

        bench.root_module.addOptions("config", options);

        const zbench = b.dependency("zbench", dep_opts).module("zbench");
        bench.root_module.addImport("zbench", zbench);

        const run_bench = b.addRunArtifact(bench);
        run_bench.has_side_effects = true;

        const bench_step = b.step("bench", "Run benchmarks");
        bench_step.dependOn(&run_bench.step);
    }
}
