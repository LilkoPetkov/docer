const std = @import("std");
const t = std.testing;
const s = @import("../schemas/schemas.zig");
const pfp = @import("python_file_processor.zig");

const TestCtx = struct {
    io: std.Io,
    dir: std.Io.Dir,

    fn init() !@This() {
        const io = std.testing.io;
        const dir = try std.Io.Dir.cwd().openDir(io, "./tests/python_test", .{ .iterate = true });

        return TestCtx{ .io = io, .dir = dir };
    }

    fn destroy(self: @This()) void {
        self.dir.close(self.io);
    }
};

test "test function with docstring" {
    const ta = std.heap.page_allocator;

    const tc = try TestCtx.init();
    defer tc.destroy();

    const file: std.Io.File = try tc.dir.openFile(tc.io, "test_single_function_ds.py", .{});
    const file_size: usize = (try tc.dir.statFile(tc.io, "test_single_function_ds.py", .{})).size;

    var f: s.File = .{
        .fd = file,
        .file_size = file_size,
        .target_files = .{
            .go_target_file = null,
            .py_target_file = null,
            .zig_target_file = null,
        },
    };

    var python_data = try pfp.processPythonFile(tc.io, ta, &f);
    defer python_data.deinit(ta);
    const expected_function = "def fib(x: int) -> int";
    const expected_docstring =
        \\"""
        \\    This is a test docstring
        \\    """
    ;

    if (python_data.items[0].func != null) try t.expect(std.mem.eql(u8, python_data.items[0].func.?, expected_function));
    if (python_data.items[0].func != null) try t.expect(std.mem.eql(u8, python_data.items[0].docstring.?, expected_docstring));

    ta.free(python_data.items[0].func.?);
    ta.free(python_data.items[0].docstring.?);
}

test "test function without docstring" {
    const ta = std.heap.page_allocator;

    const tc = try TestCtx.init();
    defer tc.destroy();

    const file: std.Io.File = try tc.dir.openFile(tc.io, "test_single_function_no_ds.py", .{});
    const file_size: usize = (try tc.dir.statFile(tc.io, "test_single_function_no_ds.py", .{})).size;

    var f: s.File = .{
        .fd = file,
        .file_size = file_size,
        .target_files = .{
            .go_target_file = null,
            .py_target_file = null,
            .zig_target_file = null,
        },
    };

    var python_data = try pfp.processPythonFile(tc.io, ta, &f);
    defer python_data.deinit(ta);
    const expected_function = "def main() -> None";

    if (python_data.items[0].func != null) try t.expect(std.mem.eql(u8, python_data.items[0].func.?, expected_function));
    ta.free(python_data.items[0].func.?);
}

test "test function with docstring as last entry" {
    const ta = std.heap.page_allocator;

    const tc = try TestCtx.init();
    defer tc.destroy();

    const file: std.Io.File = try tc.dir.openFile(tc.io, "test_single_function_last_entry_ds.py", .{});
    const file_size: usize = (try tc.dir.statFile(tc.io, "test_single_function_last_entry_ds.py", .{})).size;

    var f: s.File = .{
        .fd = file,
        .file_size = file_size,
        .target_files = .{
            .go_target_file = null,
            .py_target_file = null,
            .zig_target_file = null,
        },
    };

    var python_data = try pfp.processPythonFile(tc.io, ta, &f);
    defer python_data.deinit(ta);
    const expected_function = "def main() -> None";
    const expected_docstring =
        \\"""
        \\    This is a test docstring
        \\    """
    ;

    if (python_data.items[0].func != null) try t.expect(std.mem.eql(u8, python_data.items[0].func.?, expected_function));
    if (python_data.items[0].func != null) try t.expect(std.mem.eql(u8, python_data.items[0].docstring.?, expected_docstring));

    ta.free(python_data.items[0].func.?);
    ta.free(python_data.items[0].docstring.?);
}

test "test multiple functions with docstrings" {
    const ta = std.heap.page_allocator;

    const tc = try TestCtx.init();
    defer tc.destroy();

    const file: std.Io.File = try tc.dir.openFile(tc.io, "test_multiple_functions_with_doc_strings.py", .{});
    const file_size: usize = (try tc.dir.statFile(tc.io, "test_multiple_functions_with_doc_strings.py", .{})).size;

    var f: s.File = .{
        .fd = file,
        .file_size = file_size,
        .target_files = .{
            .go_target_file = null,
            .py_target_file = null,
            .zig_target_file = null,
        },
    };

    var python_data = try pfp.processPythonFile(tc.io, ta, &f);
    defer python_data.deinit(ta);

    const expected_function01 = "def test01() -> None";
    const expected_docstring01 =
        \\"""
        \\    This is a test docstring
        \\    """
    ;
    if (python_data.items[0].func != null) try t.expect(std.mem.eql(u8, python_data.items[0].func.?, expected_function01));
    if (python_data.items[0].func != null) try t.expect(std.mem.eql(u8, python_data.items[0].docstring.?, expected_docstring01));

    const expected_function02 = "def test02() -> None";
    const expected_docstring02 =
        \\"""
        \\    This is a test docstring
        \\    """
    ;
    if (python_data.items[1].func != null) try t.expect(std.mem.eql(u8, python_data.items[1].func.?, expected_function02));
    if (python_data.items[1].func != null) try t.expect(std.mem.eql(u8, python_data.items[1].docstring.?, expected_docstring02));

    const expected_function03 = "def test03()";
    const expected_docstring03 =
        \\"""
        \\    This is a test docstring
        \\    """
    ;
    if (python_data.items[2].func != null) try t.expect(std.mem.eql(u8, python_data.items[2].func.?, expected_function03));
    if (python_data.items[2].func != null) try t.expect(std.mem.eql(u8, python_data.items[2].docstring.?, expected_docstring03));

    for (python_data.items) |item| {
        if (item.func != null) {
            ta.free(item.func.?);
        }
        if (item.docstring != null) {
            ta.free(item.docstring.?);
        }
    }
}

test "test multiple functions without docstrings" {
    const ta = std.heap.page_allocator;

    const tc = try TestCtx.init();
    defer tc.destroy();

    const file: std.Io.File = try tc.dir.openFile(tc.io, "test_multiple_functions_wihtout_docstrings.py", .{});
    const file_size: usize = (try tc.dir.statFile(tc.io, "test_multiple_functions_wihtout_docstrings.py", .{})).size;

    var f: s.File = .{
        .fd = file,
        .file_size = file_size,
        .target_files = .{
            .go_target_file = null,
            .py_target_file = null,
            .zig_target_file = null,
        },
    };

    var python_data = try pfp.processPythonFile(tc.io, ta, &f);
    defer python_data.deinit(ta);

    const expected_function01 = "def test01() -> None";
    if (python_data.items[0].func != null) try t.expect(std.mem.eql(u8, python_data.items[0].func.?, expected_function01));

    const expected_function02 = "def test02() -> None";
    if (python_data.items[1].func != null) try t.expect(std.mem.eql(u8, python_data.items[1].func.?, expected_function02));

    const expected_function03 = "def test03()";
    if (python_data.items[2].func != null) try t.expect(std.mem.eql(u8, python_data.items[2].func.?, expected_function03));

    for (python_data.items) |item| {
        if (item.func != null) {
            ta.free(item.func.?);
        }
        if (item.docstring != null) {
            ta.free(item.docstring.?);
        }
    }
}

test "test single function multiline string no docstring" {
    const ta = std.heap.page_allocator;

    const tc = try TestCtx.init();
    defer tc.destroy();

    const file: std.Io.File = try tc.dir.openFile(tc.io, "test_single_function_no_ds_ml_string.py", .{});
    const file_size: usize = (try tc.dir.statFile(tc.io, "test_single_function_no_ds_ml_string.py", .{})).size;

    var f: s.File = .{
        .fd = file,
        .file_size = file_size,
        .target_files = .{
            .go_target_file = null,
            .py_target_file = null,
            .zig_target_file = null,
        },
    };

    var python_data = try pfp.processPythonFile(tc.io, ta, &f);
    defer python_data.deinit(ta);

    const expected_function01 = "def main() -> None";
    if (python_data.items[0].func != null) try t.expect(std.mem.eql(u8, python_data.items[0].func.?, expected_function01));

    ta.free(python_data.items[0].func.?);
}
