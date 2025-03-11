pub const Signal = @import("signal.zig").Signal;
pub const Derived = @import("derived.zig").Derived;
pub const Effect = @import("effect.zig").Effect;
pub const Dependency = @import("Dependency.zig");
pub const Subscriber = @import("Subscriber.zig");

const std = @import("std");
const Allocator = std.mem.Allocator;

/// Creates a signal from the provided value.
/// This is a convenience wrapper around `signalT` that automatically determines the type.
///
/// ### Example
///
/// ```
/// const boolean: *Signal(bool) = zignals.signal(true);
/// const number: *Signal(comptime_int) = zignals.signal(0);
/// ```
///
/// ### Function Signature
pub inline fn signal(value: anytype) *Signal(@TypeOf(value)) {
    return signalT(@TypeOf(value), value);
}

/// Creates a signal from the provided type and value.
///
/// ### Example
///
/// ```
/// const name = zignals.signalT([]const u8, "Bob");
/// try std.testing.expectEqual("Bob", name.get());
///
/// name.set("Alice");
/// try std.testing.expectEqual("Alice", name.get());
/// ```
///
/// ### Function Signature
pub inline fn signalT(
    comptime T: type,
    value: T,
) *Signal(T) {
    var sig = Signal(T).init(value);
    return &sig;
}

/// Creates a derivation from the provided function and dependencies.
/// Derived values are computed lazily and only update when accessed.
///
/// ### Example
///
/// ```
/// fn double(x: u32) u32 {
///     return x * 2;
/// }
///
/// const counter = zignals.signalT(u32, 1);
/// defer counter.deinit(gpa);
/// const doubled = try zignals.derived(gpa, double, .{counter});
/// defer doubled.deinit(gpa);
///
/// try std.testing.expectEqual(2, doubled.get());
/// ```
///
/// ### Function Signature
pub inline fn derived(
    gpa: Allocator,
    comptime fun: anytype,
    deps: anytype,
) !*Derived(fun, @typeInfo(@TypeOf(deps)).@"struct".fields.len) {
    validateTypes(@TypeOf(fun), @TypeOf(deps));
    const n = @typeInfo(@TypeOf(deps)).@"struct".fields.len;
    var dependencies: [n]Dependency = undefined;
    inline for (deps, 0..) |dep, i| {
        dependencies[i] = dep.dependency();
    }
    var der = Derived(fun, n).init(dependencies);
    errdefer der.deinit(gpa);

    const sub = der.subscriber();

    for (&dependencies) |*dep| {
        try dep.addSub(gpa, sub);
    }

    return &der;
}

/// Creates an effect from the provided function and dependencies.
/// Effects run immediately when created and again whenever any dependency updates.
///
/// ### Example
///
/// ```
/// fn print(x: u32) void {
///    std.debug.print("Value: {}\n", .{x});
/// }
///
/// const counter = zignals.signalT(u32, 0);
/// defer counter.deinit(gpa);
/// const printer = try zignals.effect(gpa, print, .{counter});
/// defer printer.deinit(gpa);
/// ```
///
/// ### Function Signature
pub inline fn effect(
    gpa: Allocator,
    comptime fun: anytype,
    deps: anytype,
) !*Effect(fun, @typeInfo(@TypeOf(deps)).@"struct".fields.len) {
    validateTypes(@TypeOf(fun), @TypeOf(deps));
    const n = @typeInfo(@TypeOf(deps)).@"struct".fields.len;
    var dependencies: [n]Dependency = undefined;
    inline for (deps, 0..) |dep, i| {
        dependencies[i] = dep.dependency();
    }
    var eff = Effect(fun, n).init(dependencies);
    errdefer eff.deinit();

    const sub = eff.subscriber();

    for (&dependencies) |*dep| {
        try dep.addSub(gpa, sub);
    }

    eff.markDirty();

    return &eff;
}

fn validateTypes(comptime Fn: type, comptime Deps: type) void {
    const info = @typeInfo(Fn);
    if (info != .@"fn") @compileError("'fun' must be a function");

    if (info.@"fn".return_type == null)
        @compileError("Zig does not provide reflection on @TypeOf return types");

    const FnArgs: type = std.meta.ArgsTuple(Fn);
    const args_info = @typeInfo(FnArgs);
    const fields = args_info.@"struct".fields;
    if (fields.len == 0) @compileError("'fun' must have at least one argument");

    const deps_info = @typeInfo(Deps);
    if (deps_info != .@"struct") @compileError("'deps' must be a struct");

    const @"struct" = deps_info.@"struct";
    const deps_len = @"struct".fields.len;

    if (deps_len != fields.len)
        @compileError("'deps' must have the same number of fields as 'fun' arguments");

    if (deps_len == 0) @compileError("'deps' must have at least one field");
}
