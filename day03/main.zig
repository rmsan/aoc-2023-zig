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

const Pos = struct { x: usize, yLow: usize, yHigh: usize };

const Coord = struct { x: usize, y: usize };

fn getGrid(input: []const u8, allocator: *std.mem.Allocator) ![][]const u8 {
    var grid: [][]const u8 = undefined;
    var rowCount: usize = 0;
    var lines = std.mem.tokenizeAny(u8, input, "\n");
    while (lines.next()) |_| {
        rowCount += 1;
    }
    lines.reset();
    var row: usize = 0;
    grid = try allocator.alloc([]u8, rowCount);
    while (lines.next()) |line| : (row += 1) {
        grid[row] = try allocator.alloc(u8, line.len);
        grid[row] = line;
    }
    return grid;
}

fn solvePart1(input: []const u8, allocator: *std.mem.Allocator) !usize {
    var grid = try getGrid(input, allocator);

    var digitNeighbours = std.ArrayList([2]usize).init(allocator.*);
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
                        try digitNeighbours.append(.{ rowNeighbour, columnNeighbour });
                    }
                }
            }
        }
    }

    var positionSet = std.AutoHashMap(Pos, void).init(allocator.*);
    for (digitNeighbours.items) |digitNeighbour| {
        const x = digitNeighbour[0];
        const y = digitNeighbour[1];
        var minus: usize = 0;
        var plus: usize = 1;
        while (true) {
            // returns a tuple with the result and a u1 (0 = no overflow)
            const left = @subWithOverflow(y, minus + 1);
            if (left[1] != 0) {
                break;
            }
            const checkLeft = grid[x][left[0]];
            if (std.ascii.isDigit(checkLeft)) {
                minus += 1;
            } else {
                break;
            }
        }
        while (true) {
            const right = y + plus;
            const checkRight = grid[x][right];
            if (std.ascii.isDigit(checkRight)) {
                plus += 1;
            } else {
                break;
            }
        }
        const pos = Pos{ .x = x, .yLow = y - minus, .yHigh = y + plus };
        try positionSet.put(pos, {});
    }

    var result: usize = 0;
    var digitsIterator = positionSet.iterator();
    while (digitsIterator.next()) |digitToParse| {
        const digitPos = digitToParse.key_ptr.*;
        const digitString = grid[digitPos.x][digitPos.yLow..digitPos.yHigh];
        const digit = try std.fmt.parseInt(usize, digitString, 10);
        result += digit;
    }

    return result;
}

fn solvePart2(input: []const u8, allocator: *std.mem.Allocator) !usize {
    var grid = try getGrid(input, allocator);

    var digitNeighbours = std.ArrayList([4]usize).init(allocator.*);
    for (grid, 0..) |row, rowIndex| {
        for (row, 0..) |column, columnIndex| {
            if (column != '*') {
                continue;
            }

            const rowNeighbours: [3]usize = .{ rowIndex - 1, rowIndex, rowIndex + 1 };
            const columnNeighbours: [3]usize = .{ columnIndex - 1, columnIndex, columnIndex + 1 };
            for (rowNeighbours) |rowNeighbour| {
                for (columnNeighbours) |columnNeighbour| {
                    const actualChar = grid[rowNeighbour][columnNeighbour];
                    if (std.ascii.isDigit(actualChar)) {
                        try digitNeighbours.append(.{ rowNeighbour, columnNeighbour, rowIndex, columnIndex });
                    }
                }
            }
        }
    }

    var coords = std.AutoHashMap(Coord, std.AutoHashMap(Pos, void)).init(allocator.*);
    for (digitNeighbours.items) |digitNeighbour| {
        const x = digitNeighbour[0];
        const y = digitNeighbour[1];
        const row = digitNeighbour[2];
        const column = digitNeighbour[3];
        var minus: usize = 0;
        var plus: usize = 1;
        while (true) {
            const left = @subWithOverflow(y, minus + 1);
            if (left[1] != 0) {
                break;
            }
            const checkLeft = grid[x][left[0]];
            if (std.ascii.isDigit(checkLeft)) {
                minus += 1;
            } else {
                break;
            }
        }
        while (true) {
            const right = y + plus;
            const checkRight = grid[x][right];
            if (std.ascii.isDigit(checkRight)) {
                plus += 1;
            } else {
                break;
            }
        }

        const pos = Pos{ .x = x, .yLow = y - minus, .yHigh = y + plus };
        const coord = Coord{ .x = row, .y = column };
        const prevCoords = try coords.getOrPut(coord);
        if (prevCoords.found_existing) {
            var map = prevCoords.value_ptr.*;
            try map.put(pos, {});
            prevCoords.value_ptr.* = map;
        } else {
            var map = std.AutoHashMap(Pos, void).init(allocator.*);
            try map.put(pos, {});
            prevCoords.value_ptr.* = map;
        }
    }

    var result: usize = 0;
    var coordsIterator = coords.iterator();
    while (coordsIterator.next()) |coord| {
        const positions = coord.value_ptr.*;
        if (positions.count() == 2) {
            var it = positions.keyIterator();
            var gearSum: usize = 1;
            while (it.next()) |key| {
                const posString = grid[key.x][key.yLow..key.yHigh];
                const posValue = try std.fmt.parseInt(usize, posString, 10);
                gearSum *= posValue;
            }
            result += gearSum;
        }
    }

    return result;
}

test "test-input" {
    var gpa = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer gpa.deinit();
    var allocator = gpa.allocator();
    const fileContent = @embedFile("test.txt");

    var part1 = try solvePart1(fileContent, &allocator);
    var part2 = try solvePart2(fileContent, &allocator);

    try std.testing.expectEqual(part1, 4361);
    try std.testing.expectEqual(part2, 467835);
}
