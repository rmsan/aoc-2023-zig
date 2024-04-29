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

fn solvePart1(input: []const u8, allocator: *std.mem.Allocator) !usize {
    var positions = std.StringHashMap([2][]const u8).init(allocator.*);
    defer positions.deinit();
    var segments = std.mem.tokenizeAny(u8, input, "\n\n");
    const directions = segments.next().?;
    while (segments.next()) |position| {
        var positionInner = std.mem.tokenizeScalar(u8, position, '=');
        const key = positionInner.next().?[0..3];
        const valueString = positionInner.next().?;
        var leftRightValues = std.mem.tokenizeScalar(u8, valueString, ',');
        const leftValue = leftRightValues.next().?[2..];
        var rightValue = leftRightValues.next().?;
        rightValue = rightValue[1 .. rightValue.len - 1];
        try positions.put(key, [2][]const u8{ leftValue, rightValue });
    }

    var result: usize = 0;
    var directionPos: usize = 0;
    const directionsCount = directions.len;
    var currentPosition: []const u8 = "AAA";
    while (!std.mem.eql(u8, currentPosition, "ZZZ")) {
        const value = positions.get(currentPosition).?;
        var nextKey: []const u8 = undefined;
        if (directions[directionPos % directionsCount] == 'L') {
            nextKey = value[0];
        } else {
            nextKey = value[1];
        }
        directionPos += 1;
        currentPosition = nextKey;
        result += 1;
    }
    return result;
}

fn solvePart2(input: []const u8, allocator: *std.mem.Allocator) !usize {
    var positions = std.StringHashMap([2][]const u8).init(allocator.*);
    defer positions.deinit();
    var segments = std.mem.tokenizeAny(u8, input, "\n\n");
    const directions = segments.next().?;
    while (segments.next()) |position| {
        var positionInner = std.mem.tokenizeScalar(u8, position, '=');
        const key = positionInner.next().?[0..3];
        const valueString = positionInner.next().?;
        var leftRightValues = std.mem.tokenizeScalar(u8, valueString, ',');
        const leftValue = leftRightValues.next().?[2..];
        var rightValue = leftRightValues.next().?;
        rightValue = rightValue[1 .. rightValue.len - 1];
        try positions.put(key, [2][]const u8{ leftValue, rightValue });
    }

    var positionList = std.ArrayList([]const u8).init(allocator.*);
    defer positionList.deinit();
    var positionIterator = positions.iterator();
    while (positionIterator.next()) |entry| {
        const position = entry.key_ptr.*;
        if (std.mem.endsWith(u8, position, "A")) {
            try positionList.append(position);
        }
    }

    var positionResults = try std.ArrayList(usize).initCapacity(allocator.*, positionList.items.len);
    defer positionResults.deinit();
    for (positionList.items) |position| {
        const currentDirections = directions;
        var currentPosition = position;
        var result: usize = 0;
        var directionPos: usize = 0;
        const directionsCount = currentDirections.len;
        while (!std.mem.endsWith(u8, currentPosition, "Z")) {
            const value = positions.get(currentPosition).?;
            var nextKey: []const u8 = undefined;
            if (currentDirections[directionPos % directionsCount] == 'L') {
                nextKey = value[0];
            } else {
                nextKey = value[1];
            }
            directionPos += 1;
            currentPosition = nextKey;
            result += 1;
        }
        positionResults.appendAssumeCapacity(result);
    }

    var lcm: usize = positionResults.pop();
    while (positionResults.popOrNull()) |result| {
        lcm *= result / std.math.gcd(lcm, result);
    }

    return lcm;
}

test "test-input" {
    var allocator = std.testing.allocator;
    const fileContentPart1 = @embedFile("test1.txt");
    const fileContentPart2 = @embedFile("test2.txt");

    const part1 = try solvePart1(fileContentPart1, &allocator);
    const part2 = try solvePart2(fileContentPart2, &allocator);

    try std.testing.expectEqual(part1, 6);
    try std.testing.expectEqual(part2, 6);
}
