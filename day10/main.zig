const std = @import("std");

pub fn main() !void {
    var gpa = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer gpa.deinit();
    var allocator = gpa.allocator();
    const fileContent = @embedFile("input.txt");

    var timer = try std.time.Timer.start();
    const part1 = try solvePart1(fileContent, &allocator);
    const part2 = try solvePart2Alt(fileContent, &allocator);

    std.debug.print("Part1: {d}\nPart2: {d}\nTime: {d:}ms\n", .{ part1, part2, timer.lap() / std.time.ns_per_ms });
}

fn getGrid(input: []const u8, allocator: *std.mem.Allocator) ![][]const u8 {
    var grid = std.ArrayList([]const u8).init(allocator.*);
    var lines = std.mem.tokenizeAny(u8, input, "\n");
    while (lines.next()) |line| {
        try grid.append(line);
    }
    return grid.toOwnedSlice();
}

const DOWN_MOV = [_]u8{ '|', 'L', 'J' };
const DOWN_S_MOV = [_]u8{'S'} ++ DOWN_MOV;
const UP_MOV = [_]u8{ '|', 'F', '7' };
const UP_S_MOV = [_]u8{'S'} ++ UP_MOV;
const LEFT_MOV = [_]u8{ '-', 'J', '7' };
const LEFT_S_MOV = [_]u8{'S'} ++ LEFT_MOV;
const RIGHT_MOV = [_]u8{ '-', 'L', 'F' };
const RIGHT_S_MOV = [_]u8{'S'} ++ RIGHT_MOV;

inline fn mapCharToInt(char: u8) usize {
    return switch (char) {
        '|' => 0,
        'L' => 1,
        'J' => 2,
        'F' => 3,
        '7' => 4,
        '-' => 5,
        else => unreachable,
    };
}

inline fn mapIntToChar(char: usize) u8 {
    return switch (char) {
        0 => '|',
        1 => 'L',
        2 => 'J',
        3 => 'F',
        4 => '7',
        5 => '-',
        else => unreachable,
    };
}

fn solvePart1(input: []const u8, allocator: *std.mem.Allocator) !usize {
    const grid = try getGrid(input, allocator);
    defer allocator.free(grid);
    var loop = std.AutoHashMap([2]usize, void).init(allocator.*);
    var list = std.ArrayList([2]usize).init(allocator.*);
    defer loop.deinit();
    defer list.deinit();
    var sPosition = [2]usize{ 0, 0 };
    for (grid, 0..) |row, rowIndex| {
        for (row, 0..) |column, columnIndex| {
            if (column == 'S') {
                sPosition = .{ rowIndex, columnIndex };
                break;
            }
        }
    }

    try loop.put(sPosition, {});
    try list.append(sPosition);
    while (list.popOrNull()) |entry| {
        const rowIndex = entry[0];
        const columnIndex = entry[1];
        const char = grid[rowIndex][columnIndex];
        if (rowIndex > 0) {
            const nextUpChar = grid[rowIndex - 1][columnIndex];
            const nextUpPos = [2]usize{ rowIndex - 1, columnIndex };
            if (!loop.contains(nextUpPos)) {
                if (std.mem.indexOfScalar(u8, &DOWN_S_MOV, char)) |_| {
                    if (std.mem.indexOfScalar(u8, &UP_MOV, nextUpChar)) |_| {
                        try loop.put(nextUpPos, {});
                        try list.append(nextUpPos);
                    }
                }
            }
        }
        if (rowIndex < grid.len - 1) {
            const nextDownChar = grid[rowIndex + 1][columnIndex];
            const nextDownPos = [2]usize{ rowIndex + 1, columnIndex };
            if (!loop.contains(nextDownPos)) {
                if (std.mem.indexOfScalar(u8, &UP_S_MOV, char)) |_| {
                    if (std.mem.indexOfScalar(u8, &DOWN_MOV, nextDownChar)) |_| {
                        try loop.put(nextDownPos, {});
                        try list.append(nextDownPos);
                    }
                }
            }
        }
        if (columnIndex > 0) {
            const nextLeftChar = grid[rowIndex][columnIndex - 1];
            const nextLeftPos = [2]usize{ rowIndex, columnIndex - 1 };
            if (!loop.contains(nextLeftPos)) {
                if (std.mem.indexOfScalar(u8, &LEFT_S_MOV, char)) |_| {
                    if (std.mem.indexOfScalar(u8, &RIGHT_MOV, nextLeftChar)) |_| {
                        try loop.put(nextLeftPos, {});
                        try list.append(nextLeftPos);
                    }
                }
            }
        }
        if (columnIndex < grid[0].len - 1) {
            const nextRigthChar = grid[rowIndex][columnIndex + 1];
            const nextRightPos = [2]usize{ rowIndex, columnIndex + 1 };
            if (!loop.contains(nextRightPos)) {
                if (std.mem.indexOfScalar(u8, &RIGHT_S_MOV, char)) |_| {
                    if (std.mem.indexOfScalar(u8, &LEFT_MOV, nextRigthChar)) |_| {
                        try loop.put(nextRightPos, {});
                        try list.append(nextRightPos);
                    }
                }
            }
        }
    }

    return loop.count() / 2;
}

fn solvePart2(input: []const u8, allocator: *std.mem.Allocator) !usize {
    var grid = try getGrid(input, allocator);
    defer allocator.free(grid);
    const bitSet = std.bit_set.IntegerBitSet(6);

    var positionOfS = [2]usize{ 0, 0 };
    for (grid, 0..) |row, rowIndex| {
        for (row, 0..) |char, columnIndex| {
            if (char == 'S') {
                positionOfS = .{ rowIndex, columnIndex };
                break;
            }
        }
    }

    var maybeS = bitSet.initFull();

    var loop = std.AutoHashMap([2]usize, void).init(allocator.*);
    defer loop.deinit();
    try loop.put(positionOfS, {});

    var neighbourList = std.ArrayList([2]usize).init(allocator.*);
    defer neighbourList.deinit();
    try neighbourList.append(positionOfS);
    while (neighbourList.popOrNull()) |neighbour| {
        const rowIndex = neighbour[0];
        const columnIndex = neighbour[1];
        const char = grid[rowIndex][columnIndex];
        if (rowIndex > 0) {
            const nextUpChar = grid[rowIndex - 1][columnIndex];
            const nextUpPos = [2]usize{ rowIndex - 1, columnIndex };
            if (!loop.contains(nextUpPos)) {
                if (std.mem.indexOfScalar(u8, &DOWN_S_MOV, char)) |_| {
                    if (std.mem.indexOfScalar(u8, &UP_MOV, nextUpChar)) |_| {
                        try loop.put(nextUpPos, {});
                        try neighbourList.append(nextUpPos);
                        if (char == 'S') {
                            var bitSetS = bitSet.initEmpty();
                            for (DOWN_MOV) |charToSet| {
                                bitSetS.set(mapCharToInt(charToSet));
                            }
                            maybeS = bitSet.intersectWith(maybeS, bitSetS);
                        }
                    }
                }
            }
        }
        if (rowIndex < grid.len - 1) {
            const nextDownChar = grid[rowIndex + 1][columnIndex];
            const nextDownPos = [2]usize{ rowIndex + 1, columnIndex };
            if (!loop.contains(nextDownPos)) {
                if (std.mem.indexOfScalar(u8, &UP_S_MOV, char)) |_| {
                    if (std.mem.indexOfScalar(u8, &DOWN_MOV, nextDownChar)) |_| {
                        try loop.put(nextDownPos, {});
                        try neighbourList.append(nextDownPos);
                        if (char == 'S') {
                            var bitSetS = bitSet.initEmpty();
                            for (UP_MOV) |charToSet| {
                                bitSetS.set(mapCharToInt(charToSet));
                            }
                            maybeS = bitSet.intersectWith(maybeS, bitSetS);
                        }
                    }
                }
            }
        }
        if (columnIndex > 0) {
            const nextLeftChar = grid[rowIndex][columnIndex - 1];
            const nextLeftPos = [2]usize{ rowIndex, columnIndex - 1 };
            if (!loop.contains(nextLeftPos)) {
                if (std.mem.indexOfScalar(u8, &LEFT_S_MOV, char)) |_| {
                    if (std.mem.indexOfScalar(u8, &RIGHT_MOV, nextLeftChar)) |_| {
                        try loop.put(nextLeftPos, {});
                        try neighbourList.append(nextLeftPos);
                        if (char == 'S') {
                            var bitSetS = bitSet.initEmpty();
                            for (LEFT_MOV) |charToSet| {
                                bitSetS.set(mapCharToInt(charToSet));
                            }
                            maybeS = bitSet.intersectWith(maybeS, bitSetS);
                        }
                    }
                }
            }
        }
        if (columnIndex < grid[0].len - 1) {
            const nextRigthChar = grid[rowIndex][columnIndex + 1];
            const nextRightPos = [2]usize{ rowIndex, columnIndex + 1 };
            if (!loop.contains(nextRightPos)) {
                if (std.mem.indexOfScalar(u8, &RIGHT_S_MOV, char)) |_| {
                    if (std.mem.indexOfScalar(u8, &LEFT_MOV, nextRigthChar)) |_| {
                        try loop.put(nextRightPos, {});
                        try neighbourList.append(nextRightPos);
                        if (char == 'S') {
                            var bitSetS = bitSet.initEmpty();
                            for (RIGHT_MOV) |charToSet| {
                                bitSetS.set(mapCharToInt(charToSet));
                            }
                            maybeS = bitSet.intersectWith(maybeS, bitSetS);
                        }
                    }
                }
            }
        }
    }

    const intForChar = maybeS.findFirstSet().?;
    var newGrid = try std.ArrayList([]const u8).initCapacity(allocator.*, grid.len);
    for (grid, 0..) |row, rowIndex| {
        var newRow = try std.ArrayList(u8).initCapacity(allocator.*, row.len);
        for (row, 0..) |column, columnIndex| {
            if (rowIndex == positionOfS[0] and columnIndex == positionOfS[1]) {
                try newRow.append(mapIntToChar(intForChar));
            } else if (loop.contains([2]usize{ rowIndex, columnIndex })) {
                try newRow.append(column);
            } else {
                try newRow.append('.');
            }
        }
        try newGrid.append(try newRow.toOwnedSlice());
    }
    grid = try newGrid.toOwnedSlice();

    var outside = std.AutoHashMap([2]usize, void).init(allocator.*);
    defer outside.deinit();
    for (grid, 0..) |row, rowIndex| {
        var within = false;
        var up: ?bool = undefined;
        for (row, 0..) |column, columnIndex| {
            switch (column) {
                '|' => {
                    within = !within;
                },
                'L', 'F' => {
                    up = column == 'L';
                },
                '7', 'J' => {
                    if (up.? and column != 'J') {
                        within = !within;
                    }
                    if (!up.? and column != '7') {
                        within = !within;
                    }
                },
                else => {},
            }
            if (!within) {
                try outside.put([2]usize{ rowIndex, columnIndex }, {});
            }
        }
    }

    var combinedSet = std.AutoHashMap([2]usize, void).init(allocator.*);
    defer combinedSet.deinit();
    var loopIterator = loop.keyIterator();
    while (loopIterator.next()) |entry| {
        try combinedSet.put(entry.*, {});
    }
    var outsideIterator = outside.keyIterator();
    while (outsideIterator.next()) |entry| {
        try combinedSet.put(entry.*, {});
    }

    const result = grid.len * grid[0].len - combinedSet.count();

    return result;
}

fn solvePart2Alt(input: []const u8, allocator: *std.mem.Allocator) !usize {
    const grid = try getGrid(input, allocator);
    defer allocator.free(grid);
    const bitSet = std.bit_set.IntegerBitSet(6);

    var positionOfS = [2]usize{ 0, 0 };
    for (grid, 0..) |row, rowIndex| {
        for (row, 0..) |char, columnIndex| {
            if (char == 'S') {
                positionOfS = .{ rowIndex, columnIndex };
                break;
            }
        }
    }

    var maybeS = bitSet.initFull();

    var loop = std.AutoHashMap([2]usize, u8).init(allocator.*);
    defer loop.deinit();
    try loop.put(positionOfS, 'S');

    var neighbourList = std.ArrayList([2]usize).init(allocator.*);
    defer neighbourList.deinit();
    try neighbourList.append(positionOfS);
    while (neighbourList.popOrNull()) |neighbour| {
        const rowIndex = neighbour[0];
        const columnIndex = neighbour[1];
        const char = grid[rowIndex][columnIndex];
        if (rowIndex > 0) {
            const nextUpChar = grid[rowIndex - 1][columnIndex];
            const nextUpPos = [2]usize{ rowIndex - 1, columnIndex };
            if (!loop.contains(nextUpPos)) {
                if (std.mem.indexOfScalar(u8, &DOWN_S_MOV, char)) |_| {
                    if (std.mem.indexOfScalar(u8, &UP_MOV, nextUpChar)) |_| {
                        try loop.put(nextUpPos, nextUpChar);
                        try neighbourList.append(nextUpPos);
                        if (char == 'S') {
                            var bitSetS = bitSet.initEmpty();
                            for (DOWN_MOV) |charToSet| {
                                bitSetS.set(mapCharToInt(charToSet));
                            }
                            maybeS = bitSet.intersectWith(maybeS, bitSetS);
                        }
                    }
                }
            }
        }
        if (rowIndex < grid.len - 1) {
            const nextDownChar = grid[rowIndex + 1][columnIndex];
            const nextDownPos = [2]usize{ rowIndex + 1, columnIndex };
            if (!loop.contains(nextDownPos)) {
                if (std.mem.indexOfScalar(u8, &UP_S_MOV, char)) |_| {
                    if (std.mem.indexOfScalar(u8, &DOWN_MOV, nextDownChar)) |_| {
                        try loop.put(nextDownPos, nextDownChar);
                        try neighbourList.append(nextDownPos);
                        if (char == 'S') {
                            var bitSetS = bitSet.initEmpty();
                            for (UP_MOV) |charToSet| {
                                bitSetS.set(mapCharToInt(charToSet));
                            }
                            maybeS = bitSet.intersectWith(maybeS, bitSetS);
                        }
                    }
                }
            }
        }
        if (columnIndex > 0) {
            const nextLeftChar = grid[rowIndex][columnIndex - 1];
            const nextLeftPos = [2]usize{ rowIndex, columnIndex - 1 };
            if (!loop.contains(nextLeftPos)) {
                if (std.mem.indexOfScalar(u8, &LEFT_S_MOV, char)) |_| {
                    if (std.mem.indexOfScalar(u8, &RIGHT_MOV, nextLeftChar)) |_| {
                        try loop.put(nextLeftPos, nextLeftChar);
                        try neighbourList.append(nextLeftPos);
                        if (char == 'S') {
                            var bitSetS = bitSet.initEmpty();
                            for (LEFT_MOV) |charToSet| {
                                bitSetS.set(mapCharToInt(charToSet));
                            }
                            maybeS = bitSet.intersectWith(maybeS, bitSetS);
                        }
                    }
                }
            }
        }
        if (columnIndex < grid[0].len - 1) {
            const nextRigthChar = grid[rowIndex][columnIndex + 1];
            const nextRightPos = [2]usize{ rowIndex, columnIndex + 1 };
            if (!loop.contains(nextRightPos)) {
                if (std.mem.indexOfScalar(u8, &RIGHT_S_MOV, char)) |_| {
                    if (std.mem.indexOfScalar(u8, &LEFT_MOV, nextRigthChar)) |_| {
                        try loop.put(nextRightPos, nextRigthChar);
                        try neighbourList.append(nextRightPos);
                        if (char == 'S') {
                            var bitSetS = bitSet.initEmpty();
                            for (RIGHT_MOV) |charToSet| {
                                bitSetS.set(mapCharToInt(charToSet));
                            }
                            maybeS = bitSet.intersectWith(maybeS, bitSetS);
                        }
                    }
                }
            }
        }
    }

    const intForChar = maybeS.findFirstSet().?;
    const newSValue = mapIntToChar(intForChar);
    try loop.put(positionOfS, newSValue);

    var insideTiles: usize = 0;
    for (grid, 0..) |row, ri| {
        var inside = false;
        for (row, 0..) |_, ci| {
            if (loop.get([2]usize{ ri, ci })) |entry| {
                switch (entry) {
                    '|', '7', 'F' => inside = !inside,
                    else => {},
                }
            } else if (inside) {
                insideTiles += 1;
            }
        }
    }

    return insideTiles;
}

test "test-input" {
    var gpa = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer gpa.deinit();
    var allocator = gpa.allocator();
    const fileContent = @embedFile("test.txt");

    const part1 = try solvePart1(fileContent, &allocator);
    const part2 = try solvePart2(fileContent, &allocator);
    const part2Alt = try solvePart2Alt(fileContent, &allocator);

    try std.testing.expectEqual(part1, 23);
    try std.testing.expectEqual(part2Alt, 4);
    try std.testing.expectEqual(part2Alt, part2);
}
