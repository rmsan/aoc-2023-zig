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

fn solvePart1(input: []const u8, allocator: *std.mem.Allocator) !usize {
    var segments = std.mem.tokenizeSequence(u8, input, "\n\n");
    var seedsList = std.ArrayList(usize).init(allocator.*);
    const seedSegment = segments.next().?;
    var seedSplit = std.mem.splitScalar(u8, seedSegment, ':');
    _ = seedSplit.next().?;
    var seedIterator = std.mem.tokenizeScalar(u8, seedSplit.next().?, ' ');
    while (seedIterator.next()) |seedString| {
        const seed = try std.fmt.parseInt(usize, seedString, 10);
        try seedsList.append(seed);
    }

    var seeds = try seedsList.toOwnedSlice();
    while (segments.next()) |segment| {
        var rangeList = std.ArrayList([3]usize).init(allocator.*);
        var segmentIterator = std.mem.tokenizeAny(u8, segment, "\n");
        _ = segmentIterator.next().?;
        while (segmentIterator.next()) |segmentString| {
            var positionIterator = std.mem.tokenizeScalar(u8, segmentString, ' ');
            const destinationStart = try std.fmt.parseInt(usize, positionIterator.next().?, 10);
            const sourceStart = try std.fmt.parseInt(usize, positionIterator.next().?, 10);
            const range = try std.fmt.parseInt(usize, positionIterator.next().?, 10);
            try rangeList.append([3]usize{ destinationStart, sourceStart, range });
        }
        var seedList = std.ArrayList(usize).init(allocator.*);
        for (seeds) |seed| {
            for (rangeList.items) |range| {
                const dest = range[0];
                const src = range[1];
                const len = range[2];
                if (src <= seed and seed < src + len) {
                    try seedList.append(seed - src + dest);
                    break;
                }
            } else {
                try seedList.append(seed);
            }
        }
        seeds = try seedList.toOwnedSlice();
    }

    return std.mem.min(usize, seeds);
}

fn solvePart2(input: []const u8, allocator: *std.mem.Allocator) !usize {
    var segments = std.mem.tokenizeSequence(u8, input, "\n\n");
    var seedRangeList = std.ArrayList(usize).init(allocator.*);
    const seedSegment = segments.next().?;
    var seedSplit = std.mem.splitScalar(u8, seedSegment, ':');
    _ = seedSplit.next().?;
    var seedIterator = std.mem.tokenizeScalar(u8, seedSplit.next().?, ' ');
    while (seedIterator.next()) |seedString| {
        const seed = try std.fmt.parseInt(usize, seedString, 10);
        try seedRangeList.append(seed);
    }

    var seedRanges = try seedRangeList.toOwnedSlice();
    var seedWindows = std.mem.window(usize, seedRanges, 2, 2);
    var seedsList = std.ArrayList([2]usize).init(allocator.*);
    while (seedWindows.next()) |seedWindow| {
        try seedsList.append([2]usize{ seedWindow[0], seedWindow[0] + seedWindow[1] });
    }
    while (segments.next()) |segment| {
        var rangeList = std.ArrayList([3]usize).init(allocator.*);
        var segmentIterator = std.mem.tokenizeAny(u8, segment, "\n");
        _ = segmentIterator.next().?;
        while (segmentIterator.next()) |segmentString| {
            var positionIterator = std.mem.tokenizeScalar(u8, segmentString, ' ');
            const destinationStart = try std.fmt.parseInt(usize, positionIterator.next().?, 10);
            const sourceStart = try std.fmt.parseInt(usize, positionIterator.next().?, 10);
            const range = try std.fmt.parseInt(usize, positionIterator.next().?, 10);
            try rangeList.append([3]usize{ destinationStart, sourceStart, range });
        }
        var seedList = std.ArrayList([2]usize).init(allocator.*);
        while (seedsList.popOrNull()) |seed| {
            const seedStart = seed[0];
            const seedEnd = seed[1];
            for (rangeList.items) |range| {
                const dest = range[0];
                const src = range[1];
                const len = range[2];
                const overlapStart = @max(seedStart, src);
                const overlapEnd = @min(seedEnd, src + len);
                if (overlapStart < overlapEnd) {
                    try seedList.append([2]usize{ overlapStart - src + dest, overlapEnd - src + dest });
                    if (overlapStart > seedStart) {
                        try seedsList.append([2]usize{ seedStart, overlapStart });
                    }
                    if (seedEnd > overlapEnd) {
                        try seedsList.append([2]usize{ overlapEnd, seedEnd });
                    }
                    break;
                }
            } else {
                try seedList.append([2]usize{ seedStart, seedEnd });
            }
        }
        seedsList = seedList;
    }
    var result: usize = std.math.maxInt(usize);
    for (seedsList.items) |seed| {
        result = @min(result, seed[0]);
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

    try std.testing.expectEqual(part1, 35);
    try std.testing.expectEqual(part2, 46);
}
