// Zig port of minivectorballs by nzy in dos-like
//
// - https://github.com/mattiasgustavsson/dos-like
// - https://github.com/mattiasgustavsson/dos-like/blob/bfb1542de009f1b51ef5f6a03eaa9649c3e54400/source/minivectorballs.c
// - https://ziglang.org/
//
// See end of file for original license
//                     / Peter Hellberg

const std = @import("std");

const signedRemainder = std.zig.c_translation.signedRemainder;

extern fn clearscreen() void;
extern fn getpal(index: c_int, r: [*c]c_int, g: [*c]c_int, b: [*c]c_int) void;
extern fn hline(x: c_int, y: c_int, len: c_int, color: c_int) void;
extern fn keystate(key: enum_keycode_t) c_int;
extern fn malloc(__size: c_ulong) ?*anyopaque;
extern fn rand() c_int;
extern fn screenbuffer() [*c]u8;
extern fn setpal(index: c_int, r: c_int, g: c_int, b: c_int) void;
extern fn setvideomode(mode: enum_videomode_t) void;
extern fn srand(__seed: c_uint) void;
extern fn swapbuffers() [*c]u8;
extern fn waitvbl() void;

const videomode_320x200: c_int = 7;
const enum_videomode_t = c_uint;

const KEY_ESCAPE: c_uint = 20;
const KEY_SPACE: c_uint = 25;
const enum_keycode_t = c_uint;

const struct_dot = extern struct {
    x: i16 = 0,
    y: i16 = 0,
    z: i16 = 0,
    yadd: i16 = 0,
    posshadow: u16 = 0,
    pos: u16 = 0,
    oldpos: u16 = 0,
    oldposshadow: u16 = 0,
    index_color: u8 = 0,
    visible: bool = false,
    shadow_visible: bool = false,
};

var dropper: i16 = 0;
var rota: i16 = @bitCast(@as(c_short, @truncate(-64)));
var rot: i16 = 0;
var rots: i16 = 0;
var grav: i16 = 0;
var gravd: i16 = 0;
var f: i16 = 0;
var frame: u16 = 0;
var dotnum: u16 = 0;
var dottaul: [1024]i16 = .{0} ** 1024;
var dots: [1024]struct_dot = [1]struct_dot{
    struct_dot{
        .x = @as(i16, @bitCast(@as(c_short, @truncate(0)))),
        .y = 0,
        .z = 0,
        .yadd = 0,
        .posshadow = 0,
        .pos = 0,
        .oldpos = 0,
        .oldposshadow = 0,
        .index_color = 0,
        .visible = false,
        .shadow_visible = false,
    },
} ++ [1]struct_dot{std.mem.zeroes(struct_dot)} ** 1023;

var rotsin: f32 = 0;
var rotcos: f32 = 0;
var gravitybottom: i16 = 8000;
var gravity: i16 = 0;
var gravityd: i16 = 16;
var rows: [200]u16 = .{0} ** 200;
var depthtable1: [128]u32 = .{0} ** 128;
var depthtable2: [128]u32 = .{0} ** 128;
var depthtable3: [128]u32 = .{0} ** 128;
var bgpic: [*c]u8 = std.mem.zeroes([*c]u8);
var vram: [*c]u8 = std.mem.zeroes([*c]u8);
var sin1024: [1024]i16 = [1024]i16{ 0, 1, 3, 4, 6, 7, 9, 10, 12, 14, 15, 17, 18, 20, 21, 23, 25, 26, 28, 29, 31, 32, 34, 36, 37, 39, 40, 42, 43, 45, 46, 48, 49, 51, 53, 54, 56, 57, 59, 60, 62, 63, 65, 66, 68, 69, 71, 72, 74, 75, 77, 78, 80, 81, 83, 84, 86, 87, 89, 90, 92, 93, 95, 96, 97, 99, 100, 102, 103, 105, 106, 108, 109, 110, 112, 113, 115, 116, 117, 119, 120, 122, 123, 124, 126, 127, 128, 130, 131, 132, 134, 135, 136, 138, 139, 140, 142, 143, 144, 146, 147, 148, 149, 151, 152, 153, 155, 156, 157, 158, 159, 161, 162, 163, 164, 166, 167, 168, 169, 170, 171, 173, 174, 175, 176, 177, 178, 179, 181, 182, 183, 184, 185, 186, 187, 188, 189, 190, 191, 192, 193, 194, 195, 196, 197, 198, 199, 200, 201, 202, 203, 204, 205, 206, 207, 208, 209, 210, 211, 211, 212, 213, 214, 215, 216, 217, 217, 218, 219, 220, 221, 221, 222, 223, 224, 225, 225, 226, 227, 227, 228, 229, 230, 230, 231, 232, 232, 233, 234, 234, 235, 235, 236, 237, 237, 238, 238, 239, 239, 240, 241, 241, 242, 242, 243, 243, 244, 244, 244, 245, 245, 246, 246, 247, 247, 247, 248, 248, 249, 249, 249, 250, 250, 250, 251, 251, 251, 251, 252, 252, 252, 252, 253, 253, 253, 253, 254, 254, 254, 254, 254, 254, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 256, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 254, 254, 254, 254, 254, 254, 253, 253, 253, 253, 252, 252, 252, 252, 251, 251, 251, 251, 250, 250, 250, 249, 249, 249, 248, 248, 247, 247, 247, 246, 246, 245, 245, 244, 244, 244, 243, 243, 242, 242, 241, 241, 240, 239, 239, 238, 238, 237, 237, 236, 235, 235, 234, 234, 233, 232, 232, 231, 230, 230, 229, 228, 227, 227, 226, 225, 225, 224, 223, 222, 221, 221, 220, 219, 218, 217, 217, 216, 215, 214, 213, 212, 211, 211, 210, 209, 208, 207, 206, 205, 204, 203, 202, 201, 200, 199, 198, 197, 196, 195, 194, 193, 192, 191, 190, 189, 188, 187, 186, 185, 184, 183, 182, 181, 179, 178, 177, 176, 175, 174, 173, 171, 170, 169, 168, 167, 166, 164, 163, 162, 161, 159, 158, 157, 156, 155, 153, 152, 151, 149, 148, 147, 146, 144, 143, 142, 140, 139, 138, 136, 135, 134, 132, 131, 130, 128, 127, 126, 124, 123, 122, 120, 119, 117, 116, 115, 113, 112, 110, 109, 108, 106, 105, 103, 102, 100, 99, 97, 96, 95, 93, 92, 90, 89, 87, 86, 84, 83, 81, 80, 78, 77, 75, 74, 72, 71, 69, 68, 66, 65, 63, 62, 60, 59, 57, 56, 54, 53, 51, 49, 48, 46, 45, 43, 42, 40, 39, 37, 36, 34, 32, 31, 29, 28, 26, 25, 23, 21, 20, 18, 17, 15, 14, 12, 10, 9, 7, 6, 4, 3, 1, 0, -1, -3, -4, -6, -7, -9, -10, -12, -14, -15, -17, -18, -20, -21, -23, -25, -26, -28, -29, -31, -32, -34, -36, -37, -39, -40, -42, -43, -45, -46, -48, -49, -51, -53, -54, -56, -57, -59, -60, -62, -63, -65, -66, -68, -69, -71, -72, -74, -75, -77, -78, -80, -81, -83, -84, -86, -87, -89, -90, -92, -93, -95, -96, -97, -99, -100, -102, -103, -105, -106, -108, -109, -110, -112, -113, -115, -116, -117, -119, -120, -122, -123, -124, -126, -127, -128, -130, -131, -132, -134, -135, -136, -138, -139, -140, -142, -143, -144, -146, -147, -148, -149, -151, -152, -153, -155, -156, -157, -158, -159, -161, -162, -163, -164, -166, -167, -168, -169, -170, -171, -173, -174, -175, -176, -177, -178, -179, -181, -182, -183, -184, -185, -186, -187, -188, -189, -190, -191, -192, -193, -194, -195, -196, -197, -198, -199, -200, -201, -202, -203, -204, -205, -206, -207, -208, -209, -210, -211, -211, -212, -213, -214, -215, -216, -217, -217, -218, -219, -220, -221, -221, -222, -223, -224, -225, -225, -226, -227, -227, -228, -229, -230, -230, -231, -232, -232, -233, -234, -234, -235, -235, -236, -237, -237, -238, -238, -239, -239, -240, -241, -241, -242, -242, -243, -243, -244, -244, -244, -245, -245, -246, -246, -247, -247, -247, -248, -248, -249, -249, -249, -250, -250, -250, -251, -251, -251, -251, -252, -252, -252, -252, -253, -253, -253, -253, -254, -254, -254, -254, -254, -254, -255, -255, -255, -255, -255, -255, -255, -255, -255, -255, -255, -255, -255, -255, -256, -255, -255, -255, -255, -255, -255, -255, -255, -255, -255, -255, -255, -255, -255, -254, -254, -254, -254, -254, -254, -253, -253, -253, -253, -252, -252, -252, -252, -251, -251, -251, -251, -250, -250, -250, -249, -249, -249, -248, -248, -247, -247, -247, -246, -246, -245, -245, -244, -244, -244, -243, -243, -242, -242, -241, -241, -240, -239, -239, -238, -238, -237, -237, -236, -235, -235, -234, -234, -233, -232, -232, -231, -230, -230, -229, -228, -227, -227, -226, -225, -225, -224, -223, -222, -221, -221, -220, -219, -218, -217, -217, -216, -215, -214, -213, -212, -211, -211, -210, -209, -208, -207, -206, -205, -204, -203, -202, -201, -200, -199, -198, -197, -196, -195, -194, -193, -192, -191, -190, -189, -188, -187, -186, -185, -184, -183, -182, -181, -179, -178, -177, -176, -175, -174, -173, -171, -170, -169, -168, -167, -166, -164, -163, -162, -161, -159, -158, -157, -156, -155, -153, -152, -151, -149, -148, -147, -146, -144, -143, -142, -140, -139, -138, -136, -135, -134, -132, -131, -130, -128, -127, -126, -124, -123, -122, -120, -119, -117, -116, -115, -113, -112, -110, -109, -108, -106, -105, -103, -102, -100, -99, -97, -96, -95, -93, -92, -90, -89, -87, -86, -84, -83, -81, -80, -78, -77, -75, -74, -72, -71, -69, -68, -66, -65, -63, -62, -60, -59, -57, -56, -54, -53, -51, -49, -48, -46, -45, -43, -42, -40, -39, -37, -36, -34, -32, -31, -29, -28, -26, -25, -23, -21, -20, -18, -17, -15, -14, -12, -10, -9, -7, -6, -4, -3, -1 };
var cols: [12]u16 = [12]u16{ 0, 0, 0, 4, 25, 30, 8, 40, 45, 16, 55, 60 };
var pal: [768]u8 = .{0} ** 768;
var pal2: [768]u8 = .{0} ** 768;

fn isin(deg: c_int) i16 {
    return sin1024[@intCast(deg & 1023)];
}

fn icos(deg: c_int) i16 {
    return sin1024[@intCast((deg + 256) & 1023)];
}

fn setupDots() void {
    dotnum = @as(u16, @bitCast(@as(c_short, @truncate(@as(c_int, 512)))));
    {
        var a: c_int = 0;
        while (a < @as(c_int, @bitCast(@as(c_uint, dotnum)))) : (a += 1) {
            dottaul[@intCast(a)] = @as(i16, @bitCast(@as(c_short, @truncate(a))));
        }
    }
    {
        var a: c_int = 0;
        while (a < 500) : (a += 1) {
            const b: c_int = signedRemainder(rand(), @as(c_int, @bitCast(@as(c_uint, dotnum))));
            const c: c_int = signedRemainder(rand(), @as(c_int, @bitCast(@as(c_uint, dotnum))));
            const d: c_int = @bitCast(@as(c_int, dottaul[@intCast(b)]));
            dottaul[@intCast(b)] = dottaul[@intCast(c)];
            dottaul[@intCast(c)] = @bitCast(@as(c_short, @truncate(d)));
        }
    }

    dropper = @as(i16, @bitCast(@as(c_short, @truncate(@as(c_int, 22000)))));

    {
        var a: c_int = 0;
        while (a < @as(c_int, @bitCast(@as(c_uint, dotnum)))) : (a += 1) {
            dots[@intCast(a)].x = 0;
            dots[@intCast(a)].y = @as(i16, @bitCast(@as(c_short, @truncate(@as(c_int, 2560) - @as(c_int, @bitCast(@as(c_int, dropper)))))));
            dots[@intCast(a)].z = 0;
            dots[@intCast(a)].yadd = 0;
        }
    }

    grav = 3;
    gravd = 13;
    gravitybottom = 8105;

    {
        var a: c_int = 0;
        while (a < 500) : (a += 1) {
            const b: c_int = signedRemainder(rand(), @as(c_int, @bitCast(@as(c_uint, dotnum))));
            const c: c_int = signedRemainder(rand(), @as(c_int, @bitCast(@as(c_uint, dotnum))));
            const t: struct_dot = dots[@intCast(b)];
            dots[@intCast(b)] = dots[@intCast(c)];
            dots[@intCast(c)] = t;
        }
    }

    {
        var a: c_int = 0;
        while (a < 200) : (a += 1) {
            rows[@intCast(a)] = @bitCast(@as(c_short, @truncate(a * 320)));
        }
    }

    {
        var a: c_int = 0;
        while (a < 128) : (a += 1) {
            var c: c_int = @divTrunc((a - @divTrunc(43 + 20, 2)) * @as(c_int, 3), 4) + 8;
            if (c < 0) {
                c = 0;
            } else if (c > 15) {
                c = 15;
            }
            c = @as(c_int, 15) - c;
            depthtable1[@intCast(a)] = @bitCast(@as(c_int, 514) + (67372036 * c));
            depthtable2[@intCast(a)] = @bitCast(@as(c_int, 33751810) + (67372036 * c));
            depthtable3[@intCast(a)] = @bitCast(@as(c_int, 514) + (67372036 * c));
        }
    }
}

fn setupPal() void {
    {
        var i: c_int = 0;
        while (i < 256) : (i += 1) {
            getpal(
                i,
                @ptrCast(@alignCast(&pal[@intCast((@as(c_int, 3) * i) + 0)])),
                @ptrCast(@alignCast(&pal[@intCast((@as(c_int, 3) * i) + 1)])),
                @ptrCast(@alignCast(&pal[@intCast((@as(c_int, 3) * i) + 2)])),
            );
        }
    }
    var i: u8 = 0;
    {
        var a: c_int = 0;
        while (a < 16) : (a += 1) {
            var b: c_int = 0;
            while (b < 4) : (b += 1) {
                const c: c_int = 100 + (a * 9);
                pal[@intCast((@as(c_int, 3) * @as(c_int, @bitCast(@as(c_uint, i)))) + 0)] = @bitCast(@as(u8, @truncate(
                    cols[@intCast((b * @as(c_int, 3)) + 0)],
                )));
                pal[@intCast((@as(c_int, 3) * @as(c_int, @bitCast(@as(c_uint, i)))) + 1)] = @bitCast(@as(i8, @truncate(@divTrunc(@as(c_int, @bitCast(@as(
                    c_uint,
                    cols[@intCast((b * @as(c_int, 3)) + @as(c_int, 1))],
                ))) * c, 256))));
                pal[@intCast((@as(c_int, 3) * @as(c_int, @bitCast(@as(c_uint, i)))) + 2)] = @bitCast(@as(i8, @truncate(@divTrunc(@as(c_int, @bitCast(@as(
                    c_uint,
                    cols[@intCast((b * @as(c_int, 3)) + @as(c_int, 2))],
                ))) * c, 256))));
                i +%= 1;
            }
        }
    }
    pal[@intCast((@as(c_int, 3) * @as(c_int, 255)) + 0)] = 31;
    pal[@intCast((@as(c_int, 3) * @as(c_int, 255)) + 1)] = 0;
    pal[@intCast((@as(c_int, 3) * @as(c_int, 255)) + 2)] = 15;
    {
        var a: c_int = 0;
        while (a < 100) : (a += 1) {
            var c: c_int = 64 - @divTrunc(256, a + 4);
            c = @divTrunc(c * c, 64);
            pal[@intCast((@as(c_int, 3) * (64 + a)) + 0)] = blk: {
                const tmp = blk_1: {
                    const tmp_2 = @as(u8, @bitCast(@as(i8, @truncate(@divTrunc(c, 4)))));
                    pal[@intCast((@as(c_int, 3) * (64 + a)) + 2)] = tmp_2;
                    break :blk_1 tmp_2;
                };
                pal[@intCast((@as(c_int, 3) * (64 + a)) + 1)] = tmp;
                break :blk tmp;
            };
        }
    }
}

fn drawDot(d: [*c]struct_dot) void {
    if (d.*.shadow_visible) {
        const c: u16 = @bitCast(@as(c_short, @truncate(87 + (87 * 256))));
        vram[d.*.posshadow] = @as(u8, @bitCast(@as(u8, @truncate(c))));
    }
    if (d.*.visible) {
        const val1: u16 = @bitCast(@as(c_short, @truncate(@as(c_int, @bitCast(@as(c_uint, @as([*c]u8, @ptrCast(@alignCast(@as([*c]u32, @ptrCast(@alignCast(&depthtable1[0]))))))[d.*.index_color]))) | (@as(c_int, @bitCast(@as(c_uint, (blk: {
            const tmp = @as(c_int, @bitCast(@as(c_uint, d.*.index_color))) + 1;
            if (tmp >= 0) break :blk @as([*c]u8, @ptrCast(@alignCast(@as([*c]u32, @ptrCast(@alignCast(&depthtable1[0])))))) + @as(usize, @intCast(tmp)) else break :blk @as([*c]u8, @ptrCast(@alignCast(@as([*c]u32, @ptrCast(@alignCast(&depthtable1[0])))))) - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
        }).*))) << 8))));
        @as([*c]u16, @ptrCast(@alignCast((vram + @as(usize, @bitCast(@as(isize, @intCast(@as(c_int, @bitCast(@as(c_uint, d.*.pos)))))))) + @as(usize, @bitCast(@as(isize, 1)))))).* = val1;
        const val2: u32 = @bitCast(((@as(c_int, @bitCast(@as(c_uint, @as([*c]u8, @ptrCast(@alignCast(@as([*c]u32, @ptrCast(@alignCast(&depthtable2[0]))))))[d.*.index_color]))) | (@as(c_int, @bitCast(@as(c_uint, (blk: {
            const tmp = @as(c_int, @bitCast(@as(c_uint, d.*.index_color))) + 1;
            if (tmp >= 0) break :blk @as([*c]u8, @ptrCast(@alignCast(@as([*c]u32, @ptrCast(@alignCast(&depthtable2[0])))))) + @as(usize, @intCast(tmp)) else break :blk @as([*c]u8, @ptrCast(@alignCast(@as([*c]u32, @ptrCast(@alignCast(&depthtable2[0])))))) - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
        }).*))) << 8)) | (@as(c_int, @bitCast(@as(c_uint, (blk: {
            const tmp = @as(c_int, @bitCast(@as(c_uint, d.*.index_color))) + 2;
            if (tmp >= 0) break :blk @as([*c]u8, @ptrCast(@alignCast(@as([*c]u32, @ptrCast(@alignCast(&depthtable2[0])))))) + @as(usize, @intCast(tmp)) else break :blk @as([*c]u8, @ptrCast(@alignCast(@as([*c]u32, @ptrCast(@alignCast(&depthtable2[0])))))) - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
        }).*))) << 16)) | (@as(c_int, @bitCast(@as(c_uint, (blk: {
            const tmp = @as(c_int, @bitCast(@as(c_uint, d.*.index_color))) + @as(c_int, 3);
            if (tmp >= 0) break :blk @as([*c]u8, @ptrCast(@alignCast(@as([*c]u32, @ptrCast(@alignCast(&depthtable2[0])))))) + @as(usize, @intCast(tmp)) else break :blk @as([*c]u8, @ptrCast(@alignCast(@as([*c]u32, @ptrCast(@alignCast(&depthtable2[0])))))) - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
        }).*))) << 24));
        @as([*c]u32, @ptrCast(@alignCast((vram + @as(usize, @bitCast(@as(isize, @intCast(@as(c_int, @bitCast(@as(c_uint, d.*.pos)))))))) + @as(usize, @bitCast(@as(isize, 320)))))).* = val2;
        const val3: u16 = @bitCast(@as(c_short, @truncate(@as(c_int, @bitCast(@as(c_uint, @as([*c]u8, @ptrCast(@alignCast(@as([*c]u32, @ptrCast(@alignCast(&depthtable3[0]))))))[d.*.index_color]))) | (@as(c_int, @bitCast(@as(c_uint, (blk: {
            const tmp = @as(c_int, @bitCast(@as(c_uint, d.*.index_color))) + 1;
            if (tmp >= 0) break :blk @as([*c]u8, @ptrCast(@alignCast(@as([*c]u32, @ptrCast(@alignCast(&depthtable3[0])))))) + @as(usize, @intCast(tmp)) else break :blk @as([*c]u8, @ptrCast(@alignCast(@as([*c]u32, @ptrCast(@alignCast(&depthtable3[@as(usize, 0)])))))) - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
        }).*))) << 8))));
        @as([*c]u16, @ptrCast(@alignCast((vram + @as(usize, @bitCast(@as(isize, @intCast(@as(c_int, @bitCast(@as(c_uint, d.*.pos)))))))) + @as(usize, @bitCast(@as(isize, @intCast(@as(c_int, 641)))))))).* = val3;
    }
}

fn drawDots() void {
    var i: c_int = 0;
    while (i < @as(c_int, @bitCast(@as(c_uint, dotnum)))) : (i += 1) {
        drawDot(&dots[@as(c_uint, @intCast(i))]);
    }
}

fn drawFloor() void {
    var a: u8 = 0;
    while (@as(c_int, @bitCast(@as(c_uint, a))) < 100) : (a +%= 1) {
        hline(0, @as(c_int, 100) + @as(c_int, @bitCast(@as(c_uint, a))), 320, @as(c_int, @bitCast(@as(c_uint, a))) + 64);
    }
}

fn fadein() void {
    var b: i32 = 64;
    while (b >= 0) : (b -= 1) {
        var c: i32 = 0;
        while (c < 768) : (c += 1) {
            var a: i32 = pal[@intCast(c)] - b;
            if (a < 0) a = 0;
            pal2[@intCast(c)] = @intCast(a);
        }

        waitvbl();
        waitvbl();

        var i: i32 = 0;
        while (i < 256) : (i += 1) {
            setpal(
                i,
                pal2[@intCast(i * 3 + 0)],
                pal2[@intCast(i * 3 + 1)],
                pal2[@intCast(i * 3 + 2)],
            );
        }
    }
}

fn updateGravity(d: [*c]struct_dot) void {
    d.*.visible = 0 != 0;
    d.*.shadow_visible = 0 != 0;
    const bp: f32 = (((@as(f32, @floatFromInt(@as(c_int, @bitCast(@as(c_int, d.*.z))))) * rotcos) - (@as(f32, @floatFromInt(@as(c_int, @bitCast(@as(c_int, d.*.x))))) * rotsin)) / 65536.0) + 9000.0;
    if (bp <= 0.0) return;
    const t: f32 = ((@as(f32, @floatFromInt(@as(c_int, @bitCast(@as(c_int, d.*.z))))) * rotsin) + (@as(f32, @floatFromInt(@as(c_int, @bitCast(@as(c_int, d.*.x))))) * rotcos)) / 256.0;
    const ax: f32 = ((t + (t / 8.0)) / bp) + 160.0;
    if ((ax >= @as(f32, @floatFromInt(0))) and (ax < @as(f32, @floatFromInt(320)))) {
        const shadow: c_int = @intFromFloat((524288.0 / bp) + 100.0);
        if ((shadow >= 0) and (shadow < 200)) {
            d.*.posshadow = @bitCast(@as(c_short, @truncate(@as(c_int, @bitCast(@as(c_uint, rows[@intCast(shadow)]))) + @as(c_int, @intFromFloat(ax)))));
            d.*.shadow_visible = 1 != 0;
            d.*.yadd += @bitCast(@as(c_short, @truncate(@as(c_int, @bitCast(@as(c_int, gravity))))));
            var b_: i16 = @bitCast(@as(c_short, @truncate(@as(c_int, @bitCast(@as(c_int, d.*.y))) + @as(c_int, @bitCast(@as(c_int, d.*.yadd))))));
            if (@as(c_int, @bitCast(@as(c_int, b_))) >= @as(c_int, @bitCast(@as(c_int, gravitybottom)))) {
                d.*.yadd = @bitCast(@as(c_short, @truncate(@divTrunc(-@as(c_int, @bitCast(@as(c_int, d.*.yadd))) * @as(c_int, @bitCast(@as(c_int, gravityd))), @as(c_int, 16)))));
                b_ = @bitCast(@as(c_short, @truncate(@as(c_int, @bitCast(@as(c_int, gravitybottom))) + @as(c_int, @bitCast(@as(c_int, d.*.yadd))))));
            }
            d.*.y = b_;
            const b__: i16 = @intFromFloat((@as(f32, @floatFromInt(@as(c_int, @bitCast(@as(c_int, b_))) << 6)) / bp) + 100);
            if ((@as(c_int, @bitCast(@as(c_int, b__))) >= 0) and (@as(c_int, @bitCast(@as(c_int, b__))) < 200)) {
                const c: i16 = @bitCast(@as(c_short, @truncate(@as(c_int, @bitCast(@as(c_uint, rows[@intCast(b__)]))) + @as(c_int, @intFromFloat(ax)))));
                const ic: u8 = @bitCast(@as(i8, @truncate((@as(c_int, @bitCast(@as(c_int, @as(i16, @intFromFloat(bp))))) >> 6) & ~@as(c_int, 3))));
                d.*.pos = @bitCast(c);
                d.*.index_color = ic;
                d.*.visible = 1 != 0;
            }
        }
    }
}

fn updateDots() void {
    if (frame == @as(c_int, 500)) {
        f = 0;
    }
    const j = struct {
        var static: c_int = 0;
    };
    const i_: c_int = @bitCast(@as(c_int, dottaul[@intCast(j.static)]));
    j.static = signedRemainder(j.static + 1, @as(c_int, @bitCast(@as(c_uint, dotnum))));
    if (frame < 500) {
        const idx: usize = @intCast(i_);
        dots[idx].x = isin(f * 11) * 40;
        dots[idx].y = icos(f * 13) * 10 - dropper;
        dots[idx].z = isin(f * 17) * 40;
        dots[idx].yadd = 0;
    } else if (frame < 900) {
        const idx: usize = @intCast(i_);
        dots[idx].x = icos(f * 15) * 55;
        dots[idx].y = dropper;
        dots[idx].z = isin(f * 15) * 55;
        dots[idx].yadd = -260;
    } else if (frame < 1700) {
        const a: c_int = @divTrunc(sin1024[@intCast(frame & 1023)], 8);

        const idx: usize = @intCast(i_);
        dots[idx].x = @intCast(icos(f * 66) * a);
        dots[idx].y = 8000;
        dots[idx].z = @intCast(isin(f * 66) * a);
        dots[idx].yadd = -300;
    } else if (frame < 2360) {
        const idx: usize = @intCast(i_);
        dots[idx].x = @intCast(rand() - 16384);
        dots[idx].y = @intCast(8000 - @divTrunc(rand(), 2));
        dots[idx].z = @intCast(rand() - 16384);
        dots[idx].yadd = 0;

        if (frame > 1900 and (frame & 31) == 0 and grav > 0) {
            grav -= 1;
        }
    } else if (frame < 2400) {
        const a: c_int = frame - 2360;

        var b: usize = 0;
        while (b < 768) : (b += 3) {
            var c: c_int = @as(c_int, @intCast(pal[b])) + a * 3;
            if (c > 63) c = 63;
            pal2[b] = @intCast(c);

            c = @as(c_int, @intCast(pal[b + 1])) + a * 3;
            if (c > 63) c = 63;
            pal2[b + 1] = @intCast(c);

            c = @as(c_int, @intCast(pal[b + 2])) + a * 4;
            if (c > 63) c = 63;
            pal2[b + 2] = @intCast(c);
        }
    } else if (frame < 2440) {
        const a: c_int = frame - 2400;

        var b: usize = 0;
        while (b < 768) : (b += 3) {
            var c: c_int = 63 - a * 2;
            if (c < 0) c = 0;

            const v: u8 = @intCast(c);
            pal2[b] = v;
            pal2[b + 1] = v;
            pal2[b + 2] = v;
        }
    }

    if (dropper > 4000) {
        dropper -= 100;
    }

    rotcos = @floatFromInt(icos(rot) * 64);
    rotsin = @floatFromInt(isin(rot) * 64);

    rots += 2;

    if (frame > 1900) {
        rot += @divTrunc(rota, 64);
        rota -= 1;
    } else {
        rot = isin(rots);
    }

    f += 1;
    gravity = grav;
    gravityd = gravd;

    var i: u16 = 0;

    while (i < dotnum) : (i += 1) {
        updateGravity(&dots[i]);
    }
}

fn adjustFramerate() c_int {
    return 1;
}

fn setpalette(p: [*c]u8) void {
    var i: c_int = 0;
    while (i < 256) : (i += 1) {
        setpal(i, @as(c_int, @bitCast(@as(c_uint, (blk: {
            const tmp = @as(c_int, 3) * i;
            if (tmp >= 0) break :blk p + @as(usize, @intCast(tmp)) else break :blk p - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
        }).*))), @as(c_int, @bitCast(@as(c_uint, (blk: {
            const tmp = (@as(c_int, 3) * i) + 1;
            if (tmp >= 0) break :blk p + @as(usize, @intCast(tmp)) else break :blk p - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
        }).*))), @as(c_int, @bitCast(@as(c_uint, (blk: {
            const tmp = (@as(c_int, 3) * i) + 2;
            if (tmp >= 0) break :blk p + @as(usize, @intCast(tmp)) else break :blk p - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
        }).*))));
    }
}

pub export fn dosmain(_: c_int, _: [*c][*c]u8) c_int {
    srand(64764);
    setvideomode(videomode_320x200);

    vram = screenbuffer();

    setupDots();
    setupPal();

    {
        var i: c_int = 0;
        while (i < 256) : (i += 1) {
            setpal(i, 0, 0, 0);
        }
    }

    drawFloor();
    fadein();

    bgpic = @as(
        [*c]u8,
        @ptrCast(
            @alignCast(malloc(@as(c_ulong, @bitCast(@as(c_long, 320 * 200))))),
        ),
    );

    {
        var i: c_int = 0;
        while (i < (320 * 200)) : (i += 1) {
            (blk: {
                const tmp = i;
                if (tmp >= 0) break :blk bgpic + @as(usize, @intCast(tmp)) else break :blk bgpic - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
            }).* = (blk: {
                const tmp = i;
                if (tmp >= 0) break :blk vram + @as(usize, @intCast(tmp)) else break :blk vram - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
            }).*;
        }
    }

    while (frame < 2450) {
        if (frame > 2300) {
            setpalette(@ptrCast(@alignCast(&pal2[0])));
        }

        waitvbl();

        if (keystate(KEY_SPACE) != 0) continue;

        frame +%= 1;

        clearscreen();
        drawFloor();

        var num: c_int = adjustFramerate();
        while (num != 0) : (num -= 1) {
            updateDots();
        }

        drawDots();

        vram = swapbuffers();

        if (keystate(KEY_ESCAPE) != 0) break;
    }

    return 0;
}

pub const main = dosmain;

// License of the original version by nzy

// Copyright (c) 2024, Constantine Zykov
// All rights reserved.
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are met:
// * Redistributions of source code must retain the above copyright notice, this
// list of conditions and the following disclaimer.
// * Redistributions in binary form must reproduce the above copyright notice,
// this list of conditions and the following disclaimer in the documentation
// and/or other materials provided with the distribution.
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
// ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
// LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
// CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
// SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
// INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
// CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
// ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF
// THE POSSIBILITY OF SUCH DAMAGE.
