const std = @import("std");
const Subscriber = @import("Subscriber.zig");
const Dependency = @import("Dependency.zig");
const Allocator = std.mem.Allocator;

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
/// defer counter.deinit(allocator);
/// const doubled = try zignals.derived(allocator, double, .{counter});
/// defer doubled.deinit(allocator);
///
/// try std.testing.expectEqual(2, doubled.get());
/// ```
///
/// ### Function Signature
pub fn Derived(comptime fun: anytype, comptime n: u32) type {
    const Fn: type = @TypeOf(fun);
    const T: type = @typeInfo(Fn).@"fn".return_type.?;
    const FnArgs: type = std.meta.ArgsTuple(Fn);

    return struct {
        value: T = undefined,
        dirty: bool = true,
        fn_args: ?FnArgs = null,
        deps: [n]Dependency,
        subs: std.ArrayListUnmanaged(Subscriber) = .empty,

        pub fn init(deps: [n]Dependency) @This() {
            return .{
                .deps = deps,
            };
        }

        pub fn deinit(self: *@This(), allocator: Allocator) void {
            const sub = self.subscriber();
            for (&self.deps) |*dep| {
                dep.removeSub(sub);
            }
            self.subs.deinit(allocator);
        }

        pub fn get(self: *@This()) T {
            self.compute();
            return self.value;
        }

        pub fn compute(self: *@This()) void {
            if (!self.dirty) return;
            self.dirty = false;

            var fn_args: FnArgs = undefined;
            inline for (0..n) |i| {
                fn_args[i] = self.deps[i].get(@TypeOf(fn_args[i]));
            }

            if (self.fn_args != null and std.meta.eql(self.fn_args, fn_args)) return;
            self.fn_args = fn_args;

            const value = @call(.auto, fun, fn_args);
            if (std.meta.eql(self.value, value)) return;

            self.value = value;
        }

        pub fn markDirty(self: *@This()) void {
            self.dirty = true;

            for (self.subs.items) |sub| {
                sub.markDirty();
            }
        }

        pub fn subscriber(self: *@This()) Subscriber {
            return .init(self, markDirty);
        }

        pub fn addSub(self: *@This(), allocator: Allocator, sub: Subscriber) !void {
            try self.subs.append(allocator, sub);
        }

        pub fn removeSub(self: *@This(), sub: Subscriber) void {
            for (self.subs.items, 0..) |item, i| {
                if (item.ptr != sub.ptr) continue;
                _ = self.subs.swapRemove(i);
                return;
            }
        }

        pub fn dependency(self: *@This()) Dependency {
            return .init(T, self, addSub, removeSub);
        }
    };
}
