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
    defer gpa.deinit();
    const allocator = gpa.allocator();

    var system = zignals.System.init(allocator);

    const counter = system.signalT(u32, 0);
    defer counter.deinit();
    const increment = try system.derived(addOne, .{counter});
    defer increment.deinit();
    const effect = try system.effect(log, .{increment});
    defer effect.deinit();

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

First, initialize a system that will keep track of update batches.

```zig
var system = zignals.System.init(allocator);
```

Next, define a signal with an initial value. Signals are reactive state containers that notify dependents when their values change.

```zig
const counter = system.signalT(u32, 0);
```

> [!TIP]
>To create a signal without specifying its type, you can create signals with automatic type inference using the `signal` function.
>```zig
>const Foo = struct {
>   pub const init = .{}
>   bar: []const u8 = "baz",
>};
>
>const foo: Foo = .init;
>
>const signal = system.signal(foo); // inferred as Signal(Foo)
> ```

With the signal created, you can create a derived value. Derivations are lazily computed and only update when you read them.

```zig
const increment = try system.derived(addOne, .{counter});
```

This creates an effect that runs when dependencies change. Effects run immediately on creation and again whenever their dependencies update.

```zig
const effect = try system.effect(log, .{increment});
```

The effect has already run once during initialization.

```zig
try expectEqual(1, count);
try expectEqual(1, increment.get());
```

When a signal updates, all derived values are marked dirty and effects that depend on the signal are automatically updated.

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