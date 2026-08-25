const std = @import("std");
const log = std.log;
const Io = std.Io;

const s = @import("../schemas/schemas.zig");

pub fn createTargetFile(target_dir: std.fs.Dir, file_type: s.FileTypes) std.fs.File {
    switch (file_type) {
        .go => {
            const go_target_file: std.fs.File = try target_dir.createFile("go_target_file", .{});
            defer go_target_file.close();
        },
        .python => {
            const python_target_file: std.fs.File = try target_dir.createFile("python_target_file", .{});
            defer python_target_file.close();
        },
        .zig => {
            const zig_target_file: std.fs.File = try target_dir.createFile("zig_target_file", .{});
            defer zig_target_file.close();
        },
    }
}

pub fn deleteUnusedTargetFiles(io: Io, target_dir: std.Io.Dir, target_file: []const u8) !void {
    target_dir.deleteFile(io, target_file) catch |err| {
        log.err("report file: `{s}` could not be deleted: {}", .{ target_file, err });
        return err;
    };
}
