const std = @import("std");
const print = std.debug.print;
const Allocator = std.mem.Allocator;

const s = @import("../schemas/schemas.zig");

pub fn generateReport(allocator: Allocator, data: s.FuncAndDefinition, target_file: std.fs.File) !void {
    const tmpl: []const u8 = try std.fmt.allocPrint(
        allocator,
        \\```bash
        \\{s}
        \\{s}
        \\```
    ++ "\n",
        .{ if (data.docstring != null) data.docstring.? else "", data.func.? },
    );
    defer allocator.free(tmpl);

    _ = try target_file.write(tmpl);
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
