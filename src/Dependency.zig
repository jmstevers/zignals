const std = @import("std");
const Subscriber = @import("Subscriber.zig");
const Allocator = std.mem.Allocator;

const VTable = struct {
    get: *const fn (ptr: *anyopaque, result: *anyopaque) void,
    addSub: *const fn (ptr: *anyopaque, gpa: Allocator, sub: Subscriber) anyerror!void,
    removeSub: *const fn (ptr: *anyopaque, sub: Subscriber) void,
};

ptr: *anyopaque,
vtable: VTable,

pub fn init(
    comptime T: type,
    pointer: anytype,
    comptime addSubFn: fn (ptr: @TypeOf(pointer), gpa: Allocator, sub: Subscriber) anyerror!void,
    comptime removeSubFn: fn (ptr: @TypeOf(pointer), sub: Subscriber) void,
) @This() {
    const Ptr = @TypeOf(pointer);
    const vtable = struct {
        fn get(ptr: *anyopaque, result: *anyopaque) void {
            const self: Ptr = @ptrCast(@alignCast(ptr));
            const typed_result: *T = @ptrCast(@alignCast(result));
            typed_result.* = self.get();
        }

        fn addSub(ptr: *anyopaque, gpa: Allocator, sub: Subscriber) !void {
            const self: Ptr = @ptrCast(@alignCast(ptr));
            try addSubFn(self, gpa, sub);
        }

        fn removeSub(ptr: *anyopaque, sub: Subscriber) void {
            const self: Ptr = @ptrCast(@alignCast(ptr));
            removeSubFn(self, sub);
        }
    };

    return .{
        .ptr = pointer,
        .vtable = .{
            .get = vtable.get,
            .addSub = vtable.addSub,
            .removeSub = vtable.removeSub,
        },
    };
}

pub fn get(self: *@This(), comptime T: type) T {
    var result: T = undefined;
    self.vtable.get(self.ptr, @ptrCast(@alignCast(&result)));
    return result;
}

pub fn addSub(self: *@This(), gpa: Allocator, sub: Subscriber) !void {
    try self.vtable.addSub(self.ptr, gpa, sub);
}

pub fn removeSub(self: *@This(), sub: Subscriber) void {
    self.vtable.removeSub(self.ptr, sub);
}
