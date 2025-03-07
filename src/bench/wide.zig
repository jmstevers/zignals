const std = @import("std");
const z = @import("../root.zig");
const bench = @import("../bench.zig");
const benchmark = bench.benchmark;

const dep_count = 100;

var wide_signals: [dep_count]*z.Signal(u32) = undefined;
var wide_derived: *z.Derived(sum, dep_count) = undefined;

const WideDeps: type = blk: {
    var types: [dep_count]type = undefined;
    for (0..dep_count) |i| {
        types[i] = *z.Signal(u32);
    }
    break :blk std.meta.Tuple(&types);
};

fn wide(_: std.mem.Allocator) void {
    for (wide_signals) |signal| {
        signal.set(signal.get() + 1);
    }

    _ = wide_derived.get();
}

test wide {
    var arena = std.heap.ArenaAllocator.init(std.heap.smp_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var deps: WideDeps = undefined;
    inline for (0..dep_count) |i| {
        const signal = z.signalT(u32, 0);
        wide_signals[i] = signal;
        deps[i] = signal;
    }

    wide_derived = try z.derived(allocator, sum, deps);

    try benchmark(allocator, "wide dependencies", wide);
}

fn sum(
    a0: u32,
    a1: u32,
    a2: u32,
    a3: u32,
    a4: u32,
    a5: u32,
    a6: u32,
    a7: u32,
    a8: u32,
    a9: u32,
    a10: u32,
    a11: u32,
    a12: u32,
    a13: u32,
    a14: u32,
    a15: u32,
    a16: u32,
    a17: u32,
    a18: u32,
    a19: u32,
    a20: u32,
    a21: u32,
    a22: u32,
    a23: u32,
    a24: u32,
    a25: u32,
    a26: u32,
    a27: u32,
    a28: u32,
    a29: u32,
    a30: u32,
    a31: u32,
    a32: u32,
    a33: u32,
    a34: u32,
    a35: u32,
    a36: u32,
    a37: u32,
    a38: u32,
    a39: u32,
    a40: u32,
    a41: u32,
    a42: u32,
    a43: u32,
    a44: u32,
    a45: u32,
    a46: u32,
    a47: u32,
    a48: u32,
    a49: u32,
    a50: u32,
    a51: u32,
    a52: u32,
    a53: u32,
    a54: u32,
    a55: u32,
    a56: u32,
    a57: u32,
    a58: u32,
    a59: u32,
    a60: u32,
    a61: u32,
    a62: u32,
    a63: u32,
    a64: u32,
    a65: u32,
    a66: u32,
    a67: u32,
    a68: u32,
    a69: u32,
    a70: u32,
    a71: u32,
    a72: u32,
    a73: u32,
    a74: u32,
    a75: u32,
    a76: u32,
    a77: u32,
    a78: u32,
    a79: u32,
    a80: u32,
    a81: u32,
    a82: u32,
    a83: u32,
    a84: u32,
    a85: u32,
    a86: u32,
    a87: u32,
    a88: u32,
    a89: u32,
    a90: u32,
    a91: u32,
    a92: u32,
    a93: u32,
    a94: u32,
    a95: u32,
    a96: u32,
    a97: u32,
    a98: u32,
    a99: u32,
) u32 {
    return a0 + a1 + a2 + a3 + a4 + a5 + a6 + a7 + a8 + a9 + a10 +
        a11 + a12 + a13 + a14 + a15 + a16 + a17 + a18 + a19 + a20 +
        a21 + a22 + a23 + a24 + a25 + a26 + a27 + a28 + a29 + a30 +
        a31 + a32 + a33 + a34 + a35 + a36 + a37 + a38 + a39 + a40 +
        a41 + a42 + a43 + a44 + a45 + a46 + a47 + a48 + a49 + a50 +
        a51 + a52 + a53 + a54 + a55 + a56 + a57 + a58 + a59 + a60 +
        a61 + a62 + a63 + a64 + a65 + a66 + a67 + a68 + a69 + a70 +
        a71 + a72 + a73 + a74 + a75 + a76 + a77 + a78 + a79 + a80 +
        a81 + a82 + a83 + a84 + a85 + a86 + a87 + a88 + a89 + a90 +
        a91 + a92 + a93 + a94 + a95 + a96 + a97 + a98 + a99;
}
