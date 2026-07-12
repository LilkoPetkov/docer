const std = @import("std");

pub fn main() !void {
    const arr = [2]u8{ 1, 2 };

    for (arr) |item| {
        std.debug.print("Item: {d}\n", .{item});
    }
}

fn testFunc(
    x: u8,
    y: u8,
    z: []const u8,
) !std.ArrayList(u8) {}

fn testFuncWithStruct(x: u8, y: u8, test_struct: struct {}) !void {
    std.debug.print("X, Y, Struct: {s} - {s} - {s}\n", .{ x, y, test_struct });
}
