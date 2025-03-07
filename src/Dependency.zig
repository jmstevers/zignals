const std = @import("std");
const Subscriber = @import("Subscriber.zig");
const Allocator = std.mem.Allocator;

const VTable = struct {
    version: *const fn (ptr: *anyopaque) u32,
    get: *const fn (ptr: *anyopaque, result: *anyopaque) void,
    addSub: *const fn (ptr: *anyopaque, allocator: Allocator, sub: Subscriber) anyerror!void,
    removeSub: *const fn (ptr: *anyopaque, sub: Subscriber) void,
};

ptr: *anyopaque,
vtable: VTable,

pub fn init(
    comptime T: type,
    pointer: anytype,
    comptime versionFn: fn (ptr: @TypeOf(pointer)) u32,
    comptime addSubFn: fn (ptr: @TypeOf(pointer), allocator: Allocator, sub: Subscriber) anyerror!void,
    comptime removeSubFn: fn (ptr: @TypeOf(pointer), sub: Subscriber) void,
) @This() {
    const Ptr = @TypeOf(pointer);
    const vtable = struct {
        fn version(ptr: *anyopaque) u32 {
            const self: Ptr = @ptrCast(@alignCast(ptr));
            return versionFn(self);
        }

        fn get(ptr: *anyopaque, result: *anyopaque) void {
            const self: Ptr = @ptrCast(@alignCast(ptr));
            const typed_result: *T = @ptrCast(@alignCast(result));
            typed_result.* = self.get();
        }

        fn addSub(ptr: *anyopaque, allocator: Allocator, sub: Subscriber) !void {
            const self: Ptr = @ptrCast(@alignCast(ptr));
            try addSubFn(self, allocator, sub);
        }

        fn removeSub(ptr: *anyopaque, sub: Subscriber) void {
            const self: Ptr = @ptrCast(@alignCast(ptr));
            removeSubFn(self, sub);
        }
    };

    return .{
        .ptr = pointer,
        .vtable = .{
            .version = vtable.version,
            .get = vtable.get,
            .addSub = vtable.addSub,
            .removeSub = vtable.removeSub,
        },
    };
}

pub fn version(self: *@This()) u32 {
    return self.vtable.version(self.ptr);
}

pub fn get(self: *@This(), comptime T: type) T {
    var result: T = undefined;
    self.vtable.get(self.ptr, @ptrCast(@alignCast(&result)));
    return result;
}

pub fn addSub(self: *@This(), allocator: Allocator, sub: Subscriber) !void {
    try self.vtable.addSub(self.ptr, allocator, sub);
}

pub fn removeSub(self: *@This(), sub: Subscriber) void {
    self.vtable.removeSub(self.ptr, sub);
}
