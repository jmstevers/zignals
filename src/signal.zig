const std = @import("std");
const Subscriber = @import("Subscriber.zig");
const Dependency = @import("Dependency.zig");
const Allocator = std.mem.Allocator;

/// Signals are values that can be observed and updated.
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
pub fn Signal(comptime T: type) type {
    return struct {
        value: T,
        subs: std.ArrayListUnmanaged(Subscriber) = .empty,

        pub fn init(value: T) @This() {
            return .{
                .value = value,
            };
        }

        pub fn deinit(self: *@This(), gpa: Allocator) void {
            self.subs.deinit(gpa);
        }

        pub fn get(self: @This()) T {
            return self.value;
        }

        pub fn set(self: *@This(), value: T) void {
            if (std.meta.eql(self.value, value)) return;
            self.value = value;

            for (self.subs.items) |sub| {
                sub.markDirty();
            }
        }

        pub fn addSub(self: *@This(), gpa: Allocator, sub: Subscriber) !void {
            try self.subs.append(gpa, sub);
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
