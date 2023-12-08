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

fn solvePart1(input: []const u8, allocator: *std.mem.Allocator) !usize {
    var grid = try getGrid(input, allocator);
    defer allocator.free(grid);

    var digitNeighbours = std.AutoHashMap([2]usize, void).init(allocator.*);
    defer digitNeighbours.deinit();
    for (grid, 0..) |row, rowIndex| {
        for (row, 0..) |column, columnIndex| {
            if (column == '.' or std.ascii.isDigit(column)) {
                continue;
            }

            // this is only safe because the puzzle input contains symbols from the second line to
            // the second last line, thank you authors :)
            const rowNeighbours: [3]usize = .{ rowIndex - 1, rowIndex, rowIndex + 1 };
            const columnNeighbours: [3]usize = .{ columnIndex - 1, columnIndex, columnIndex + 1 };
            for (rowNeighbours) |rowNeighbour| {
                for (columnNeighbours) |columnNeighbour| {
                    const actualChar = grid[rowNeighbour][columnNeighbour];
                    if (std.ascii.isDigit(actualChar)) {
                        var minus: usize = 0;
                        while (true) {
                            // returns a tuple with the result and a u1 (0 = no overflow)
                            const left = @subWithOverflow(columnNeighbour, minus + 1);
                            if (left[1] != 0) {
                                break;
                            }
                            const checkLeft = grid[rowNeighbour][left[0]];
                            if (std.ascii.isDigit(checkLeft)) {
                                minus += 1;
                            } else {
                                break;
                            }
                        }
                        try digitNeighbours.put(.{ rowNeighbour, columnNeighbour - minus }, {});
                    }
                }
            }
        }
    }

    var result: usize = 0;
    var it = digitNeighbours.iterator();
    while (it.next()) |digitNeighbour| {
        const x = digitNeighbour.key_ptr.*[0];
        const y = digitNeighbour.key_ptr.*[1];
        var plus: usize = 1;
        while (true) {
            const right = y + plus;
            const checkRight = grid[x][right];
            if (std.ascii.isDigit(checkRight)) {
                plus += 1;
            } else {
                break;
            }
        }
        const digitString = grid[x][y .. y + plus];
        const digit = try std.fmt.parseInt(usize, digitString, 10);
        result += digit;
    }

    return result;
}

fn solvePart2(input: []const u8, allocator: *std.mem.Allocator) !usize {
    var grid = try getGrid(input, allocator);
    defer allocator.free(grid);

    var finalResult: usize = 0;
    for (grid, 0..) |row, rowIndex| {
        for (row, 0..) |column, columnIndex| {
            if (column != '*') {
                continue;
            }

            var digitNeighbours = std.AutoHashMap([2]usize, void).init(allocator.*);
            defer digitNeighbours.deinit();
            const rowNeighbours: [3]usize = .{ rowIndex - 1, rowIndex, rowIndex + 1 };
            const columnNeighbours: [3]usize = .{ columnIndex - 1, columnIndex, columnIndex + 1 };
            for (rowNeighbours) |rowNeighbour| {
                for (columnNeighbours) |columnNeighbour| {
                    const actualChar = grid[rowNeighbour][columnNeighbour];
                    if (std.ascii.isDigit(actualChar)) {
                        var minus: usize = 0;
                        while (true) {
                            // returns a tuple with the result and a u1 (0 = no overflow)
                            const left = @subWithOverflow(columnNeighbour, minus + 1);
                            if (left[1] != 0) {
                                break;
                            }
                            const checkLeft = grid[rowNeighbour][left[0]];
                            if (std.ascii.isDigit(checkLeft)) {
                                minus += 1;
                            } else {
                                break;
                            }
                        }
                        try digitNeighbours.put(.{ rowNeighbour, columnNeighbour - minus }, {});
                    }
                }
            }

            if (digitNeighbours.count() == 2) {
                var result: usize = 1;
                var it = digitNeighbours.iterator();
                while (it.next()) |digitNeighbour| {
                    const x = digitNeighbour.key_ptr.*[0];
                    const y = digitNeighbour.key_ptr.*[1];
                    var plus: usize = 1;
                    while (true) {
                        const right = y + plus;
                        const checkRight = grid[x][right];
                        if (std.ascii.isDigit(checkRight)) {
                            plus += 1;
                        } else {
                            break;
                        }
                    }
                    const digitString = grid[x][y .. y + plus];
                    const digit = try std.fmt.parseInt(usize, digitString, 10);
                    result *= digit;
                }
                finalResult += result;
            }
        }
    }

    return finalResult;
}

test "test-input" {
    var allocator = std.testing.allocator;
    const fileContent = @embedFile("test.txt");

    var part1 = try solvePart1(fileContent, &allocator);
    var part2 = try solvePart2(fileContent, &allocator);

    try std.testing.expectEqual(part1, 4361);
    try std.testing.expectEqual(part2, 467835);
}
