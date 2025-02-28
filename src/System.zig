//! System tracks the current update batch and provides functions for creating signals, derivations, and effects.

const std = @import("std");
const Signal = @import("signal.zig").Signal;
const Derived = @import("derived.zig").Derived;
const Effect = @import("effect.zig").Effect;
const Node = @import("Node.zig");

current_update: u64 = 0,

/// Creates a signal from the provided value.
/// This is a convenience wrapper around `signalT` that automatically determines the type.
///
/// ### Example
///
/// ```
/// const boolean: *Signal(bool) = system.signal(true);
/// const number: *Signal(comptime_int) = system.signal(0);
/// ```
///
/// ### Function Signature
pub inline fn signal(self: *@This(), value: anytype) *Signal(@TypeOf(value)) {
    return self.signalT(@TypeOf(value), value);
}

/// Creates a signal from the provided type and value.
///
/// ### Example
///
/// ```
/// const name = system.signalT([]const u8, "Bob");
/// try std.testing.expectEqual("Bob", name.get());
///
/// name.set("Alice");
/// try std.testing.expectEqual("Alice", name.get());
/// ```
///
/// ### Function Signature
pub inline fn signalT(
    self: *@This(),
    comptime T: type,
    value: T,
) *Signal(T) {
    var sig = Signal(T).init(value, undefined, self);
    var node = Node.init(&sig);
    sig.node = &node;

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
/// const counter = system.signalT(u32, 1);
/// const doubled = system.derived(double, .{counter});
///
/// try std.testing.expectEqual(2, doubled.get());
/// ```
///
/// ### Function Signature
pub inline fn derived(
    self: *@This(),
    comptime fun: anytype,
    deps: anytype,
) *Derived(fun) {
    validateTypes(@TypeOf(fun), @TypeOf(deps));

    var der = Derived(fun).init(.init(undefined, undefined, self));
    var node = Node.init(&der);
    der.signal.node = &node;

    inline for (deps) |dep| {
        const dep_node: *Node = dep.getNode();
        node.addDep(dep_node);
        dep_node.addSub(&node);
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
/// const counter = system.signalT(u32, 0);
/// const printer = system.effect(print, .{counter});
/// defer printer.deinit();
/// ```
///
/// ### Function Signature
pub inline fn effect(
    self: *@This(),
    comptime fun: anytype,
    deps: anytype,
) *Effect(fun) {
    validateTypes(@TypeOf(fun), @TypeOf(deps));

    var eff = Effect(fun).init(undefined, self);
    var node = Node.init(&eff);
    eff.node = &node;

    inline for (deps) |dep| {
        const dep_node: *Node = dep.getNode();
        node.addDep(dep_node);
        dep_node.addSub(&node);
    }

    eff.get();

    return &eff;
}

fn validateTypes(comptime Fn: type, comptime Deps: type) void {
    const info = @typeInfo(Fn);
    switch (info) {
        .@"fn" => {},
        else => @compileError("'fun' must be a function"),
    }
    if (info.@"fn".return_type == null) {
        @compileError("Zig does not provide reflection on generic return types");
    }

    const FnArgs: type = std.meta.ArgsTuple(Fn);
    const args_info = @typeInfo(FnArgs);
    const fields = args_info.@"struct".fields;
    if (fields.len == 0) {
        @compileError("'fun' must have at least one argument");
    }

    const deps_info = @typeInfo(Deps);
    switch (deps_info) {
        .@"struct" => {},
        else => @compileError("'deps' must be a struct"),
    }
    const @"struct" = deps_info.@"struct";
    const deps_len = @"struct".fields.len;

    if (deps_len != fields.len) {
        @compileError("'deps' must have the same number of fields as 'fun' arguments");
    }

    if (deps_len == 0) {
        @compileError("'deps' must have at least one field");
    }
}
