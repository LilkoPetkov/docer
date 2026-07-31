const std = @import("std");
const print = std.debug.print;
const Allocator = std.mem.Allocator;
const startsWith = std.ascii.startsWithIgnoreCase;
const endsWith = std.ascii.endsWithIgnoreCase;
const t = std.testing;

const report_generator = @import("../report_generator/md_report_generator.zig");
const s = @import("../schemas/schemas.zig");

pub const goByteChecks = struct {
    file_content_buf: *[]u8,

    fn isComment(self: @This(), byte: u8, idx: usize) bool {
        return byte == 0x2F and
            idx + 1 < self.file_content_buf.*.len and
            self.file_content_buf.*[idx + 1] == 0x2F;
    }

    fn nextBytesComment(self: @This(), idx: usize) bool {
        return idx + 2 < self.file_content_buf.*.len and
            self.file_content_buf.*[idx + 1] == 0x2F and
            self.file_content_buf.*[idx + 2] == 0x2F;
    }

    fn isNextBytesFunc(self: @This(), idx: usize) bool {
        return idx + 5 < self.file_content_buf.*.len and
            self.file_content_buf.*[idx + 1] == 0x66 and
            self.file_content_buf.*[idx + 2] == 0x75 and
            self.file_content_buf.*[idx + 3] == 0x6E and
            self.file_content_buf.*[idx + 4] == 0x63 and
            self.file_content_buf.*[idx + 5] == 0x20;
    }

    fn isCurrentBytesFunc(self: @This(), byte: u8, idx: usize) bool {
        return byte == 0x66 and
            idx + 4 < self.file_content_buf.*.len and
            self.file_content_buf.*[idx + 1] == 0x75 and
            self.file_content_buf.*[idx + 2] == 0x6E and
            self.file_content_buf.*[idx + 3] == 0x63 and
            self.file_content_buf.*[idx + 4] == 0x20;
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

pub fn processGoFile(allocator: Allocator, file: *s.File, target_files: s.TargetFiles) !void {
    var file_content_buf = try allocator.alloc(u8, file.file_size);
    defer allocator.free(file_content_buf);
    _ = try file.fd.read(file_content_buf);

    var ctx: s.GoObjectContext = .{};
    const check_ctx: goByteChecks = .{ .file_content_buf = &file_content_buf };

    var current_func: std.ArrayList(u8) = try .initCapacity(allocator, 64);
    defer current_func.deinit(allocator);
    var current_fd: std.ArrayList(u8) = try .initCapacity(allocator, 128);
    defer current_fd.deinit(allocator);

    for (file_content_buf, 0..) |byte, idx| {
        if (check_ctx.isComment(byte, idx)) {
            try current_fd.append(allocator, byte);
            ctx.comment_or_fd_found = true;
        } else if (ctx.comment_or_fd_found) {
            try current_fd.append(allocator, byte);

            if (byte == 0x0A) {
                if (check_ctx.nextBytesComment(idx)) {
                    continue;
                } else if (check_ctx.isNextBytesFunc(idx)) {
                    ctx.comment_func_found = true;
                    ctx.comment_or_fd_found = false;
                } else {
                    current_fd.clearAndFree(allocator);
                    ctx.comment_or_fd_found = false;
                }
            }
        } else if (ctx.comment_func_found or
            check_ctx.isCurrentBytesFunc(byte, idx))
        {
            try current_func.append(allocator, byte);
            ctx.comment_func_found = false;
            ctx.func_found = true;
        } else if (ctx.func_found) {
            if (check_ctx.isFuncEnd(byte, idx)) {
                const stripped_val = std.mem.trimEnd(u8, current_func.items, &[1]u8{' '});

                ctx.func_found = false;
                ctx.comment_func_found = false;

                const go_data: s.FuncAndDefinition = .{
                    .func = stripped_val,
                    .docstring = if (current_fd.items.len > 0) current_fd.items else null,
                };
                try report_generator.generateReport(allocator, go_data, target_files, .go);

                current_fd.clearAndFree(allocator);
                current_func.clearAndFree(allocator);
                continue;
            }

            try current_func.append(allocator, byte);
        }
    }
}
