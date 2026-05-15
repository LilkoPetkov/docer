const std = @import("std");
const print = std.debug.print;
const Allocator = std.mem.Allocator;
const t = std.testing;

const s = @import("../schemas/schemas.zig");

pub fn processFile(allocator: Allocator, file: *s.File) !std.ArrayList(s.PythonFuncAndDoc) {
    const file_content_buf = try allocator.alloc(u8, file.file_size);
    defer allocator.free(file_content_buf);
    _ = try file.fd.read(file_content_buf);

    var python_data: std.ArrayList(s.PythonFuncAndDoc) = try .initCapacity(allocator, 1024);
    var func_data: std.ArrayList(u8) = try .initCapacity(allocator, 32);
    defer func_data.deinit(allocator);
    var func_doc_string: std.ArrayList(u8) = try .initCapacity(allocator, 256);
    defer func_doc_string.deinit(allocator);

    var context: s.PythonObjectContext = .{};

    for (file_content_buf, 0..) |byte, idx| {
        if (context.func_recorded) {
            if (byte != 0x22 and
                byte != 0x20 and
                byte != 0x0A and
                !context.doc_string_found)
            {
                const func: []u8 = try allocator.dupe(u8, func_data.items);
                func_data.clearAndFree(allocator);
                const pfad: s.PythonFuncAndDoc = .{ .docstring = null, .func = func };
                try python_data.append(allocator, pfad);

                context.func_recorded = false;
            } else if (byte == 0x22 and
                idx + 2 < file_content_buf.len and
                file_content_buf[idx + 1] == 0x22 and
                file_content_buf[idx + 2] == 0x22)
            {
                if (!context.doc_string_found) {
                    context.doc_string_found = true;
                    try func_doc_string.append(allocator, byte);
                } else {
                    try func_doc_string.appendNTimes(allocator, 0x22, 3);

                    const func: []u8 = try allocator.dupe(u8, func_data.items);
                    const dc: []u8 = try allocator.dupe(u8, func_doc_string.items);

                    func_data.clearAndFree(allocator);
                    func_doc_string.clearAndFree(allocator);

                    const pfad: s.PythonFuncAndDoc = .{ .docstring = dc, .func = func };
                    try python_data.append(allocator, pfad);

                    context.doc_string_found = false;
                    context.func_recorded = false;
                }
            } else if (context.doc_string_found) {
                try func_doc_string.append(allocator, byte);
            }

            continue;
        }

        if (context.func_found and byte == 0x29) {
            try func_data.append(allocator, byte);
            context.closing_func_bracket_found = true;
        } else if (context.func_found and !context.closing_func_bracket_found) {
            try func_data.append(allocator, byte);
        } else if (context.func_found and context.closing_func_bracket_found) {
            if (byte != 0x3A) try func_data.append(allocator, byte) else {
                context.func_found = false;
                context.closing_func_bracket_found = false;
                context.func_recorded = true;
            }
        }

        if (byte == 0x64 and
            idx + 3 < file_content_buf.len and
            file_content_buf[idx + 1] == 0x65 and
            file_content_buf[idx + 2] == 0x66 and
            file_content_buf[idx + 3] == 0x20 and
            !context.func_found)
        {
            try func_data.append(allocator, byte);
            context.func_found = true;
        }
    }

    return python_data;
}
