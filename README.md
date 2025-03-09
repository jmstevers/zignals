# zignals
zignals is a reactive programming library for Zig.

> [!WARNING]  
> This is a toy project and is NOT meant for production use.

## Installation

Add zignals as a dependency

```
zig fetch --save git+https://github.com/jmstevers/zignals
```

Then, add this to your `build.zig`

```zig
const zignals = b.dependency("zignals", .{
    .target = target,
    .optimize = optimize,
}).module("zignals");

exe.root_module.addImport("zignals", zignals);
```


## Usage
```zig
const std = @import("std");
const zignals = @import("zignals");
const expectEqual = std.testing.expectEqual;

var count: u32 = 0;

fn log(x: u32) void {
    count += 1;
    std.debug.print("x: {}\n", .{x});
}

fn addOne(x: u32) u32 {
    return x + 1;
}

pub fn main() !void {
    var gpa: std.heap.DebugAllocator(.{}) = .init;
    defer gpa.deinit(allocator);
    const allocator = gpa.allocator();

    const counter = zignals.signalT(u32, 0);
    defer counter.deinit(allocator);

    const increment = try zignals.derived(allocator, addOne, .{counter});
    defer increment.deinit(allocator);

    const effect = try zignals.effect(allocator, log, .{increment});
    defer effect.deinit(allocator);

    try expectEqual(1, count);
    try expectEqual(1, increment.get());

    counter.set(1);

    try expectEqual(2, count);
    try expectEqual(2, increment.get());
}
```

### Explanation

After [installing](#installation), start by importing the library.

```zig
const zignals = @import("zignals");
```

Define a signal with an initial value. A signal is a reactive state container that notifies its subscribers whenever its value changes.

```zig
const counter = zignals.signalT(u32, 0);
```

> [!TIP]
>To avoid explicitly specifying a type, you can use automatic type inference with the `signal` function.
>```zig
>const Foo = struct {
>   bar: []const u8 = "baz",
>};
>
>const foo: Foo = .{};
>
>const signal = zignals.signal(foo); // inferred as Signal(Foo)
> ```

Once the signal is set up, you can create a derived value that subscribes to it. Derivations are computed lazily, meaning they only update when their value is read. This approach is useful for expensive computations that you want to perform only once per update.

```zig
const increment = try zignals.derived(allocator, addOne, .{counter});
```

Next, create an effect that subscribes to the derived value. Effects execute immediately upon creation and run again whenever any of their dependencies update.

```zig
const effect = try zignals.effect(allocator, log, .{increment});
```

The effect has already ran once during initialization.

```zig
try expectEqual(1, count);
try expectEqual(1, increment.get());
```
When you update the signal, all subscribed derived values are marked as dirty, and the corresponding effects automatically recalculate their values.

```zig
counter.set(1);

try expectEqual(2, count);
try expectEqual(2, increment.get());
```

## Special Thanks

- [signalparty](https://github.com/delaneyj/signalparty) for the optimization of the implementation.
- [alien-signals](https://github.com/stackblitz/alien-signals) for the topology and effect tests.
- [reco](https://github.com/gingerfocus/reco) for the initial inspiration.

## License

zignals uses the [Apache-2.0](http://www.apache.org/licenses/LICENSE-2.0) license.
