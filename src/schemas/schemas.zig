const std = @import("std");

pub const PythonObjectContext = struct {
    func_found: bool = false,
    closing_func_bracket_found: bool = false,
    func_recorded: bool = false,
    doc_string_found: bool = false,
};

pub const GoObjectContext = struct {
    func_found: bool = false,
    comment_or_fd_found: bool = false,
    comment_func_found: bool = false,
};

pub const File = struct {
    fd: std.fs.File,
    target_file: ?std.fs.File,
    file_size: u64,
};

pub const FuncAndDefinition = struct {
    func: ?[]u8,
    docstring: ?[]u8,
};

// pub const PythonData = struct {
//     data: std.ArrayList(PythonFuncAndDoc),
// };
