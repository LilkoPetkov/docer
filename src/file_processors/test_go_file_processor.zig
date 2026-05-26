const std = @import("std");
const t = std.testing;
const s = @import("../schemas/schemas.zig");
const gfp = @import("go_file_processor.zig");

test "test function without function definition" {
    const ta = std.heap.page_allocator;

    const file = try std.fs.cwd().openFile("tests/go_test/test_single_func_no_fd.go", .{});
    const file_size: usize = (try file.stat()).size;

    var f: s.File = .{
        .fd = file,
        .file_size = file_size,
        .target_file = null,
    };

    var go_data = try gfp.processGoFile(ta, &f);
    defer go_data.deinit(ta);
    const expected_function = "func main(x, x, x int)";

    if (go_data.items[0].func != null) try t.expect(std.mem.eql(u8, go_data.items[0].func.?, expected_function));
    if (go_data.items[0].func != null) ta.free(go_data.items[0].func.?);
}

test "test function with function definition" {
    const ta = std.heap.page_allocator;

    const file = try std.fs.cwd().openFile("tests/go_test/test_single_func_fd.go", .{});
    const file_size: usize = (try file.stat()).size;

    var f: s.File = .{
        .fd = file,
        .file_size = file_size,
        .target_file = null,
    };

    var go_data = try gfp.processGoFile(ta, &f);
    defer go_data.deinit(ta);
    const expected_function = "func main(x, y int) string";
    const expected_fd = "// Main entrypoint // \\\\ to the program\n";

    if (go_data.items[0].func != null) try t.expect(std.mem.eql(u8, go_data.items[0].func.?, expected_function));
    if (go_data.items[0].func != null) ta.free(go_data.items[0].func.?);

    if (go_data.items[0].func != null) try t.expect(std.mem.eql(u8, go_data.items[0].docstring.?, expected_fd));
    if (go_data.items[0].func != null) ta.free(go_data.items[0].docstring.?);
}

test "test functions without function definition" {
    const ta = std.heap.page_allocator;

    const file = try std.fs.cwd().openFile("tests/go_test/test_multiple_funcs_no_fd.go", .{});
    const file_size: usize = (try file.stat()).size;

    var f: s.File = .{
        .fd = file,
        .file_size = file_size,
        .target_file = null,
    };

    var go_data = try gfp.processGoFile(ta, &f);
    defer go_data.deinit(ta);

    const first_expected_function = "func genericFunc[T any](x, y T) T";
    const second_expected_function = "func (P testStruct) withObject(x int) string";
    const third_expected_function = "func returnsError(x int) (bool, error)";

    if (go_data.items[0].func != null) try t.expect(std.mem.eql(u8, go_data.items[0].func.?, first_expected_function));
    if (go_data.items[0].func != null) ta.free(go_data.items[0].func.?);

    if (go_data.items[1].func != null) try t.expect(std.mem.eql(u8, go_data.items[1].func.?, second_expected_function));
    if (go_data.items[1].func != null) ta.free(go_data.items[1].func.?);

    if (go_data.items[2].func != null) try t.expect(std.mem.eql(u8, go_data.items[2].func.?, third_expected_function));
    if (go_data.items[2].func != null) ta.free(go_data.items[2].func.?);
}

test "test functions with function definition" {
    const ta = std.heap.page_allocator;

    const file = try std.fs.cwd().openFile("tests/go_test/test_multiple_funcs_fd.go", .{});
    const file_size: usize = (try file.stat()).size;

    var f: s.File = .{
        .fd = file,
        .file_size = file_size,
        .target_file = null,
    };

    var go_data = try gfp.processGoFile(ta, &f);
    defer go_data.deinit(ta);

    const first_expected_function = "func main()";
    const first_expected_fd = "// Main entrypoint to the application\n";

    const second_expected_function = "func (t teststruct) t1(x, y int) interface{}";
    const second_expected_fd = "// Test function with an object\n";

    const third_expected_function = "func testFunc(x, y int)";
    const third_expected_fd =
        \\// Test function, not useful in any way
        \\//
        \\// Args:
        \\//
        \\// x: the X value
        \\// y: the Y value
        \\//
        \\// Returns:
        \\//
        \\// nill/void
    ++ "\n";

    if (go_data.items[0].func != null) try t.expect(std.mem.eql(u8, go_data.items[0].func.?, first_expected_function));
    if (go_data.items[0].func != null) try t.expect(std.mem.eql(u8, go_data.items[0].docstring.?, first_expected_fd));
    if (go_data.items[0].func != null) ta.free(go_data.items[0].docstring.?);
    if (go_data.items[0].func != null) ta.free(go_data.items[0].func.?);

    if (go_data.items[1].func != null) try t.expect(std.mem.eql(u8, go_data.items[1].func.?, second_expected_function));
    if (go_data.items[1].func != null) try t.expect(std.mem.eql(u8, go_data.items[1].docstring.?, second_expected_fd));
    if (go_data.items[1].func != null) ta.free(go_data.items[1].docstring.?);
    if (go_data.items[1].func != null) ta.free(go_data.items[1].func.?);

    if (go_data.items[2].func != null) try t.expect(std.mem.eql(u8, go_data.items[2].func.?, third_expected_function));
    if (go_data.items[2].func != null) try t.expect(std.mem.eql(u8, go_data.items[2].docstring.?, third_expected_fd));

    if (go_data.items[2].func != null) ta.free(go_data.items[2].docstring.?);
    if (go_data.items[2].func != null) ta.free(go_data.items[2].func.?);
}
