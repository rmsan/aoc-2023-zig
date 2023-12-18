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

inline fn process(comptime part: Part, rowsOrColumns: *std.ArrayList(u32), factor: usize, result: *usize) void {
    for (0..rowsOrColumns.items.len - 1) |index| {
        var diffs: u32 = 0;
        var c0: isize = @intCast(index);
        var c1 = index + 1;
        while (c0 >= 0 and c1 < rowsOrColumns.items.len) {
            diffs += @popCount(rowsOrColumns.items[@intCast(c0)] ^ rowsOrColumns.items[c1]);
            c0 -= 1;
            c1 += 1;
        }
        var diffFactor: usize = 0;
        switch (part) {
            Part.One => {
                if (diffs == 0) {
                    diffFactor = 1;
                }
            },
            else => {
                if (diffs == 1) {
                    diffFactor = 1;
                }
            },
        }

        result.* += diffFactor * (index + 1) * factor;
    }
}

inline fn solve(comptime part: Part, input: []const u8, allocator: *std.mem.Allocator) !usize {
    var result: usize = 0;
    var blocks = std.mem.tokenizeSequence(u8, input, "\n\n");
    while (blocks.next()) |block| {
        var rows = std.ArrayList(u32).init(allocator.*);
        var columns = std.ArrayList(u32).init(allocator.*);
        defer rows.deinit();
        defer columns.deinit();
        var lines = std.mem.tokenizeScalar(u8, block, '\n');
        while (lines.next()) |line| {
            if (columns.items.len == 0) {
                for (0..line.len) |_| {
                    try columns.append(0);
                }
            }
            var row: u32 = 0;
            const j = rows.items.len;
            for (line, 0..) |char, lineIndex| {
                var condition: u32 = 0;
                if (char == '#') {
                    condition = 1;
                }
                row |= condition << @intCast(lineIndex);
                columns.items[lineIndex] |= condition << @intCast(j);
            }
            try rows.append(row);
        }
        process(part, &rows, 100, &result);
        process(part, &columns, 1, &result);
    }
    return result;
}

fn solvePart1(input: []const u8, allocator: *std.mem.Allocator) !usize {
    return try solve(Part.One, input, allocator);
}

fn solvePart2(input: []const u8, allocator: *std.mem.Allocator) !usize {
    return try solve(Part.Two, input, allocator);
}

test "test-input" {
    var allocator = std.testing.allocator;
    const fileContent = @embedFile("test.txt");

    const part1 = try solvePart1(fileContent, &allocator);
    const part2 = try solvePart2(fileContent, &allocator);

    try std.testing.expectEqual(part1, 405);
    try std.testing.expectEqual(part2, 400);
}
