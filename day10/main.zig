const std = @import("std");

pub fn main() !void {
    var gpa = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer gpa.deinit();
    var allocator = gpa.allocator();
    const fileContent = @embedFile("input.txt");

    var part1 = try solvePart1(fileContent, &allocator);
    var part2 = try solvePart2(fileContent, &allocator);

    std.debug.print("Part1: {d}\nPart2: {d}\n", .{ part1, part2 });
}

fn getGrid(input: []const u8, allocator: *std.mem.Allocator) ![][]const u8 {
    var grid = std.ArrayList([]const u8).init(allocator.*);
    var lines = std.mem.tokenizeAny(u8, input, "\n");
    while (lines.next()) |line| {
        try grid.append(line);
    }
    return grid.toOwnedSlice();
}

// | is a vertical pipe connecting north and south.
// - is a horizontal pipe connecting east and west.
// L is a 90-degree bend connecting north and east.
// J is a 90-degree bend connecting north and west.
// 7 is a 90-degree bend connecting south and west.
// F is a 90-degree bend connecting south and east.
// . is ground; there is no pipe in this tile.
// S is the starting position of the animal; there is a pipe on this

const DOWN_MOV = [_]u8{ '|', 'L', 'J' };
const DOWN_S_MOV = [_]u8{'S'} ++ DOWN_MOV;
const UP_MOV = [_]u8{ '|', 'F', '7' };
const UP_S_MOV = [_]u8{'S'} ++ UP_MOV;
const LEFT_MOV = [_]u8{ '-', 'J', '7' };
const LEFT_S_MOV = [_]u8{'S'} ++ LEFT_MOV;
const RIGHT_MOV = [_]u8{ '-', 'L', 'F' };
const RIGHT_S_MOV = [_]u8{'S'} ++ RIGHT_MOV;

fn solvePart1(input: []const u8, allocator: *std.mem.Allocator) !usize {
    var grid = try getGrid(input, allocator);
    defer allocator.free(grid);
    var pipeSet = std.AutoHashMap([2]usize, void).init(allocator.*);
    var list = std.ArrayList([2]usize).init(allocator.*);
    defer pipeSet.deinit();
    defer list.deinit();
    var sPosition = [2]usize{ 0, 0 };
    for (grid, 0..) |row, rowIndex| {
        for (row, 0..) |column, columnIndex| {
            if (column == 'S') {
                sPosition = .{ rowIndex, columnIndex };
            }
        }
    }

    try pipeSet.put(sPosition, {});
    try list.append(sPosition);
    while (list.popOrNull()) |entry| {
        const rowIndex = entry[0];
        const columnIndex = entry[1];
        const char = grid[rowIndex][columnIndex];
        if (rowIndex > 0) {
            const nextUpChar = grid[rowIndex - 1][columnIndex];
            const nextUpPos = [2]usize{ rowIndex - 1, columnIndex };
            var inPipe = false;
            if (pipeSet.get(nextUpPos)) |_| {
                inPipe = true;
            }
            if (!inPipe) {
                if (std.mem.indexOfScalar(u8, &DOWN_S_MOV, char)) |_| {
                    if (std.mem.indexOfScalar(u8, &UP_MOV, nextUpChar)) |_| {
                        try pipeSet.put(nextUpPos, {});
                        try list.append(nextUpPos);
                        continue;
                    }
                }
            }
        }
        if (rowIndex < grid.len - 1) {
            const nextDownChar = grid[rowIndex + 1][columnIndex];
            const nextDownPos = [2]usize{ rowIndex + 1, columnIndex };
            var inPipe = false;
            if (pipeSet.get(nextDownPos)) |_| {
                inPipe = true;
            }
            if (!inPipe) {
                if (std.mem.indexOfScalar(u8, &UP_S_MOV, char)) |_| {
                    if (std.mem.indexOfScalar(u8, &DOWN_MOV, nextDownChar)) |_| {
                        try pipeSet.put(nextDownPos, {});
                        try list.append(nextDownPos);
                        continue;
                    }
                }
            }
        }
        if (columnIndex > 0) {
            const nextLeftChar = grid[rowIndex][columnIndex - 1];
            const nextLeftPos = [2]usize{ rowIndex, columnIndex - 1 };
            var inPipe = false;
            if (pipeSet.get(nextLeftPos)) |_| {
                inPipe = true;
            }
            if (!inPipe) {
                if (std.mem.indexOfScalar(u8, &LEFT_S_MOV, char)) |_| {
                    if (std.mem.indexOfScalar(u8, &RIGHT_MOV, nextLeftChar)) |_| {
                        try pipeSet.put(nextLeftPos, {});
                        try list.append(nextLeftPos);
                        continue;
                    }
                }
            }
        }
        if (columnIndex < grid[0].len - 1) {
            const nextRigthChar = grid[rowIndex][columnIndex + 1];
            const nextRightPos = [2]usize{ rowIndex, columnIndex + 1 };
            var inPipe = false;
            if (pipeSet.get(nextRightPos)) |_| {
                inPipe = true;
            }
            if (!inPipe) {
                if (std.mem.indexOfScalar(u8, &RIGHT_S_MOV, char)) |_| {
                    if (std.mem.indexOfScalar(u8, &LEFT_MOV, nextRigthChar)) |_| {
                        try pipeSet.put(nextRightPos, {});
                        try list.append(nextRightPos);
                        continue;
                    }
                }
            }
        }
    }

    return pipeSet.count() / 2;
}

fn solvePart2(input: []const u8, allocator: *std.mem.Allocator) !usize {
    var grid = try getGrid(input, allocator);
    defer allocator.free(grid);
    return 0;
}

test "test-input" {
    var allocator = std.testing.allocator;
    const fileContentPart1 = @embedFile("test1.txt");
    const fileContentPart2 = @embedFile("test1.txt");

    var part1 = try solvePart1(fileContentPart1, &allocator);
    var part2 = try solvePart2(fileContentPart2, &allocator);

    try std.testing.expectEqual(part1, 8);
    try std.testing.expectEqual(part2, 0);
}
