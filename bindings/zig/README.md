# No need for Zig bindings

You can link directly `libzenroom.so` in your zig program.

Usually you may want to run a zencode script and save the result in a zig array, the following code does exactly that (we assume there are `zenroom.h` and `libzenroom.so` in the same folder of the zig file):
```zig
const std = @import("std");
const zenroom = @cImport(@cInclude("zenroom.h"));

pub fn main() !void {
    var script: [*c]const u8 = "Given nothing\nWhen done\nThen print the string 'ok'"; 
    var outbuf: [4096:0]u8 = undefined;
    var errbuf: [4096:0]u8 = undefined;
    _ = zenroom.zencode_exec_tobuf(script,"","","", &outbuf, 4096, &errbuf, 4096);
    
    // Deal with null terminated string (print until '\0')
    if (std.mem.indexOf(u8, &outbuf, &[_]u8{0})) |pos| {
        std.log.info("{s}", .{outbuf[0..pos-1]});
    } else {
        std.log.warn("Zenroom returned a not null terminated string... :(", .{});
    }
}
```

Finally, you can compile with the command (build the zig file, linking `libc` and `zenroom` using headers and libraries in the current path)
```
zig build-exe main.zig -lc -lzenroom -isystem . -L.
```

## Use directly stdout for zenroom
You can also show the zencode output directly to stdout (without using a buffer)
```zig
const std = @import("std");
const zenroom = @cImport(@cInclude("zenroom.h"));

pub fn main() !void {
    var script: [*c]const u8 = "Given nothing\nWhen done\nThen print the string 'ok'";
    _ = zenroom.zencode_exec(script,"","","");
}
```
