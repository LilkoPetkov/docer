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

pub fn main(init: std.process.Init) !void {
    var gpa = std.heap.DebugAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var arg_iterator = init.minimal.args.iterate();
    const io = init.io;

    const TARGET_DIRECTORY = try args.processArgs(allocator, &arg_iterator);
    defer allocator.free(TARGET_DIRECTORY);
    arg_iterator.deinit();

    var dir = try std.Io.Dir.cwd().openDir(io, ".", .{ .iterate = true });
    defer dir.close(io);

    var it = try dir.walk(allocator);
    defer it.deinit();

    const dir_name: []const u8 = try std.fmt.allocPrint(allocator, "REPORT_{d}.md", .{std.time.epoch.unix});
    var target_dir = dir.createDirPathOpen(io, dir_name, .{}) catch |err| {
        log.err("Report directory could not be created: {}", .{err});
        return err;
    };
    defer target_dir.close(io);
    allocator.free(dir_name);

    const target_files: s.TargetFiles = .{
        .go_target_file = try target_dir.createFile(io, "go_report.md", .{}),
        .py_target_file = try target_dir.createFile(io, "python_report.md", .{}),
        .zig_target_file = try target_dir.createFile(io, "zig_report.md", .{}),
    };
    defer target_files.go_target_file.?.close(io);
    defer target_files.py_target_file.?.close(io);
    defer target_files.zig_target_file.?.close(io);

    try report_generator.writeReportHeader(io, .go, target_files.go_target_file.?);
    try report_generator.writeReportHeader(io, .zig, target_files.zig_target_file.?);
    try report_generator.writeReportHeader(io, .python, target_files.py_target_file.?);

    var python_target_file_created: bool = false;
    var go_target_file_created: bool = false;
    var zig_target_file_created: bool = false;

    while (try it.next(io)) |file| {
        const file_name: []const u8 = file.basename;
        const file_size: u64 = (try dir.statFile(io, file.path, .{})).size;
        const fd: std.Io.File = try dir.openFile(io, file.path, .{});

        var f: s.File = .{
            .fd = fd,
            .file_size = file_size,
            .target_files = target_files,
        };

        if (std.ascii.endsWithIgnoreCase(file_name, ".py")) {
            python_target_file_created = true;

            var python_data = try pfp.processPythonFile(io, allocator, &f);

            for (python_data.items) |item| {
                try report_generator.generateReport(io, item, target_files, .python);

                if (item.func != null) allocator.free(item.func.?);
                if (item.docstring != null) allocator.free(item.docstring.?);
            }

            python_data.deinit(allocator);
        } else if (std.ascii.endsWithIgnoreCase(file_name, ".go")) {
            go_target_file_created = true;

            var go_data = try gfp.processGoFile(io, allocator, &f);

            for (go_data.items) |item| {
                try report_generator.generateReport(io, item, target_files, .go);

                if (item.func != null) allocator.free(item.func.?);
                if (item.docstring != null) allocator.free(item.docstring.?);
            }

            go_data.deinit(allocator);
        } else if (std.ascii.endsWithIgnoreCase(file_name, ".zig")) {
            zig_target_file_created = true;

            var zig_data = try zfp.processZigFile(io, allocator, &f);

            for (zig_data.items) |item| {
                try report_generator.generateReport(io, item, target_files, .zig);

                if (item.func != null) allocator.free(item.func.?);
                if (item.docstring != null) allocator.free(item.docstring.?);
            }

            zig_data.deinit(allocator);
        }

        fd.close(io);
    }

    if (!python_target_file_created) {
        try tf_manager.deleteUnusedTargetFiles(io, target_dir, "python_report.md");
    } else if (!go_target_file_created) {
        try tf_manager.deleteUnusedTargetFiles(io, target_dir, "go_report.md");
    } else if (!zig_target_file_created) {
        try tf_manager.deleteUnusedTargetFiles(io, target_dir, "zig_report.md");
    }
}
