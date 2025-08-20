const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = .ReleaseFast;

    const exe = b.addExecutable(.{
        .name = "zig-dos-like-minivectorballs",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/minivectorballs.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });

    const dos = b.dependency("dos", .{
        .target = target,
        .optimize = optimize,
    });

    exe.addCSourceFile(.{
        .file = dos.path("source/dos.c"),
    });

    exe.addIncludePath(dos.path("source"));

    exe.linkSystemLibrary("SDL2");
    exe.linkSystemLibrary("GLEW");
    exe.linkSystemLibrary("pthread");

    if (target.result.os.tag == .macos) {
        exe.linkFramework("OpenGL");
    }

    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);

    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
}
