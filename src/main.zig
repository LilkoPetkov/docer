const std = @import("std");
const docer = @import("docer");
const print = std.debug.print;
const re = @import("mvzr");
const Allocator = std.mem.Allocator;

const TARGET_DIRECTORY: []const u8 = "/home/lpetkov/Tasks/zig_tasks/docer/python_app";

const FileTypes = enum {
    py,
    go,
    zig,
};

const File = struct {
    file_type: FileTypes, // py / go / zig
    fd: std.fs.File,
    target_file: std.fs.File,
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
            try processFile(allocator, &f);
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

fn processFile(allocator: Allocator, file: *File) !void {
    const file_content_buf = try allocator.alloc(u8, file.file_size);
    defer allocator.free(file_content_buf);
    _ = try file.fd.read(file_content_buf);

    var python_data: std.ArrayList(PythonFuncAndDoc) = try .initCapacity(allocator, 1024);
    defer python_data.deinit(allocator);
    var func_data: std.ArrayList(u8) = try .initCapacity(allocator, 32);
    defer func_data.deinit(allocator);
    var func_doc_string: std.ArrayList(u8) = try .initCapacity(allocator, 256);
    defer func_doc_string.deinit(allocator);

    var func_found: bool = false;
    var closing_func_bracket_found: bool = false;
    var func_recorded: bool = false;
    var doc_string_found: bool = false;

    for (file_content_buf, 0..) |byte, idx| {
        if (func_recorded) {
            if (byte != '"' and
                byte != ' ' and
                byte != 0x0A and
                !doc_string_found)
            {
                func_recorded = false;
            } else if (byte == '"' and
                idx + 2 < file_content_buf.len and
                file_content_buf[idx + 1] == '"' and
                file_content_buf[idx + 2] == '"')
            {
                if (!doc_string_found) {
                    doc_string_found = true;
                    try func_doc_string.append(allocator, byte);
                } else {
                    try func_doc_string.appendNTimes(allocator, 0x22, 3);

                    const func: []u8 = try allocator.dupe(u8, func_data.items);
                    const dc: []u8 = try allocator.dupe(u8, func_doc_string.items);

                    func_data.clearAndFree(allocator);
                    func_doc_string.clearAndFree(allocator);

                    const pfad: PythonFuncAndDoc = .{ .docstring = dc, .func = func };
                    try python_data.append(allocator, pfad);

                    doc_string_found = false;
                }
            } else if (doc_string_found) {
                try func_doc_string.append(allocator, byte);
            }

            continue;
        }

        if (func_found and byte == ')') {
            try func_data.append(allocator, byte);
            closing_func_bracket_found = true;
        } else if (func_found and !closing_func_bracket_found) {
            try func_data.append(allocator, byte);
        } else if (func_found and closing_func_bracket_found) {
            if (byte != ':') try func_data.append(allocator, byte) else {
                func_found = false;
                closing_func_bracket_found = false;
                func_recorded = true;
            }
        }

        if (byte == 'd' and
            idx + 3 < file_content_buf.len and
            file_content_buf[idx + 1] == 'e' and
            file_content_buf[idx + 2] == 'f' and
            file_content_buf[idx + 3] == ' ' and
            !func_found)
        {
            try func_data.append(allocator, byte);
            func_found = true;
        }
    }

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
}
