const std = @import("std");
const print = std.debug.print;
const Allocator = std.mem.Allocator;
const Io = std.Io;

const s = @import("../schemas/schemas.zig");

pub fn generateReport(io: Io, data: s.FuncAndDefinition, target_files: s.TargetFiles, file_type: s.FileTypes) !void {
    switch (file_type) {
        .go => {
            var writer = target_files.go_target_file.?.writer(io, &.{});
            try writer.seekTo(try target_files.go_target_file.?.length(io));

            if (target_files.go_target_file != null) _ = try writer.interface.print(
                \\```{s}
                \\{s}
                \\{s}
                \\```
            ++ "\n\n",
                .{ @tagName(file_type), if (data.docstring != null) data.docstring.? else "**UNDOCUMENTED**", data.func.? },
            ) else std.log.warn("could not write function: `{s}` to go report file", .{data.func.?});
        },
        .python => {
            var writer = target_files.py_target_file.?.writer(io, &.{});
            try writer.seekTo(try target_files.py_target_file.?.length(io));

            if (target_files.py_target_file != null) _ = try writer.interface.print(
                \\```{s}
                \\{s}
                \\{s}
                \\```
            ++ "\n\n",
                .{ @tagName(file_type), if (data.docstring != null) data.docstring.? else "**UNDOCUMENTED**", data.func.? },
            ) else std.log.warn("could not write function: `{s}` to python report file", .{data.func.?});
        },
        .zig => {
            var writer = target_files.zig_target_file.?.writer(io, &.{});
            try writer.seekTo(try target_files.zig_target_file.?.length(io));

            if (target_files.zig_target_file != null) _ = try writer.interface.print(
                \\```{s}
                \\{s}
                \\{s}
                \\```
            ++ "\n\n",
                .{ @tagName(file_type), if (data.docstring != null) data.docstring.? else "**UNDOCUMENTED**", data.func.? },
            ) else std.log.warn("could not write function: `{s}` to zig report file", .{data.func.?});
        },
    }
}

pub fn writeReportHeader(io: Io, file_type: s.FileTypes, target_file: Io.File) !void {
    switch (file_type) {
        .go => {
            var writer = target_file.writer(io, &.{});
            try writer.interface.writeAll("# `Go` Functions\n");
            try writer.flush();
        },
        .python => {
            var writer = target_file.writer(io, &.{});
            try writer.interface.writeAll("# `Python` Functions\n");
            try writer.flush();
        },
        .zig => {
            var writer = target_file.writer(io, &.{});
            try writer.interface.writeAll("# `Zig` Functions\n");
            try writer.flush();
        },
    }
}
