const std = @import("std");
const print = std.debug.print;
const Allocator = std.mem.Allocator;
const startsWith = std.ascii.startsWithIgnoreCase;
const endsWith = std.ascii.endsWithIgnoreCase;
const t = std.testing;

const s = @import("../schemas/schemas.zig");

pub const zigByteChecks = struct {
    file_content_buf: *[]u8,

    fn isComment(self: @This(), byte: u8, idx: usize) bool {
        return byte == 0x2F and
            idx + 2 < self.file_content_buf.*.len and
            self.file_content_buf.*[idx + 1] == 0x2F and
            self.file_content_buf.*[idx + 2] == 0x2F;
    }

    fn nextBytesComment(self: @This(), idx: usize) bool {
        return idx + 3 < self.file_content_buf.*.len and
            self.file_content_buf.*[idx + 1] == 0x2F and
            self.file_content_buf.*[idx + 2] == 0x2F and
            self.file_content_buf.*[idx + 3] == 0x2F;
    }

    fn isNextBytesFunc(self: @This(), idx: usize) bool {
        return (idx + 2 < self.file_content_buf.*.len and
            self.file_content_buf.*[idx + 1] == 0x66 and
            self.file_content_buf.*[idx + 2] == 0x6E) or
            (idx + 6 < self.file_content_buf.*.len and
                self.file_content_buf.*[idx + 1] == 0x70 and
                self.file_content_buf.*[idx + 2] == 0x75 and
                self.file_content_buf.*[idx + 3] == 0x62 and
                self.file_content_buf.*[idx + 4] == 0x20 and
                self.file_content_buf.*[idx + 5] == 0x66 and
                self.file_content_buf.*[idx + 6] == 0x6E);
    }

    fn isCurrentBytesFunc(self: @This(), byte: u8, idx: usize) bool {
        return (byte == 0x66 and
            idx + 2 < self.file_content_buf.*.len and
            self.file_content_buf.*[idx + 1] == 0x6E and
            self.file_content_buf.*[idx + 2] == 0x20) or
            (byte == 0x70 and
                idx + 5 < self.file_content_buf.*.len and
                self.file_content_buf.*[idx + 1] == 0x75 and
                self.file_content_buf.*[idx + 2] == 0x62 and
                self.file_content_buf.*[idx + 3] == 0x20 and
                self.file_content_buf.*[idx + 4] == 0x66 and
                self.file_content_buf.*[idx + 5] == 0x6E);
    }

    fn isFuncEnd(self: @This(), byte: u8, idx: usize) bool {
        return byte == 0x7B and
            idx + 1 < self.file_content_buf.*.len and
            (self.file_content_buf.*[idx + 1] == 0x0A or
                (self.file_content_buf.*[idx + 1] == 0x7D and
                    idx + 2 < self.file_content_buf.*.len and
                    self.file_content_buf.*[idx + 2] == 0x0A));
    }
};

pub fn processZigFile(allocator: Allocator, file: *s.File) !std.ArrayList(s.FuncAndDefinition) {
    var file_content_buf = try allocator.alloc(u8, file.file_size);
    defer allocator.free(file_content_buf);
    _ = try file.fd.read(file_content_buf);

    const check_ctx: zigByteChecks = .{ .file_content_buf = &file_content_buf };

    var current_func: std.ArrayList(u8) = try .initCapacity(allocator, 64);
    defer current_func.deinit(allocator);
    var current_fd: std.ArrayList(u8) = try .initCapacity(allocator, 128);
    defer current_fd.deinit(allocator);

    var data: std.ArrayList(s.FuncAndDefinition) = try .initCapacity(allocator, 1024);

    var fd_found: bool = false;
    var comment_func_found: bool = false;
    var func_found: bool = false;

    for (file_content_buf, 0..) |byte, idx| {
        if (check_ctx.isComment(byte, idx) and !fd_found) {
            fd_found = true;
            try current_fd.append(allocator, byte);
        } else if (fd_found) {
            if (byte == 0x0A) {
                if (!check_ctx.nextBytesComment(idx)) {
                    if (check_ctx.isNextBytesFunc(idx)) {
                        fd_found = false;
                        comment_func_found = true;
                    } else {
                        current_fd.clearAndFree(allocator);
                        continue;
                    }
                }
            }

            try current_fd.append(allocator, byte);
        } else if (comment_func_found or check_ctx.isCurrentBytesFunc(byte, idx)) {
            try current_func.append(allocator, byte);
            comment_func_found = false;
            func_found = true;
        } else if (func_found) {
            if (check_ctx.isFuncEnd(byte, idx)) {
                const stripped_val = std.mem.trimEnd(u8, current_func.items, &[1]u8{' '});
                func_found = false;

                const fd = try allocator.dupe(u8, current_fd.items);
                current_fd.clearAndFree(allocator);

                const func = try allocator.dupe(u8, stripped_val);
                current_func.clearAndFree(allocator);

                const zig_st: s.FuncAndDefinition = .{ .docstring = fd, .func = func };
                try data.append(allocator, zig_st);
            } else try current_func.append(allocator, byte);
        }
    }

    return data;
}
