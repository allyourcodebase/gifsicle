# Gifsicle

This is [gifsicle](https://github.com/kohler/gifsicle) packaged using Zig build system

needs zig version `0.15.1` or higher


## Options

You can set these options when importing as a dependency with `b.dependency("gifsicle", .{ option=value })`
or when building directly with `zig build -Doption=value`

|Option Name|default |description                                   |
|-----------|:------:|----------------------------------------------|
| linkage   | static | Linkage mode too build lib (dynamic library) |
| tools     | true   | Build cli tools (gifsicle, gifview, gifdiff) |
| terminal  | true   | Output gif to terminal                       |

---

Thanks to andrew's fork of [ffmpeg](https://github.com/andrewrk/ffmpeg) for the knowhow
