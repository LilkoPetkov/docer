const std = @import("std");
const docer = @import("docer");
const print = std.debug.print;
const log = std.log;
const Allocator = std.mem.Allocator;

const s = @import("schemas/schemas.zig");
const report_generator = @import("report_generator/md_report_generator.zig");
const tf_manager = @import("report_generator/target_file_manager.zig");
const args = @import("args/args_processor.zig");

const pfp = @import("file_processors/python_file_processor.zig");
const gfp = @import("file_processors/go_file_processor.zig");
const zfp = @import("file_processors/zig_file_processor.zig");

const python_tests = @import("file_processors/test_python_file_processor.zig");
const go_tests = @import("file_processors/test_go_file_processor.zig");
const zig_tests = @import("file_processors/test_zig_file_processor.zig");
test {
    std.testing.refAllDecls(python_tests);
    std.testing.refAllDecls(go_tests);
    std.testing.refAllDecls(zig_tests);
}

pub fn main() !void {
    var gpa = std.heap.DebugAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const TARGET_DIRECTORY = try args.processArgs(allocator);
    defer allocator.free(TARGET_DIRECTORY);

    var dir = std.fs.cwd().openDir(TARGET_DIRECTORY, .{ .iterate = true }) catch |err| {
        return err;
    };
    defer dir.close();

    var it = try dir.walk(allocator);
    defer it.deinit();

    const dir_name: []const u8 = try std.fmt.allocPrint(allocator, "REPORT_{d}", .{std.time.timestamp()});
    var target_dir = std.fs.cwd().makeOpenPath(dir_name, .{}) catch |err| {
        log.err("Report directory could not be created: {}", .{err});
        return err;
    };
    defer target_dir.close();
    allocator.free(dir_name);

    const target_files: s.TargetFiles = .{
        .go_target_file = try target_dir.createFile("go_report.md", .{}),
        .py_target_file = try target_dir.createFile("python_report.md", .{}),
        .zig_target_file = try target_dir.createFile("zig_report.md", .{}),
    };
    defer target_files.go_target_file.?.close();
    defer target_files.py_target_file.?.close();
    defer target_files.zig_target_file.?.close();

    try report_generator.writeReportHeader(.go, target_files.go_target_file.?);
    try report_generator.writeReportHeader(.zig, target_files.zig_target_file.?);
    try report_generator.writeReportHeader(.python, target_files.py_target_file.?);

    var python_target_file_created: bool = false;
    var go_target_file_created: bool = false;
    var zig_target_file_created: bool = false;

    while (try it.next()) |file| {
        const file_name: []const u8 = file.basename;
        const file_size: u64 = (try dir.statFile(file.path)).size;
        const fd: std.fs.File = try dir.openFile(file.path, .{});

        var f: s.File = .{
            .fd = fd,
            .file_size = file_size,
            .target_files = target_files,
        };

        if (std.ascii.endsWithIgnoreCase(file_name, ".py")) {
            python_target_file_created = true;

            var python_data = try pfp.processPythonFile(allocator, &f);

            for (python_data.items) |item| {
                try report_generator.generateReport(allocator, item, target_files, .python);

                if (item.func != null) allocator.free(item.func.?);
                if (item.docstring != null) allocator.free(item.docstring.?);
            }

            python_data.deinit(allocator);
        } else if (std.ascii.endsWithIgnoreCase(file_name, ".go")) {
            go_target_file_created = true;

            var go_data = try gfp.processGoFile(allocator, &f);

            for (go_data.items) |item| {
                try report_generator.generateReport(allocator, item, target_files, .go);

                if (item.func != null) allocator.free(item.func.?);
                if (item.docstring != null) allocator.free(item.docstring.?);
            }

            go_data.deinit(allocator);
        } else if (std.ascii.endsWithIgnoreCase(file_name, ".zig")) {
            zig_target_file_created = true;

            var zig_data = try zfp.processZigFile(allocator, &f);

            for (zig_data.items) |item| {
                try report_generator.generateReport(allocator, item, target_files, .zig);

                if (item.func != null) allocator.free(item.func.?);
                if (item.docstring != null) allocator.free(item.docstring.?);
            }

            zig_data.deinit(allocator);
        }

        fd.close();
    }

    if (!python_target_file_created) {
        try tf_manager.deleteUnusedTargetFiles(target_dir, "python_report.md");
    } else if (!go_target_file_created) {
        try tf_manager.deleteUnusedTargetFiles(target_dir, "go_report.md");
    } else if (!zig_target_file_created) {
        try tf_manager.deleteUnusedTargetFiles(target_dir, "zig_report.md");
    }
}
