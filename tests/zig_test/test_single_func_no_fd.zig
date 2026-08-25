const std = @import("std");

pub fn main() !void {
    const arr = [2]u8{ 1, 2 };

    for (arr) |item| {
        std.debug.print("Item: {d}\n", .{item});
    }
}
