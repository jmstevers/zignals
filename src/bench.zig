const std = @import("std");
const zbench = @import("zbench");
const zignals = @import("root.zig");

fn benchmark(name: []const u8, comptime f: fn (std.mem.Allocator) void) !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.smp_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var bench = zbench.Benchmark.init(
        allocator,
        .{},
    );
    defer bench.deinit();
    try bench.add(name, f, .{});
    try bench.run(std.io.getStdIn().writer());
}

fn addOne(x: u32) u32 {
    return x + 1;
}

fn log(x: u32) void {
    std.debug.print("x: {x}", .{x});
}

fn noop(_: u32) void {}

var global_signal: *zignals.Signal(u32) = undefined;

fn deepGraph(_: std.mem.Allocator) void {
    global_signal.set(global_signal.get() + 1);
}

test deepGraph {
    @setEvalBranchQuota(20000000);

    var system = zignals.System{};
    global_signal = system.signalT(u32, 1);

    var derived = system.derived(addOne, .{global_signal});
    inline for (2..1000) |_| {
        derived = system.derived(addOne, .{derived});
    }

    _ = system.effect(noop, .{derived});

    try benchmark("deep graph", deepGraph);
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
    *zignals.Signal(u32),
    *zignals.Signal(u32),
    *zignals.Signal(u32),
    *zignals.Signal(u32),
    *zignals.Signal(u32),
    *zignals.Signal(u32),
    *zignals.Signal(u32),
    *zignals.Signal(u32),
    *zignals.Signal(u32),
    *zignals.Signal(u32),
    *zignals.Signal(u32),
    *zignals.Signal(u32),
    *zignals.Signal(u32),
    *zignals.Signal(u32),
    *zignals.Signal(u32),
    *zignals.Signal(u32),
};

var global_derived: *zignals.Derived(wide) = undefined;
var global_deps: Deps = undefined;

fn wideGraph(_: std.mem.Allocator) void {
    inline for (global_deps) |dep| {
        dep.set(dep.get() + 1);
    }
    _ = global_derived.get();
}

test wideGraph {
    var system = zignals.System{};

    var deps: Deps = undefined;
    inline for (deps, 0..) |_, i| {
        deps[i] = system.signalT(u32, 0);
    }

    global_deps = deps;
    global_derived = system.derived(wide, global_deps);

    try benchmark("wide graph", wideGraph);
}
