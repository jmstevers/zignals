const std = @import("std");
const Node = @import("Node.zig");
const System = @import("System.zig");

/// Signals are values that can be observed and updated.
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
pub fn Signal(comptime T: type) type {
    return struct {
        value: T,
        node: *Node,
        system: *System,

        pub fn init(value: T, node: *Node, system: *System) @This() {
            return .{
                .value = value,
                .node = node,
                .system = system,
            };
        }

        pub fn deinit(self: *@This()) void {
            self.node.deinit();
        }

        pub fn get(self: @This()) T {
            return self.value;
        }

        pub fn set(self: *@This(), value: T) void {
            if (std.meta.eql(self.value, value)) return;
            self.value = value;

            self.emit();
        }

        pub fn getNode(self: @This()) *Node {
            return self.node;
        }

        pub fn markDirty(self: *@This()) void {
            for (self.node.getSubs()) |node| {
                node.markDirty();
            }
        }

        pub fn emit(self: *@This()) void {
            if (self.node.subs_len == 0) return;
            self.system.current_update += 1;
            self.markDirty();
        }
    };
}
