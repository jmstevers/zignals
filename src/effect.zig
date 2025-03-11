const std = @import("std");
const Subscriber = @import("Subscriber.zig");
const Dependency = @import("Dependency.zig");

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
pub fn Effect(comptime fun: anytype, comptime n: u32) type {
    const Fn: type = @TypeOf(fun);
    const FnArgs: type = std.meta.ArgsTuple(Fn);
    const fallible = switch (@typeInfo(@typeInfo(Fn).@"fn".return_type.?)) {
        .error_set => true,
        else => false,
    };

    return struct {
        fn_args: ?FnArgs = null,
        deps: [n]Dependency,

        pub fn init(deps: [n]Dependency) @This() {
            return .{
                .deps = deps,
            };
        }

        pub fn deinit(self: *@This()) void {
            const sub = self.subscriber();
            for (&self.deps) |*dep| {
                dep.removeSub(sub);
            }
        }

        pub fn markDirty(self: *@This()) void {
            var fn_args: FnArgs = undefined;
            inline for (0..n) |i| {
                fn_args[i] = self.deps[i].get(@TypeOf(fn_args[i]));
            }

            if (self.fn_args != null and std.meta.eql(self.fn_args, fn_args)) return;
            self.fn_args = fn_args;

            if (fallible) {
                // TODO: better error handling
                // maybe an options struct with optional onError callback?
                @call(.auto, fun, fn_args) catch {};
            } else {
                @call(.auto, fun, fn_args);
            }
        }

        pub fn subscriber(self: *@This()) Subscriber {
            return .init(self, markDirty);
        }
    };
}
