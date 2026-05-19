const std = @import("std");
const print = std.debug.print;
const Allocator = std.mem.Allocator;
const t = std.testing;

const s = @import("../schemas/schemas.zig");

pub fn processGoFile(allocator: Allocator, file: *s.File) !void {
    const file_content_buf = try allocator.alloc(u8, file.file_size);
    defer allocator.free(file_content_buf);
    _ = try file.fd.read(file_content_buf);

    // var go_data: std.ArrayList(s.GoFuncAndDefinition) = try .initCapacity(allocator, 1024);
    var func_data: std.ArrayList(u8) = try .initCapacity(allocator, 32);
    defer func_data.deinit(allocator);
    var func_definition: std.ArrayList(u8) = try .initCapacity(allocator, 256);
    defer func_definition.deinit(allocator);

    // For future context struct
    var is_first_line_char: bool = false;
    var fd_found: bool = false;
    var is_func_found: bool = false;

    for (file_content_buf, 0..) |byte, idx| {
        switch (is_func_found) {
            false => {
                if (fd_found and byte == 0x0A and !is_first_line_char) {
                    is_first_line_char = true;
                    try func_definition.append(allocator, byte);
                } else if (is_first_line_char) {
                    if (byte == 0x2F and
                        idx + 1 < file_content_buf.len and
                        file_content_buf[idx + 1] == 0x2F)
                    {
                        try func_definition.append(allocator, byte);
                        is_first_line_char = false;
                    } else if (byte != 0x2F and
                        byte == 0x66 and
                        idx + 3 < file_content_buf.len and
                        file_content_buf[idx + 1] == 0x75 and
                        file_content_buf[idx + 2] == 0x6E and
                        file_content_buf[idx + 3] == 0x63)
                    {
                        try func_data.append(allocator, byte);
                        is_func_found = true;

                        print("{s}\n", .{func_definition.items});
                        func_definition.clearAndFree(allocator);

                        is_first_line_char = false;
                        fd_found = false;
                    } else {
                        print("Skipping {s}\n", .{func_definition.items});
                        func_definition.clearAndFree(allocator);

                        is_first_line_char = false;
                        fd_found = false;
                    }
                } else if (byte == 0x2F and
                    idx + 1 < file_content_buf.len and
                    !fd_found and
                    file_content_buf[idx + 1] == 0x2F)
                {
                    try func_definition.append(allocator, byte);
                    fd_found = true;
                } else if (fd_found) {
                    try func_definition.append(allocator, byte);
                }
            },
            true => {},
        }
    }
}
