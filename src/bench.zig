const std = @import("std");
const zbench = @import("zbench");

pub fn benchmark(
    allocator: std.mem.Allocator,
    name: []const u8,
    comptime f: fn (std.mem.Allocator) void,
) !void {
    var bench = zbench.Benchmark.init(
        allocator,
        .{},
    );
    defer bench.deinit();
    try bench.add(name, f, .{});
    try bench.run(std.io.getStdIn().writer());
}

pub fn addOne(x: u32) u32 {
    return x + 1;
}

pub fn noop(_: u32) void {}

pub fn log(x: u32) void {
    std.debug.print("x: {}\n", .{x});
}

test {
    std.testing.refAllDecls(@import("bench/propagate.zig"));
    std.testing.refAllDecls(@import("bench/wide.zig"));
}
