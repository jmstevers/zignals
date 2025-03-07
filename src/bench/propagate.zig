const std = @import("std");
const z = @import("../root.zig");
const bench = @import("../bench.zig");
const Dependency = @import("../Dependency.zig");
const addOne = bench.addOne;
const noop = bench.noop;
const benchmark = bench.benchmark;

const height = 100;
const width = 100;

var deep_signal: *z.Signal(u32) = undefined;
var chains: [width]DeepChain = undefined;

const DeepChain: type = blk: {
    @setEvalBranchQuota(20_000_000);

    var types: [height + 1]type = undefined;
    types[0] = *z.Derived(addOne, 1);

    for (1..height) |i| {
        types[i] = *z.Derived(addOne, 1);
    }

    types[height] = *z.Effect(noop, 1);

    break :blk std.meta.Tuple(&types);
};

fn propagate(_: std.mem.Allocator) void {
    deep_signal.set(deep_signal.get() + 1);
}

test propagate {
    @setEvalBranchQuota(20_000_000);

    var arena = std.heap.ArenaAllocator.init(std.heap.smp_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    deep_signal = z.signalT(u32, 0);

    for (0..width) |i| {
        chains[i][0] = try z.derived(allocator, addOne, .{deep_signal});
        inline for (1..height) |j| {
            chains[i][j] = try z.derived(allocator, addOne, .{chains[i][j - 1]});
        }
        chains[i][height] = try z.effect(allocator, noop, .{chains[i][height - 1]});
    }

    try benchmark(allocator, "propagate", propagate);
}
