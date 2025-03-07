const std = @import("std");
const zbench = @import("zbench");
const z = @import("root.zig");

fn benchmark(allocator: std.mem.Allocator, name: []const u8, comptime f: fn (std.mem.Allocator) void) !void {
    var bench = zbench.Benchmark.init(
        allocator,
        .{
            .iterations = 1000,
        },
    );
    defer bench.deinit();
    try bench.add(name, f, .{});
    try bench.run(std.io.getStdIn().writer());
}

fn addOne(x: u32) u32 {
    return x + 1;
}

fn noop(_: u32) void {}

fn log(x: u32) void {
    std.debug.print("x: {}\n", .{x});
}

var global_signal: *z.Signal(u32) = undefined;

fn propagate(_: std.mem.Allocator) void {
    global_signal.set(global_signal.get() + 1);
}

const height = 1000;
const width = 1000;

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

var chains: [width]DeepChain = undefined;

test propagate {
    @setEvalBranchQuota(20_000_000);

    var arena = std.heap.ArenaAllocator.init(std.heap.smp_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    global_signal = z.signalT(u32, 0);

    for (0..width) |i| {
        chains[i][0] = try z.derived(allocator, addOne, .{global_signal});
        inline for (1..height) |j| {
            chains[i][j] = try z.derived(allocator, addOne, .{chains[i][j - 1]});
        }
        chains[i][height] = try z.effect(allocator, noop, .{chains[i][height - 1]});
    }

    try benchmark(allocator, "propagate", propagate);
}

fn wide(
    a: u32,
    b: u32,
    c: u32,
    d: u32,
    e: u32,
    f: u32,
    g: u32,
    h: u32,
    i: u32,
    j: u32,
    k: u32,
    l: u32,
    m: u32,
    n: u32,
    o: u32,
    p: u32,
) u32 {
    return a +
        b +
        c +
        d +
        e +
        f +
        g +
        h +
        i +
        j +
        k +
        l +
        m +
        n +
        o +
        p;
}

const Deps = struct {
    *z.Signal(u32),
    *z.Signal(u32),
    *z.Signal(u32),
    *z.Signal(u32),
    *z.Signal(u32),
    *z.Signal(u32),
    *z.Signal(u32),
    *z.Signal(u32),
    *z.Signal(u32),
    *z.Signal(u32),
    *z.Signal(u32),
    *z.Signal(u32),
    *z.Signal(u32),
    *z.Signal(u32),
    *z.Signal(u32),
    *z.Signal(u32),
};

var global_derived: *z.Derived(wide, 16) = undefined;
var global_deps: Deps = undefined;

fn wideGraph(_: std.mem.Allocator) void {
    inline for (global_deps) |dep| {
        dep.set(dep.get() + 1);
    }
    _ = global_derived.get();
}

test wideGraph {
    var arena = std.heap.ArenaAllocator.init(std.heap.smp_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var deps: Deps = undefined;
    inline for (deps, 0..) |_, i| {
        deps[i] = z.signalT(u32, 0);
    }

    global_deps = deps;
    global_derived = try z.derived(allocator, wide, global_deps);

    try benchmark(allocator, "wide graph", wideGraph);
}
