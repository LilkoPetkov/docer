const std = @import("std");
const docer = @import("docer");
const print = std.debug.print;
const Allocator = std.mem.Allocator;

const s = @import("schemas/schemas.zig");
const pfp = @import("file_processors/python_file_processor.zig");

const t = @import("file_processors/test_python_file_processor.zig");
test {
    std.testing.refAllDecls(t);
}

const TARGET_DIRECTORY: []const u8 = "/home/lpetkov/Tasks/zig_tasks/docer/python_test";

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
            var f: s.File = .{
                .fd = fd,
                .file_size = file_size,
                .target_file = target_file,
            };

            var python_data = try pfp.processFile(allocator, &f);
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
        } else if (std.ascii.endsWithIgnoreCase(file_name, ".go")) {
            print("It is a go file\n", .{});
        } else if (std.ascii.endsWithIgnoreCase(file_name, ".zig")) {
            print("It is a zig file\n", .{});
        }

        fd.close();
    }
}
