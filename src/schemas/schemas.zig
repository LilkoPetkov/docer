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

pub const TargetFiles = struct {
    py_target_file: ?std.fs.File,
    go_target_file: ?std.fs.File,
    zig_target_file: ?std.fs.File,
};

pub const File = struct {
    fd: std.fs.File,
    target_files: TargetFiles,
    file_size: u64,
};

pub const FuncAndDefinition = struct {
    func: ?[]u8,
    docstring: ?[]u8,
};

pub const FileTypes = enum(u8) { go, python, zig };

// pub const PythonData = struct {
//     data: std.ArrayList(PythonFuncAndDoc),
// };
