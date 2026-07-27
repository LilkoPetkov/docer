const std = @import("std");
const Allocator = std.mem.Allocator;

const print = std.debug.print;

pub fn processArgs(allocator: Allocator) ![]const u8 {
    var args = try std.process.argsWithAllocator(allocator);
    defer args.deinit();

    _ = args.skip();

    if (args.inner.count <= 1) return error.MissingArguments;

    while (args.next()) |arg| {
        if (std.mem.eql(u8, arg, "-p") or std.mem.eql(u8, arg, "--path")) {
            const arg_val = args.next();

            if (arg_val != null) {
                const path_arg = try allocator.dupe(u8, arg_val.?);

                return path_arg;
            } else return error.MissingArgument;
        } else {
            return error.InvalidArgument;
        }
    }

    return error.MissingArguments;
}
