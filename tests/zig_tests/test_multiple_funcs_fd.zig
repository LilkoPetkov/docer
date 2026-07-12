const std = @import("std");

/// This is a multiline function definition
///
/// Args:
///  None
/// Returns:
///  Void
pub fn testMain() !void {
    const arr = [2]u8{ 1, 2 };

    for (arr) |item| {
        std.debug.print("Item: {d}\n", .{item});
    }
}

/// This is a test function, it makes no sense
pub fn testFunc(x: []const u8, y: []const u8) !void {
    const arr = [2]u8{ 1, 2 };

    for (arr) |item| {
        std.debug.print("Item: {d}\n", .{item});
    }

    std.debug.print("X - Y: {s} / {s}\n", .{ x, y });
}
