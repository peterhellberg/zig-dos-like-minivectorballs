# zig-dos-like-minivectorballs :soccer:

Getting the [minivectorballs](https://github.com/mattiasgustavsson/dos-like/blob/bfb1542de009f1b51ef5f6a03eaa9649c3e54400/source/minivectorballs.c)
example from [dos-like](https://github.com/mattiasgustavsson/dos-like) to build in
[Zig](https://ziglang.org/) :zap:

> [!Note]
> `zig translate-c -lc minivectorballs.c > minivectorballs.zig` was used as a starting point of the port.
>
> Most of the time was spent figuring out how to setup the build :joy:

## Screenshots

![CRT](files/CRT.png)

## Requirements

A fairly recent version of [Zig master](https://ziglang.org/download/#release-master)
(which would be `0.15.0-dev.1585` when this was written)

 - `SDL2`
 - `GLEW`
 - `pthread`

## Compilation

You should hopefully be able to compile the binary by calling `zig build`

> [!Note]
> As a convenience you can compile and run the binary via `zig build run`
> (or `zig build run -- -w` if you want to start in windowed mode)

## Links

 - https://mattiasgustavsson.itch.io/dos-like
 - https://ziglang.org/
