# zignals
zignals is a signals library for Zig, with signals, derivations, and effects.

> [!WARNING]  
> This is a toy project and is not meant for production use.

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
    var system = zignals.System{};

    const counter = system.signalT(u32, 0);
    const increment = system.derived(addOne, .{counter});
    _ = system.effect(log, .{increment});

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
var system = zignals.System{};
```

Next, define a signal with an initial value. Signals are reactive state containers that notify dependents when their values change.

```zig
const counter = system.signalT(u32, 0);
```

> [!TIP]
>To create a signal without specifying its type, you can create signals with automatic type inference using the `signal` function.
>```zig
>const Foo = struct {
>   bar: []const u8,
>};
>
>const foo = Foo{};
>
>const signal = system.signal(foo); // inferred as Signal(Foo)
> ```

With the signal created, you can create a derived value. Derivations are lazily computed and only update when you read them.

```zig
const increment = system.derived(addOne, .{counter});
```

This creates an effect that runs when dependencies change. Effects run immediately on creation and again whenever their dependencies update.

```zig
_ = system.effect(log, .{increment});
```
> [!TIP]
>In this example, we discard the effect's return value. If you need to properly clean up an effect, you should capture the value and call `deinit()` like this.
>```zig
>const effect = system.effect(log, .{increment});
>defer effect.deinit();
>```

The effect has already run once during initialization.

```zig
try expectEqual(1, count);
try expectEqual(1, increment.get());
```

When a signal updates, all derived values are marked dirty and effects that depend on the signal automatically updated.

```zig
counter.set(1);

try expectEqual(2, count);
try expectEqual(2, increment.get());
```

## Configuration

To avoid heap allocation, zignals uses fixed size arrays to store dependencies and subscribers. To modify the maximum amounts add, a `max_dependencies` or `max_subscribers` field to the `zignals` dependency in your `build.zig`
```zig
b.dependency("zignals", .{
    .target = target,
    .optimize = optimize,
    .max_dependencies = 4, // defaults to 16
    .max_subscribers = 32, // defaults to 16
})
```

## Thanks To

- [alien-signals-go](https://github.com/delaneyj/alien-signals-go) for the topology and effect tests.

## License

zignals uses the [Apache-2.0](http://www.apache.org/licenses/LICENSE-2.0) license.