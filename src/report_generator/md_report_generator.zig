const std = @import("std");
const print = std.debug.print;
const Allocator = std.mem.Allocator;

const s = @import("../schemas/schemas.zig");

pub fn generateReport(allocator: Allocator, data: s.FuncAndDefinition, target_files: s.TargetFiles, file_type: s.FileTypes) !void {
    const tmpl: []const u8 = try std.fmt.allocPrint(
        allocator,
        \\```bash
        \\{s}
        \\{s}
        \\```
    ++ "\n",
        .{ if (data.docstring != null) data.docstring.? else "> function definition missing", data.func.? },
    );
    defer allocator.free(tmpl);

    switch (file_type) {
        .go => {
            if (target_files.go_target_file != null) _ = try target_files.go_target_file.?.write(tmpl) else std.log.warn("could not write function: `{s}` to go report file", .{data.func.?});
        },
        .python => {
            if (target_files.py_target_file != null) _ = try target_files.py_target_file.?.write(tmpl) else std.log.warn("could not write function: `{s}` to python report file", .{data.func.?});
        },
        .zig => {
            if (target_files.zig_target_file != null) _ = try target_files.zig_target_file.?.write(tmpl) else std.log.warn("could not write function: `{s}` to zig report file", .{data.func.?});
        },
    }
}

pub fn writeReportHeader(file_type: s.FileTypes, target_file: std.fs.File) !void {
    switch (file_type) {
        .go => {
            _ = try target_file.write("# `Go` Functions\n");
        },
        .python => {
            _ = try target_file.write("# `Python` Functions\n");
        },
        .zig => {
            _ = try target_file.write("# `Zig` Functions\n");
        },
    }
}
