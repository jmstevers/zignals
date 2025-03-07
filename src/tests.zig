const std = @import("std");
const zignals = @import("root.zig");
const expectEqual = std.testing.expectEqual;

fn identity(x: u32) u32 {
    return x;
}

fn addOne(x: u32) u32 {
    return x + 1;
}

fn add(x: u32, y: u32) u32 {
    return x + y;
}

fn one(_: u32) u32 {
    return 1;
}

fn noop(_: u32) void {}

fn log(x: u32) void {
    std.debug.print("x: {x}\n", .{x});
}

fn setResult(result: *u32, x: u32) void {
    result.* = x;
}

fn countCallsEffect(_: u32) void {
    count += 1;
}

fn countCalls(x: u32) u32 {
    count += 1;
    return x;
}

fn countCalls2(x: u32, y: u32) u32 {
    count += 1;
    return x + y;
}

fn countCalls3(x: u32, y: u32, z: u32) u32 {
    count += 1;
    return x + y + z;
}

var count: u32 = 0;

test "drop aba updates" {
    count = 0;

    var arena = std.heap.ArenaAllocator.init(std.heap.smp_allocator);
    defer arena.deinit();
    const gpa = arena.allocator();

    const a = zignals.signalT(u32, 1);
    const b = try zignals.derived(gpa, addOne, .{a});
    const c = try zignals.derived(gpa, add, .{ a, b });
    const d = try zignals.derived(gpa, countCalls, .{c});

    try expectEqual(3, d.get());
    try expectEqual(1, count);

    a.set(2);

    try expectEqual(5, d.get());
    try expectEqual(2, count);
}

test "diamond" {
    count = 0;

    var arena = std.heap.ArenaAllocator.init(std.heap.smp_allocator);
    defer arena.deinit();
    const gpa = arena.allocator();

    const a = zignals.signalT(u32, 0);
    const b = try zignals.derived(gpa, addOne, .{a});
    const c = try zignals.derived(gpa, addOne, .{a});
    const d = try zignals.derived(gpa, countCalls2, .{ b, c });

    try expectEqual(2, d.get());
    try expectEqual(1, count);

    a.set(1);

    try expectEqual(4, d.get());
    try expectEqual(2, count);
}

test "diamond tail" {
    count = 0;

    var arena = std.heap.ArenaAllocator.init(std.heap.smp_allocator);
    defer arena.deinit();
    const gpa = arena.allocator();

    const a = zignals.signalT(u32, 1);
    const b = try zignals.derived(gpa, addOne, .{a});
    const c = try zignals.derived(gpa, addOne, .{a});
    const d = try zignals.derived(gpa, add, .{ b, c });
    const e = try zignals.derived(gpa, countCalls, .{d});

    try expectEqual(4, e.get());
    try expectEqual(1, count);

    a.set(2);

    try expectEqual(6, e.get());
    try expectEqual(2, count);
}

test "jagged diamond tails" {
    count = 0;

    var arena = std.heap.ArenaAllocator.init(std.heap.smp_allocator);
    defer arena.deinit();
    const gpa = arena.allocator();

    const a = zignals.signalT(u32, 1);
    const b = try zignals.derived(gpa, addOne, .{a});
    const c = try zignals.derived(gpa, addOne, .{a});
    const d = try zignals.derived(gpa, addOne, .{c});
    const e = try zignals.derived(gpa, countCalls2, .{ b, d });
    const f = try zignals.derived(gpa, countCalls, .{e});

    try expectEqual(5, f.get());
    try expectEqual(5, e.get());
    try expectEqual(2, count);

    a.set(2);

    try expectEqual(7, f.get());
    try expectEqual(7, e.get());
    try expectEqual(4, count);

    a.set(3);

    try expectEqual(9, f.get());
    try expectEqual(9, e.get());
    try expectEqual(6, count);
}

test "bail if result is the same" {
    count = 0;

    var arena = std.heap.ArenaAllocator.init(std.heap.smp_allocator);
    defer arena.deinit();
    const gpa = arena.allocator();

    const a = zignals.signalT(u32, 1);
    const b = try zignals.derived(gpa, one, .{a});
    const c = try zignals.derived(gpa, countCalls, .{b});

    try expectEqual(1, c.get());
    try expectEqual(1, count);

    a.set(2);

    try expectEqual(1, c.get());
    try expectEqual(1, count);
}

test "diamond with static middle" {
    count = 0;

    var arena = std.heap.ArenaAllocator.init(std.heap.smp_allocator);
    defer arena.deinit();
    const gpa = arena.allocator();

    const a = zignals.signalT(u32, 1);
    const b = try zignals.derived(gpa, one, .{a});
    const c = try zignals.derived(gpa, one, .{a});
    const d = try zignals.derived(gpa, countCalls2, .{ b, c });

    try expectEqual(2, d.get());
    try expectEqual(1, count);

    a.set(2);

    try expectEqual(2, d.get());
    try expectEqual(1, count);
}

test "only sub to signals listened to" {
    count = 0;

    var arena = std.heap.ArenaAllocator.init(std.heap.smp_allocator);
    defer arena.deinit();
    const gpa = arena.allocator();

    const a = zignals.signalT(u32, 1);
    const b = try zignals.derived(gpa, addOne, .{a});
    _ = try zignals.derived(gpa, countCalls, .{a});

    try expectEqual(2, b.get());
    try expectEqual(0, count);

    a.set(2);

    try expectEqual(3, b.get());
    try expectEqual(0, count);
}

test "only sub to signals listened to 2" {
    count = 0;

    var arena = std.heap.ArenaAllocator.init(std.heap.smp_allocator);
    defer arena.deinit();
    const gpa = arena.allocator();

    const a = zignals.signalT(u32, 1);
    const b = try zignals.derived(gpa, countCalls, .{a});
    const c = try zignals.derived(gpa, countCalls, .{b});
    const d = try zignals.derived(gpa, identity, .{a});

    var result_num: u32 = 0;
    const result = zignals.signalT(*u32, &result_num);
    const effect = try zignals.effect(gpa, setResult, .{ result, c });

    try expectEqual(1, result_num);
    try expectEqual(1, d.get());
    try expectEqual(2, count);

    effect.deinit();

    a.set(2);

    try expectEqual(2, d.get());
    try expectEqual(2, count);
    try expectEqual(1, result_num);
}

test "ensure subs update" {
    count = 0;

    var arena = std.heap.ArenaAllocator.init(std.heap.smp_allocator);
    defer arena.deinit();
    const gpa = arena.allocator();

    const a = zignals.signalT(u32, 1);
    const b = try zignals.derived(gpa, identity, .{a});
    const c = try zignals.derived(gpa, one, .{a});
    const d = try zignals.derived(gpa, countCalls2, .{ b, c });

    try expectEqual(2, d.get());
    try expectEqual(1, count);

    a.set(2);

    try expectEqual(3, d.get());
    try expectEqual(2, count);
}

test "ensure subs update despite two deps being unmarked" {
    count = 0;

    var arena = std.heap.ArenaAllocator.init(std.heap.smp_allocator);
    defer arena.deinit();
    const gpa = arena.allocator();

    const a = zignals.signalT(u32, 1);
    const b = try zignals.derived(gpa, identity, .{a});
    const c = try zignals.derived(gpa, one, .{a});
    const d = try zignals.derived(gpa, one, .{a});
    const e = try zignals.derived(gpa, countCalls3, .{ b, c, d });

    try expectEqual(3, e.get());
    try expectEqual(1, count);

    a.set(2);

    try expectEqual(4, e.get());
    try expectEqual(2, count);
}

test "effect clears subs when untracked" {
    count = 0;

    var arena = std.heap.ArenaAllocator.init(std.heap.smp_allocator);
    defer arena.deinit();
    const gpa = arena.allocator();

    const a = zignals.signalT(u32, 1);
    const b = try zignals.derived(gpa, countCalls, .{a});
    const effect = try zignals.effect(gpa, noop, .{b});

    try expectEqual(1, count);
    try expectEqual(1, b.get());

    a.set(2);

    try expectEqual(2, count);
    try expectEqual(2, b.get());
    try expectEqual(2, count);

    effect.deinit();

    a.set(3);

    try expectEqual(2, count);
}
