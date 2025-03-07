const std = @import("std");

ptr: *anyopaque,
markDirtyFn: *const fn (ptr: *anyopaque) void,

pub fn init(pointer: anytype, comptime markDirtyFn: fn (ptr: @TypeOf(pointer)) void) @This() {
    const vtable = struct {
        fn markDirty(ptr: *anyopaque) void {
            const self: @TypeOf(pointer) = @ptrCast(@alignCast(ptr));
            markDirtyFn(self);
        }
    };

    return .{
        .ptr = pointer,
        .markDirtyFn = vtable.markDirty,
    };
}

pub fn markDirty(self: @This()) void {
    self.markDirtyFn(self.ptr);
}
