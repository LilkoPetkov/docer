const std = @import("std");
const t = std.testing;
const s = @import("../schemas/schemas.zig");
const zfp = @import("zig_file_processor.zig");

test "test function without function definition" {
    const ta = std.heap.page_allocator;

    const file = try std.fs.cwd().openFile("tests/zig_tests/test_single_func_no_fd.zig", .{});
    const file_size: usize = (try file.stat()).size;

    var f: s.File = .{
        .fd = file,
        .file_size = file_size,
        .target_file = null,
    };

    var zig_data = try zfp.processZigFile(ta, &f);
    defer zig_data.deinit(ta);
    const expected_function = "pub fn main() !void";

    if (zig_data.items[0].func != null) try t.expect(std.mem.eql(u8, zig_data.items[0].func.?, expected_function));
    if (zig_data.items[0].func != null) ta.free(zig_data.items[0].func.?);
}

test "test functions without function definition" {
    const ta = std.heap.page_allocator;

    const file = try std.fs.cwd().openFile("tests/zig_tests/test_multiple_funcs_no_fd.zig", .{});
    const file_size: usize = (try file.stat()).size;

    var f: s.File = .{
        .fd = file,
        .file_size = file_size,
        .target_file = null,
    };

    var zig_data = try zfp.processZigFile(ta, &f);
    defer zig_data.deinit(ta);
    const first_expected_function = "pub fn main() !void";

    if (zig_data.items[0].func != null) try t.expect(std.mem.eql(u8, zig_data.items[0].func.?, first_expected_function));
    if (zig_data.items[0].func != null) ta.free(zig_data.items[0].func.?);

    const second_expected_function =
        \\fn testFunc(
        \\    x: u8,
        \\    y: u8,
        \\    z: []const u8,
        \\) !std.ArrayList(u8)
    ;
    if (zig_data.items[1].func != null) try t.expect(std.mem.eql(u8, zig_data.items[1].func.?, second_expected_function));
    if (zig_data.items[1].func != null) ta.free(zig_data.items[1].func.?);

    const third_expected_function = "fn testFuncWithStruct(x: u8, y: u8, test_struct: struct {}) !void";
    if (zig_data.items[2].func != null) try t.expect(std.mem.eql(u8, zig_data.items[2].func.?, third_expected_function));
    if (zig_data.items[2].func != null) ta.free(zig_data.items[2].func.?);
}
