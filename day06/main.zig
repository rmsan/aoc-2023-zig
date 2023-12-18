const std = @import("std");

pub fn main() !void {
    var gpa = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer gpa.deinit();
    var allocator = gpa.allocator();
    const fileContent = @embedFile("input.txt");

    var timer = try std.time.Timer.start();
    const part1 = try solvePart1(fileContent, &allocator);
    const part2 = try solvePart2_binarySearch(fileContent, &allocator);

    std.debug.print("Part1: {d}\nPart2: {d}\nTime: {d}us\n", .{ part1, part2, timer.lap() / std.time.ns_per_us });
}

fn getTimeAndDistanceSlices(input: []const u8, allocator: *std.mem.Allocator) ![2][]usize {
    var segements = std.mem.tokenizeScalar(u8, input, '\n');

    var timeSegment = segements.next().?;
    var timeSegmentInner = std.mem.tokenizeScalar(u8, timeSegment, ':');
    _ = timeSegmentInner.next();
    var timeList = try std.ArrayList(usize).initCapacity(allocator.*, 4);
    var timeStrings = std.mem.tokenizeScalar(u8, timeSegmentInner.next().?, ' ');
    while (timeStrings.next()) |timeString| {
        var time = try std.fmt.parseInt(usize, timeString, 10);
        timeList.appendAssumeCapacity(time);
    }

    var distanceSegment = segements.next().?;
    var distanceSegmentInner = std.mem.tokenizeScalar(u8, distanceSegment, ':');
    _ = distanceSegmentInner.next();
    var distanceList = try std.ArrayList(usize).initCapacity(allocator.*, 4);
    var distanceStrings = std.mem.tokenizeScalar(u8, distanceSegmentInner.next().?, ' ');
    while (distanceStrings.next()) |distanceString| {
        var distance = try std.fmt.parseInt(usize, distanceString, 10);
        distanceList.appendAssumeCapacity(distance);
    }

    const times = try timeList.toOwnedSlice();
    const distances = try distanceList.toOwnedSlice();

    return .{ times, distances };
}

fn solvePart1(input: []const u8, allocator: *std.mem.Allocator) !usize {
    const timesAndDistances = try getTimeAndDistanceSlices(input, allocator);
    const times = timesAndDistances[0];
    const distances = timesAndDistances[1];
    defer allocator.free(times);
    defer allocator.free(distances);

    var result: usize = 1;
    for (times, 0..) |time, index| {
        var countDistances: usize = 0;
        const distance = distances[index];
        for (1..time) |nextTime| {
            const dx = nextTime * (time - nextTime);
            if (dx > distance) {
                countDistances += 1;
            }
        }
        result *= countDistances;
    }

    return result;
}

fn getTimeAndDistance(input: []const u8, allocator: *std.mem.Allocator) ![2]usize {
    var segements = std.mem.tokenizeScalar(u8, input, '\n');

    var timeSegment = segements.next().?;
    var timeSegmentInner = std.mem.tokenizeScalar(u8, timeSegment, ':');
    _ = timeSegmentInner.next();
    const timeStringSegment = timeSegmentInner.next().?;
    var timeStrings = std.mem.tokenizeScalar(u8, timeStringSegment, ' ');
    var timeBuffer = try std.RingBuffer.init(allocator.*, timeStringSegment.len);
    defer timeBuffer.deinit(allocator.*);
    while (timeStrings.next()) |timeString| {
        try timeBuffer.writeSlice(timeString);
    }

    var distanceSegment = segements.next().?;
    var distanceSegmentInner = std.mem.tokenizeScalar(u8, distanceSegment, ':');
    _ = distanceSegmentInner.next();
    const distanceStringSegment = distanceSegmentInner.next().?;
    var distanceStrings = std.mem.tokenizeScalar(u8, distanceStringSegment, ' ');
    var distanceBuffer = try std.RingBuffer.init(allocator.*, distanceStringSegment.len);
    defer distanceBuffer.deinit(allocator.*);
    while (distanceStrings.next()) |distanceString| {
        try distanceBuffer.writeSlice(distanceString);
    }

    const time = try std.fmt.parseInt(usize, timeBuffer.data[0..timeBuffer.len()], 10);
    const distance = try std.fmt.parseInt(usize, distanceBuffer.data[0..distanceBuffer.len()], 10);

    return .{ time, distance };
}

fn solvePart2_linearSearch(input: []const u8, allocator: *std.mem.Allocator) !usize {
    const timeAndDistance = try getTimeAndDistance(input, allocator);
    const time = timeAndDistance[0];
    const distance = timeAndDistance[1];

    var result: usize = 1;
    var countDistances: usize = 0;
    for (1..time) |nextTime| {
        const dx = nextTime * (time - nextTime);
        if (dx > distance) {
            countDistances += 1;
        }
    }
    result *= countDistances;
    return result;
}

fn solvePart2_binarySearch(input: []const u8, allocator: *std.mem.Allocator) !usize {
    const timeAndDistance = try getTimeAndDistance(input, allocator);
    const time = timeAndDistance[0];
    const distance = timeAndDistance[1];

    var result: usize = 0;
    var low: usize = 0;
    var high: usize = time / 2;

    while (low + 1 < high) {
        const middle = low + (high - low) / 2;
        if (middle * (time - middle) >= distance) {
            high = middle;
        } else {
            low = middle;
        }
    }
    const first = high;
    const last = (time / 2) + (time / 2 - first);
    result = last - first + 1;
    return result;
}

test "test-input" {
    var allocator = std.testing.allocator;
    const fileContent = @embedFile("test.txt");

    const part1 = try solvePart1(fileContent, &allocator);
    const part2Linear = try solvePart2_linearSearch(fileContent, &allocator);
    const part2Binary = try solvePart2_binarySearch(fileContent, &allocator);

    try std.testing.expectEqual(part1, 288);
    try std.testing.expectEqual(part2Binary, 71503);
    try std.testing.expectEqual(part2Binary, part2Linear);
}
