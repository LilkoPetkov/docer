const std = @import("std");
const docer = @import("docer");
const print = std.debug.print;
const Allocator = std.mem.Allocator;

const TARGET_DIRECTORY: []const u8 = "/home/lpetkov/Tasks/zig_tasks/docer/python_test";

const FileTypes = enum {
    py,
    go,
    zig,
};

const PythonObjectContext = struct {
    func_found: bool = false,
    closing_func_bracket_found: bool = false,
    func_recorded: bool = false,
    doc_string_found: bool = false,
};

const File = struct {
    file_type: FileTypes, // py / go / zig
    fd: std.fs.File,
    target_file: ?std.fs.File,
    file_size: u64,
};

const PythonFuncAndDoc = struct {
    func: ?[]u8,
    docstring: ?[]u8,
};

const PythonData = struct {
    data: std.ArrayList(PythonFuncAndDoc),
};

const SPAWN_CONFIG: std.Thread.SpawnConfig = .{
    .stack_size = 1024 * 16,
};

pub fn main() !void {
    var gpa = std.heap.DebugAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var dir = try std.fs.cwd().openDir(TARGET_DIRECTORY, .{ .iterate = true });
    defer dir.close();

    var it = try dir.walk(allocator);
    defer it.deinit();

    const target_file: std.fs.File = try dir.createFile("REPORT.md", .{});
    defer target_file.close();

    while (try it.next()) |file| {
        const file_name: []const u8 = file.basename;
        const file_size: u64 = (try dir.statFile(file.path)).size;
        const fd: std.fs.File = try dir.openFile(file.path, .{});

        if (std.ascii.endsWithIgnoreCase(file_name, ".py")) {
            var f: File = .{
                .file_type = .py,
                .fd = fd,
                .file_size = file_size,
                .target_file = target_file,
            };

            var python_data = try processFile(allocator, &f);
            for (python_data.items) |item| {
                if (item.func != null) {
                    print("{s}\n", .{item.func.?});
                    allocator.free(item.func.?);
                }
                if (item.docstring != null) {
                    print("{s}\n", .{item.docstring.?});
                    allocator.free(item.docstring.?);
                }
            }

            python_data.deinit(allocator);
            // const thread = try std.Thread.spawn(SPAWN_CONFIG, processFile, .{ allocator, &f });
            // thread.join();
        } else if (std.ascii.endsWithIgnoreCase(file_name, ".go")) {
            print("It is a go file\n", .{});
        } else if (std.ascii.endsWithIgnoreCase(file_name, ".zig")) {
            print("It is a zig file\n", .{});
        }

        fd.close();
    }
}

fn processFile(allocator: Allocator, file: *File) !std.ArrayList(PythonFuncAndDoc) {
    const file_content_buf = try allocator.alloc(u8, file.file_size);
    defer allocator.free(file_content_buf);
    _ = try file.fd.read(file_content_buf);

    var python_data: std.ArrayList(PythonFuncAndDoc) = try .initCapacity(allocator, 1024);
    var func_data: std.ArrayList(u8) = try .initCapacity(allocator, 32);
    defer func_data.deinit(allocator);
    var func_doc_string: std.ArrayList(u8) = try .initCapacity(allocator, 256);
    defer func_doc_string.deinit(allocator);

    var context: PythonObjectContext = .{};

    for (file_content_buf, 0..) |byte, idx| {
        if (context.func_recorded) {
            if (byte != '"' and
                byte != ' ' and
                byte != 0x0A and
                !context.doc_string_found)
            {
                const func: []u8 = try allocator.dupe(u8, func_data.items);
                func_data.clearAndFree(allocator);
                const pfad: PythonFuncAndDoc = .{ .docstring = null, .func = func };
                try python_data.append(allocator, pfad);

                context.func_recorded = false;
            } else if (byte == '"' and
                idx + 2 < file_content_buf.len and
                file_content_buf[idx + 1] == '"' and
                file_content_buf[idx + 2] == '"')
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

                    const pfad: PythonFuncAndDoc = .{ .docstring = dc, .func = func };
                    try python_data.append(allocator, pfad);

                    context.doc_string_found = false;
                    context.func_recorded = false;
                }
            } else if (context.doc_string_found) {
                try func_doc_string.append(allocator, byte);
            }

            continue;
        }

        if (context.func_found and byte == ')') {
            try func_data.append(allocator, byte);
            context.closing_func_bracket_found = true;
        } else if (context.func_found and !context.closing_func_bracket_found) {
            try func_data.append(allocator, byte);
        } else if (context.func_found and context.closing_func_bracket_found) {
            if (byte != ':') try func_data.append(allocator, byte) else {
                context.func_found = false;
                context.closing_func_bracket_found = false;
                context.func_recorded = true;
            }
        }

        if (byte == 'd' and
            idx + 3 < file_content_buf.len and
            file_content_buf[idx + 1] == 'e' and
            file_content_buf[idx + 2] == 'f' and
            file_content_buf[idx + 3] == ' ' and
            !context.func_found)
        {
            try func_data.append(allocator, byte);
            context.func_found = true;
        }
    }

    return python_data;
}

const t = std.testing;
// Tests
test "test function with docstring" {
    const ta = std.heap.page_allocator;

    const file = try std.fs.cwd().openFile("python_test/test_single_function_ds.py", .{});
    const file_size: usize = (try file.stat()).size;

    var f: File = .{
        .fd = file,
        .file_size = file_size,
        .file_type = .py,
        .target_file = null,
    };

    var python_data = try processFile(ta, &f);
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

    const file = try std.fs.cwd().openFile("python_test/test_single_function_no_ds.py", .{});
    const file_size: usize = (try file.stat()).size;

    var f: File = .{
        .fd = file,
        .file_size = file_size,
        .file_type = .py,
        .target_file = null,
    };

    var python_data = try processFile(ta, &f);
    defer python_data.deinit(ta);
    const expected_function = "def main() -> None";

    if (python_data.items[0].func != null) try t.expect(std.mem.eql(u8, python_data.items[0].func.?, expected_function));
    ta.free(python_data.items[0].func.?);
}

test "test function with docstring as last entry" {
    const ta = std.heap.page_allocator;

    const file = try std.fs.cwd().openFile("python_test/test_single_function_last_entry_ds.py", .{});
    const file_size: usize = (try file.stat()).size;

    var f: File = .{
        .fd = file,
        .file_size = file_size,
        .file_type = .py,
        .target_file = null,
    };

    var python_data = try processFile(ta, &f);
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

    const file = try std.fs.cwd().openFile("python_test/test_multiple_functions_with_doc_strings.py", .{});
    const file_size: usize = (try file.stat()).size;

    var f: File = .{
        .fd = file,
        .file_size = file_size,
        .file_type = .py,
        .target_file = null,
    };

    var python_data = try processFile(ta, &f);
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

    const file = try std.fs.cwd().openFile("python_test/test_multiple_functions_wihtout_docstrings.py", .{});
    const file_size: usize = (try file.stat()).size;

    var f: File = .{
        .fd = file,
        .file_size = file_size,
        .file_type = .py,
        .target_file = null,
    };

    var python_data = try processFile(ta, &f);
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
