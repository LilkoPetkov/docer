const std = @import("std");
const print = std.debug.print;
const Allocator = std.mem.Allocator;
const startsWith = std.ascii.startsWithIgnoreCase;
const endsWith = std.ascii.endsWithIgnoreCase;
const t = std.testing;

const s = @import("../schemas/schemas.zig");

fn isComment(byte: u8, idx: usize, file_content_buf: *[]u8) bool {
    return byte == 0x2F and
        idx + 1 < file_content_buf.*.len and
        file_content_buf.*[idx + 1] == 0x2F;
}

fn nextBytesComment(idx: usize, file_content_buf: *[]u8) bool {
    return idx + 2 < file_content_buf.*.len and
        file_content_buf.*[idx + 1] == 0x2F and
        file_content_buf.*[idx + 2] == 0x2F;
}

fn nextBytesFunc(idx: usize, file_content_buf: *[]u8) bool {
    return idx + 5 < file_content_buf.*.len and
        file_content_buf.*[idx + 1] == 0x66 and
        file_content_buf.*[idx + 2] == 0x75 and
        file_content_buf.*[idx + 3] == 0x6E and
        file_content_buf.*[idx + 4] == 0x63 and
        file_content_buf.*[idx + 5] == 0x20;
}

fn currentBytesFunc(byte: u8, idx: usize, file_content_buf: *[]u8) bool {
    return byte == 0x66 and
        idx + 4 < file_content_buf.*.len and
        file_content_buf.*[idx + 1] == 0x75 and
        file_content_buf.*[idx + 2] == 0x6E and
        file_content_buf.*[idx + 3] == 0x63 and
        file_content_buf.*[idx + 4] == 0x20;
}

fn isFuncEnd(byte: u8, idx: usize, file_content_buf: *[]u8) bool {
    return byte == 0x7B and
        idx + 1 < file_content_buf.*.len and
        (file_content_buf.*[idx + 1] == 0x0A or
            (file_content_buf.*[idx + 1] == 0x7D and
                idx + 2 < file_content_buf.*.len and
                file_content_buf.*[idx + 2] == 0x0A));
}

pub fn processGoFile(allocator: Allocator, file: *s.File) !std.ArrayList(s.GoFuncAndDefinition) {
    var file_content_buf = try allocator.alloc(u8, file.file_size);
    defer allocator.free(file_content_buf);
    _ = try file.fd.read(file_content_buf);

    var current_func: std.ArrayList(u8) = try .initCapacity(allocator, 64);
    defer current_func.deinit(allocator);
    var current_fd: std.ArrayList(u8) = try .initCapacity(allocator, 128);
    defer current_fd.deinit(allocator);

    var data: std.ArrayList(s.GoFuncAndDefinition) = try .initCapacity(allocator, 1024);

    var ctx: s.GoObjectContext = .{};

    for (file_content_buf, 0..) |byte, idx| {
        if (isComment(byte, idx, &file_content_buf)) {
            try current_fd.append(allocator, byte);
            ctx.comment_or_fd_found = true;
        } else if (ctx.comment_or_fd_found) {
            try current_fd.append(allocator, byte);

            if (byte == 0x0A) {
                if (nextBytesComment(idx, &file_content_buf)) {
                    continue;
                } else if (nextBytesFunc(idx, &file_content_buf)) {
                    ctx.comment_func_found = true;
                    ctx.comment_or_fd_found = false;
                } else {
                    current_fd.clearAndFree(allocator);
                    ctx.comment_or_fd_found = false;
                }
            }
        } else if (ctx.comment_func_found or
            currentBytesFunc(byte, idx, &file_content_buf))
        {
            try current_func.append(allocator, byte);
            ctx.comment_func_found = false;
            ctx.func_found = true;
        } else if (ctx.func_found) {
            if (isFuncEnd(byte, idx, &file_content_buf)) {
                try current_func.append(allocator, '\n');

                const stripped_val = std.mem.trimEnd(u8, current_func.items, &[2]u8{ '\n', ' ' });
                const func_copy = try allocator.dupe(u8, stripped_val);

                current_func.clearAndFree(allocator);

                var fd_copy: ?[]u8 = null;
                if (current_fd.items.len > 0) {
                    fd_copy = try allocator.dupe(u8, current_fd.items);
                    current_fd.clearAndFree(allocator);
                }

                ctx.func_found = false;
                ctx.comment_func_found = false;

                const go_file: s.GoFuncAndDefinition = .{
                    .func = func_copy,
                    .docstring = if (fd_copy != null) fd_copy else null,
                };
                try data.append(allocator, go_file);
                continue;
            }

            try current_func.append(allocator, byte);
        }
    }

    return data;
}
