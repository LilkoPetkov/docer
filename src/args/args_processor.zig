const std = @import("std");
const Allocator = std.mem.Allocator;

const print = std.debug.print;

pub fn processArgs(allocator: Allocator, arg_iterator: *std.process.Args.Iterator) ![]const u8 {
    if (arg_iterator.*.inner.remaining.len == 1) return error.MissingArguments;

    _ = arg_iterator.skip();

    while (arg_iterator.next()) |arg| {
        if (std.mem.eql(u8, arg, "-p") or std.mem.eql(u8, arg, "--path")) {
            const arg_val = arg_iterator.next();

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
