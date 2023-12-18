const std = @import("std");

pub fn main() !void {
    var gpa = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer gpa.deinit();
    var allocator = gpa.allocator();
    const fileContent = @embedFile("input.txt");

    var timer = try std.time.Timer.start();
    var part1 = try solvePart1Alt(fileContent, &allocator);
    var part2 = try solvePart2Alt(fileContent, &allocator);

    std.debug.print("Part1: {d}\nPart2: {d}\nTime: {d}us\n", .{ part1, part2, timer.lap() / std.time.ns_per_us });
}

inline fn solveAlt(input: []const u8, allocator: *std.mem.Allocator, comptime expandBy: usize) !usize {
    var result: usize = 0;
    var grid = std.mem.tokenizeScalar(u8, input, '\n');
    var lineSize: usize = 0;
    while (grid.next()) |row| {
        lineSize = row.len;
        break;
    }
    grid.reset();

    var xx = try std.ArrayList(usize).initCapacity(allocator.*, lineSize);
    var yy = try std.ArrayList(usize).initCapacity(allocator.*, lineSize);
    for (0..lineSize) |_| {
        xx.appendAssumeCapacity(0);
        yy.appendAssumeCapacity(0);
    }
    defer xx.deinit();
    defer yy.deinit();

    var rowIndex: usize = 0;
    while (grid.next()) |row| : (rowIndex += 1) {
        for (row, 0..) |char, columnIndex| {
            if (char == '#') {
                xx.items[rowIndex] += 1;
                yy.items[columnIndex] += 1;
            }
        }
    }

    result += dist(xx.items, expandBy);
    result += dist(yy.items, expandBy);

    return result;
}

inline fn dist(counts: []usize, comptime expandBy: usize) usize {
    var gaps: usize = 0;
    var sum: usize = 0;
    var items: usize = 0;
    var distV: usize = 0;

    for (counts, 0..) |count, index| {
        if (count > 0) {
            const expanded = index + expandBy * gaps;
            distV += count * (items * expanded - sum);
            sum += count * expanded;
            items += count;
        } else {
            gaps += 1;
        }
    }

    return distV;
}

fn solvePart1Alt(input: []const u8, allocator: *std.mem.Allocator) !usize {
    return try solveAlt(input, allocator, 1);
}

fn solvePart2Alt(input: []const u8, allocator: *std.mem.Allocator) !usize {
    return try solveAlt(input, allocator, 999_999);
}

inline fn solve(input: []const u8, allocator: *std.mem.Allocator, comptime scale: usize) !usize {
    var result: usize = 0;
    var emptyRows = std.ArrayList(bool).init(allocator.*);
    var emptyColumns = std.ArrayList(bool).init(allocator.*);
    var galaxyList = std.ArrayList([2]usize).init(allocator.*);
    defer emptyRows.deinit();
    defer emptyColumns.deinit();
    defer galaxyList.deinit();

    var grid = std.mem.tokenizeScalar(u8, input, '\n');
    var rowIndex: usize = 0;
    while (grid.next()) |row| {
        if (emptyColumns.items.len == 0 or emptyRows.items.len == 0) {
            for (0..row.len) |_| {
                // only possible because the input is always a square
                try emptyRows.append(true);
                try emptyColumns.append(true);
            }
        }
        for (row, 0..) |char, columnIndex| {
            if (char == '#') {
                try galaxyList.append([2]usize{ rowIndex, columnIndex });
                emptyRows.items[rowIndex] = false;
                emptyColumns.items[columnIndex] = false;
            }
        }
        rowIndex += 1;
    }

    for (galaxyList.items, 0..) |galaxy, i| {
        const r1 = galaxy[0];
        const c1 = galaxy[1];
        for (galaxyList.items[i + 1 ..]) |subGalaxy| {
            const r2 = subGalaxy[0];
            const c2 = subGalaxy[1];

            for (@min(r1, r2)..@max(r1, r2)) |r| {
                result += if (emptyRows.items[r]) scale else 1;
            }

            for (@min(c1, c2)..@max(c1, c2)) |c| {
                result += if (emptyColumns.items[c]) scale else 1;
            }
        }
    }

    return result;
}

fn solvePart1(input: []const u8, allocator: *std.mem.Allocator) !usize {
    return try solve(input, allocator, 2);
}

fn solvePart2(input: []const u8, allocator: *std.mem.Allocator) !usize {
    return try solve(input, allocator, 1_000_000);
}

test "test-input" {
    var allocator = std.testing.allocator;
    const fileContent = @embedFile("test.txt");

    var part1 = try solvePart1(fileContent, &allocator);
    var part2 = try solvePart2(fileContent, &allocator);
    var part1Alt = try solvePart1(fileContent, &allocator);
    var part2Alt = try solvePart2(fileContent, &allocator);

    try std.testing.expectEqual(part1, 374);
    try std.testing.expectEqual(part1, part1Alt);
    try std.testing.expectEqual(part2, 82000210);
    try std.testing.expectEqual(part2, part2Alt);
}
