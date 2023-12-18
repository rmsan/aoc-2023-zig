const std = @import("std");

pub fn main() !void {
    var gpa = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer gpa.deinit();
    var allocator = gpa.allocator();
    const fileContent = @embedFile("input.txt");

    var timer = try std.time.Timer.start();
    const part1 = try solvePart1(fileContent, &allocator);
    const part2 = try solvePart2(fileContent, &allocator);

    std.debug.print("Part1: {d}\nPart2: {d}\nTime: {d}us\n", .{ part1, part2, timer.lap() / std.time.ns_per_us });
}

const Part = enum { One, Two };

inline fn solve(input: []const u8, allocator: *std.mem.Allocator, comptime part: Part) !isize {
    var result: isize = 0;
    var lines = std.mem.tokenizeScalar(u8, input, '\n');
    while (lines.next()) |line| {
        var dataSet = std.ArrayList([]isize).init(allocator.*);
        defer dataSet.deinit();
        var numberIterator = std.mem.tokenizeScalar(u8, line, ' ');
        var numberCount: usize = 0;
        var initialNumberList = std.ArrayList(isize).init(allocator.*);
        while (numberIterator.next()) |numberString| {
            const number = try std.fmt.parseInt(isize, numberString, 10);
            try initialNumberList.append(number);
            numberCount += 1;
        }
        var numberListItems = try initialNumberList.toOwnedSlice();
        defer allocator.free(numberListItems);
        try dataSet.append(numberListItems);
        while (numberCount > 0) {
            var diffList = try std.ArrayList(isize).initCapacity(allocator.*, numberCount - 1);
            defer diffList.deinit();
            var zeroesCount: usize = 0;
            for (numberListItems, 1..) |item, index| {
                if (index < numberCount) {
                    const diff: isize = numberListItems[index] - item;
                    if (diff == 0) {
                        zeroesCount += 1;
                    }
                    diffList.appendAssumeCapacity(diff);
                }
            }

            const slice = try diffList.toOwnedSlice();
            try dataSet.append(slice);
            numberListItems = slice;
            numberCount -= 1;
            if (zeroesCount == numberCount) {
                break;
            }
        }

        var lineMax: isize = 0;
        // skip the zeroes line
        _ = dataSet.pop();
        while (dataSet.popOrNull()) |currentNumbers| {
            if (part == Part.One) {
                lineMax += currentNumbers[currentNumbers.len - 1];
            } else {
                lineMax = currentNumbers[0] - lineMax;
            }
        }
        result += lineMax;
    }

    return result;
}

fn solvePart1(input: []const u8, allocator: *std.mem.Allocator) !isize {
    return try solve(input, allocator, Part.One);
}

fn solvePart2(input: []const u8, allocator: *std.mem.Allocator) !isize {
    return try solve(input, allocator, Part.Two);
}

test "test-input" {
    var gpa = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer gpa.deinit();
    var allocator = gpa.allocator();
    const fileContent = @embedFile("test.txt");

    const part1 = try solvePart1(fileContent, &allocator);
    const part2 = try solvePart2(fileContent, &allocator);

    try std.testing.expectEqual(part1, 114);
    try std.testing.expectEqual(part2, 2);
}
