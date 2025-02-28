const std = @import("std");
const Signal = @import("signal.zig").Signal;
const Node = @import("Node.zig");
const root = @import("root.zig");

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
pub fn Derived(comptime fun: anytype) type {
    const Fn: type = @TypeOf(fun);
    const T: type = @typeInfo(Fn).@"fn".return_type.?;
    const FnArgs: type = std.meta.ArgsTuple(Fn);
    const fields = @typeInfo(FnArgs).@"struct".fields;

    return struct {
        signal: Signal(T),
        dirty: bool = true,
        last_update: u64 = 0,
        fn_args: ?FnArgs = null,

        pub fn init(signal: Signal(T)) @This() {
            return .{
                .signal = signal,
            };
        }

        pub fn deinit(self: *@This()) void {
            self.signal.node.deinit();
        }

        pub fn get(self: *@This()) T {
            self.compute();
            return self.signal.value;
        }

        pub fn compute(self: *@This()) void {
            if (!self.dirty) return;
            self.dirty = false;

            var fn_args: FnArgs = undefined;
            inline for (0..fields.len) |i| {
                fn_args[i] = self.signal.node.deps[i].get(fields[i].type);
            }

            if (self.fn_args != null and std.meta.eql(self.fn_args, fn_args)) return;
            self.fn_args = fn_args;

            const value = @call(.auto, fun, fn_args);
            if (std.meta.eql(self.signal.value, value)) return;

            self.signal.value = value;
            self.signal.markDirty();
        }

        pub fn getNode(self: @This()) *Node {
            return self.signal.node;
        }

        pub fn markDirty(self: *@This()) void {
            if (self.last_update == self.signal.system.current_update or self.dirty) return;
            self.last_update = self.signal.system.current_update;
            self.dirty = true;

            self.signal.markDirty();
        }
    };
}
