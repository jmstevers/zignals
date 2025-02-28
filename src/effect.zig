const std = @import("std");
const Signal = @import("signal.zig").Signal;
const Node = @import("Node.zig");
const System = @import("System.zig");

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
pub fn Effect(comptime fun: anytype) type {
    const Fn: type = @TypeOf(fun);
    const FnArgs: type = std.meta.ArgsTuple(Fn);
    const fields = @typeInfo(FnArgs).@"struct".fields;
    const fallible = switch (@typeInfo(@typeInfo(Fn).@"fn".return_type.?)) {
        .error_set => true,
        else => false,
    };

    return struct {
        node: *Node,
        system: *System,
        last_update: u64 = 0,
        fn_args: ?FnArgs = null,

        pub fn init(node: *Node, system: *System) @This() {
            return .{
                .node = node,
                .system = system,
            };
        }
        pub fn deinit(self: *@This()) void {
            self.node.deinit();
        }

        pub fn get(self: *@This()) void {
            var fn_args: FnArgs = undefined;
            inline for (0..fields.len) |i| {
                fn_args[i] = self.node.deps[i].get(fields[i].type);
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

        pub fn getNode(self: @This()) *Node {
            return self.node;
        }

        pub fn markDirty(self: *@This()) void {
            if (self.last_update == self.system.current_update) return;
            self.last_update = self.system.current_update;

            self.get();
        }
    };
}
