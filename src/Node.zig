//! Interface for a node in the dependency graph.

const std = @import("std");
const config = @import("config");

const VTable = struct {
    get: *const fn (ptr: *anyopaque, dest: *anyopaque) void,
    markDirty: *const fn (ptr: *anyopaque) void,
};

deps: [config.max_dependencies]*@This() = undefined,
subs: [config.max_subscribers]*@This() = undefined,
deps_len: u8 = 0,
subs_len: u8 = 0,
ptr: *anyopaque,
vtable: *const VTable,

pub fn init(data: anytype) @This() {
    const DataPtr: type = @TypeOf(data);

    const vtable = struct {
        fn get(ptr: *anyopaque, dest: *anyopaque) void {
            const data_ptr: DataPtr = @ptrCast(@alignCast(ptr));
            const result = data_ptr.get();
            const typed_dest: *@TypeOf(result) = @ptrCast(@alignCast(dest));
            typed_dest.* = result;
        }

        fn markDirty(ptr: *anyopaque) void {
            const data_ptr: DataPtr = @ptrCast(@alignCast(ptr));
            data_ptr.markDirty();
        }
    };

    return .{
        .ptr = @ptrCast(@alignCast(data)),
        .vtable = &.{
            .get = vtable.get,
            .markDirty = vtable.markDirty,
        },
    };
}

pub fn deinit(self: *@This()) void {
    for (self.getDeps()) |dep| {
        for (dep.getSubs(), 0..) |sub, i| {
            if (sub.ptr == self.ptr) {
                dep.subs[i] = dep.subs[dep.subs_len - 1];
                dep.subs[dep.subs_len - 1] = undefined;
                dep.subs_len -= 1;
            }
        }
    }

    for (self.getSubs()) |sub| {
        for (sub.getDeps(), 0..) |dep, i| {
            if (dep.ptr == self.ptr) {
                sub.deps[i] = sub.deps[sub.deps_len - 1];
                sub.deps[sub.deps_len - 1] = undefined;
                sub.deps_len -= 1;
            }
        }
    }
}

pub fn get(self: @This(), comptime T: type) T {
    var result: T = undefined;
    self.vtable.get(self.ptr, @ptrCast(@alignCast(&result)));
    return result;
}

pub fn markDirty(self: @This()) void {
    self.vtable.markDirty(self.ptr);
}

pub fn addSub(self: *@This(), sub: *@This()) void {
    self.subs[self.subs_len] = sub;
    self.subs_len += 1;
}

pub fn getSubs(self: *@This()) []*@This() {
    return self.subs[0..self.subs_len];
}

pub fn addDep(self: *@This(), dep: *@This()) void {
    self.deps[self.deps_len] = dep;
    self.deps_len += 1;
}

pub fn getDeps(self: *@This()) []*@This() {
    return self.deps[0..self.deps_len];
}
