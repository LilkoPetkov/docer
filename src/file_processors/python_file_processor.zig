const std = @import("std");
const print = std.debug.print;
const Allocator = std.mem.Allocator;

const s = @import("../schemas/schemas.zig");

pub const pythonByteChecks = struct {
    file_content_buf: *[]u8,

    fn isNotCommentLineQuote(_: @This(), byte: u8, doc_string_found: bool) bool {
        return byte != 0x22 and
            byte != 0x20 and
            byte != 0x0A and
            !doc_string_found;
    }

    fn isDocString(self: @This(), byte: u8, idx: usize) bool {
        return byte == 0x22 and
            idx + 2 < self.file_content_buf.*.len and
            self.file_content_buf.*[idx + 1] == 0x22 and
            self.file_content_buf.*[idx + 2] == 0x22;
    }

    fn isFunc(self: @This(), byte: u8, idx: usize, func_found: bool) bool {
        return byte == 0x64 and
            idx + 3 < self.file_content_buf.*.len and
            self.file_content_buf.*[idx + 1] == 0x65 and
            self.file_content_buf.*[idx + 2] == 0x66 and
            self.file_content_buf.*[idx + 3] == 0x20 and
            !func_found;
    }
};

pub fn processPythonFile(allocator: Allocator, file: *s.File) !std.ArrayList(s.FuncAndDefinition) {
    var file_content_buf = try allocator.alloc(u8, file.file_size);
    defer allocator.free(file_content_buf);
    _ = try file.fd.read(file_content_buf);

    var python_data: std.ArrayList(s.FuncAndDefinition) = try .initCapacity(allocator, 1024);
    var func_data: std.ArrayList(u8) = try .initCapacity(allocator, 32);
    defer func_data.deinit(allocator);
    var func_doc_string: std.ArrayList(u8) = try .initCapacity(allocator, 256);
    defer func_doc_string.deinit(allocator);

    const check_ctx: pythonByteChecks = .{ .file_content_buf = &file_content_buf };
    var context: s.PythonObjectContext = .{};

    for (file_content_buf, 0..) |byte, idx| {
        if (context.func_recorded) {
            if (check_ctx.isNotCommentLineQuote(byte, context.doc_string_found)) {
                const func: []u8 = try allocator.dupe(u8, func_data.items);
                func_data.clearAndFree(allocator);
                const pfad: s.FuncAndDefinition = .{ .docstring = null, .func = func };
                try python_data.append(allocator, pfad);

                context.func_recorded = false;
            } else if (check_ctx.isDocString(byte, idx)) {
                if (!context.doc_string_found) {
                    context.doc_string_found = true;
                    try func_doc_string.append(allocator, byte);
                } else {
                    try func_doc_string.appendNTimes(allocator, 0x22, 3);

                    const func: []u8 = try allocator.dupe(u8, func_data.items);
                    const dc: []u8 = try allocator.dupe(u8, func_doc_string.items);

                    func_data.clearAndFree(allocator);
                    func_doc_string.clearAndFree(allocator);

                    const pfad: s.FuncAndDefinition = .{ .docstring = dc, .func = func };
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

        if (check_ctx.isFunc(byte, idx, context.func_found)) {
            try func_data.append(allocator, byte);
            context.func_found = true;
        }
    }

    return python_data;
}
