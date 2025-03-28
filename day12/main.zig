const std = @import("std");

pub fn main() !void {
    var gpa = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer gpa.deinit();
    var allocator = gpa.allocator();
    const fileContent = @embedFile("input.txt");

    var timer = try std.time.Timer.start();
    const part1 = try solvePart1(fileContent, &allocator);
    const part2 = try solvePart2(fileContent, &allocator);
    std.debug.print("Part1: {d}\nPart2: {d}\nTime: {d}ms\n", .{ part1, part2, timer.lap() / std.time.ns_per_ms });

    const part1Alt = try solvePart1Alt(fileContent, &allocator);
    const part2Alt = try solvePart2Alt(fileContent, &allocator);
    std.debug.print("ALT:\nPart1: {d}\nPart2: {d}\nTime: {d}ms\n", .{ part1Alt, part2Alt, timer.lap() / std.time.ns_per_ms });
}

const CacheKey = struct {
    firstChar: u8,
    configurationSize: u8,
    numberSize: u8,
};

var cache: std.AutoHashMap(CacheKey, usize) = undefined;

var cacheArray: [][]?usize = undefined;

inline fn contains(haystack: []const u8, needle: u8) bool {
    if (std.mem.indexOfScalar(u8, haystack, needle)) |_| {
        return true;
    }
    return false;
}

fn count(configuration: []const u8, numbers: []u8) !usize {
    if (configuration.len == 0) {
        if (numbers.len == 0) {
            return 1;
        }
        return 0;
    }
    if (numbers.len == 0) {
        if (contains(configuration, '#')) {
            return 0;
        }
        return 1;
    }

    var result: usize = 0;
    const firstCharConfig = configuration[0];
    const firstNumber = numbers[0];

    const key = CacheKey{
        .firstChar = firstCharConfig,
        .configurationSize = @intCast(configuration.len),
        .numberSize = @intCast(numbers.len),
    };

    if (cache.get(key)) |entry| {
        return entry;
    }

    if (firstCharConfig == '.' or firstCharConfig == '?') {
        result += try count(configuration[1..], numbers);
    }

    if (firstCharConfig == '#' or firstCharConfig == '?') {
        if (firstNumber <= configuration.len and
            !contains(configuration[0..firstNumber], '.') and
            (firstNumber == configuration.len or configuration[firstNumber] != '#'))
        {
            if (firstNumber == configuration.len) {
                result += try count(configuration[firstNumber..], numbers[1..]);
            } else {
                result += try count(configuration[firstNumber + 1 ..], numbers[1..]);
            }
        }
    }
    try cache.put(key, result);

    return result;
}

inline fn solve(input: []const u8, allocator: *std.mem.Allocator, comptime expand: bool) !usize {
    var result: usize = 0;

    var lines = std.mem.tokenizeScalar(u8, input, '\n');
    while (lines.next()) |line| {
        var numbers = try std.ArrayList(u8).initCapacity(allocator.*, 6);
        defer numbers.deinit();
        var segments = std.mem.tokenizeScalar(u8, line, ' ');
        const configuration = segments.next().?;
        const numberSegment = segments.next().?;
        var numbersString = std.mem.tokenizeScalar(u8, numberSegment, ',');
        while (numbersString.next()) |numberString| {
            const number = try std.fmt.parseInt(u8, numberString, 10);
            numbers.appendAssumeCapacity(number);
        }

        cache = std.AutoHashMap(CacheKey, usize).init(allocator.*);
        defer cache.deinit();

        if (!expand) {
            const numberSlice = try numbers.toOwnedSlice();
            defer allocator.free(numberSlice);

            result += try count(configuration, numberSlice);
        } else {
            var expNumbers = try std.ArrayList(u8).initCapacity(allocator.*, 30);
            defer expNumbers.deinit();

            var expConfigBuffer = try std.RingBuffer.init(allocator.*, configuration.len * 5 + 4);
            defer expConfigBuffer.deinit(allocator.*);

            for (0..5) |index| {
                expNumbers.appendSliceAssumeCapacity(numbers.items);

                try expConfigBuffer.writeSlice(configuration);
                if (index < 4) {
                    try expConfigBuffer.write('?');
                }
            }
            const numberSlice = try expNumbers.toOwnedSlice();
            defer allocator.free(numberSlice);

            result += try count(expConfigBuffer.data, numberSlice);
        }
    }
    return result;
}

fn solvePart1(input: []const u8, allocator: *std.mem.Allocator) !usize {
    return try solve(input, allocator, false);
}

fn solvePart2(input: []const u8, allocator: *std.mem.Allocator) !usize {
    return try solve(input, allocator, true);
}

fn countAlt(configuration: []const u8, numbers: *[]u8, start: u8, end: u8) usize {
    if (start == configuration.len) {
        if (end == numbers.len) {
            return 1;
        } else {
            return 0;
        }
    }

    if (cacheArray[start][end]) |entry| {
        return entry;
    }

    const charToCheck = configuration[start];

    const result = switch (charToCheck) {
        '.' => countAlt(configuration, numbers, start + 1, end),
        '#' => countBroken(configuration, numbers, start, end),
        '?' => countAlt(configuration, numbers, start + 1, end) + countBroken(configuration, numbers, start, end),
        else => unreachable,
    };

    cacheArray[start][end] = result;

    return result;
}

fn countBroken(configuration: []const u8, numbers: *[]u8, start: u8, end: u8) usize {
    if (end == numbers.len) {
        return 0;
    }
    const endIndex = start + numbers.*[end];

    if (!brokenPossible(configuration, start, endIndex)) {
        return 0;
    }

    if (endIndex == configuration.len) {
        if (end == numbers.len - 1) {
            return 1;
        } else {
            return 0;
        }
    }

    return countAlt(configuration, numbers, endIndex + 1, end + 1);
}

fn brokenPossible(configuration: []const u8, start: u8, end: u8) bool {
    const configSize = configuration.len;

    if (end > configSize) {
        return false;
    }

    if (end == configSize) {
        for (configuration[start..end]) |item| {
            if (item == '.') {
                return false;
            }
        }
        return true;
    }

    if (end < configSize) {
        for (configuration[start..end]) |item| {
            if (item == '.') {
                return false;
            }
        }
        return if (configuration[end] != '#') true else false;
    }

    // SAFETY: All cases are covered above
    unreachable;
}

fn initCacheArray(outer: usize, inner: usize, allocator: *std.mem.Allocator) !void {
    var cacheList = try std.ArrayList([]?usize).initCapacity(allocator.*, outer);
    for (0..outer) |_| {
        var temp = try std.ArrayList(?usize).initCapacity(allocator.*, inner);
        for (0..inner) |_| {
            temp.appendAssumeCapacity(null);
        }
        const tempSlice = try temp.toOwnedSlice();
        cacheList.appendAssumeCapacity(tempSlice);
    }

    cacheArray = try cacheList.toOwnedSlice();
}

fn solveAlt(input: []const u8, allocator: *std.mem.Allocator, comptime expand: bool) !usize {
    var result: usize = 0;

    var lines = std.mem.tokenizeScalar(u8, input, '\n');
    while (lines.next()) |line| {
        var numbers = try std.ArrayList(u8).initCapacity(allocator.*, 6);
        defer numbers.deinit();
        var segments = std.mem.tokenizeScalar(u8, line, ' ');
        const configuration = segments.next().?;
        const numberSegment = segments.next().?;
        var numbersString = std.mem.tokenizeScalar(u8, numberSegment, ',');
        while (numbersString.next()) |numberString| {
            const number = try std.fmt.parseInt(u8, numberString, 10);
            numbers.appendAssumeCapacity(number);
        }

        if (!expand) {
            var numberSlice = try numbers.toOwnedSlice();
            defer allocator.free(numberSlice);

            try initCacheArray(configuration.len, numberSlice.len + 1, allocator);

            result += countAlt(configuration, &numberSlice, 0, 0);
        } else {
            var expNumbers = try std.ArrayList(u8).initCapacity(allocator.*, 30);
            defer expNumbers.deinit();

            var expConfigBuffer = try std.RingBuffer.init(allocator.*, configuration.len * 5 + 4);
            defer expConfigBuffer.deinit(allocator.*);
            for (0..5) |index| {
                expNumbers.appendSliceAssumeCapacity(numbers.items);

                try expConfigBuffer.writeSlice(configuration);
                if (index < 4) {
                    try expConfigBuffer.write('?');
                }
            }
            var numberSlice = try expNumbers.toOwnedSlice();
            defer allocator.free(numberSlice);

            try initCacheArray(expConfigBuffer.data.len, numberSlice.len + 1, allocator);

            result += countAlt(expConfigBuffer.data, &numberSlice, 0, 0);
        }
    }
    allocator.free(cacheArray);
    return result;
}

fn solvePart1Alt(input: []const u8, allocator: *std.mem.Allocator) !usize {
    return try solveAlt(input, allocator, false);
}

fn solvePart2Alt(input: []const u8, allocator: *std.mem.Allocator) !usize {
    return try solveAlt(input, allocator, true);
}

test "test-input" {
    var allocator = std.testing.allocator;
    const fileContent = @embedFile("test.txt");

    const part1 = try solvePart1(fileContent, &allocator);
    const part2 = try solvePart2(fileContent, &allocator);
    const part1Alt = try solvePart1(fileContent, &allocator);
    const part2Alt = try solvePart2(fileContent, &allocator);

    try std.testing.expectEqual(part1, 21);
    try std.testing.expectEqual(part1, part1Alt);
    try std.testing.expectEqual(part2, 525152);
    try std.testing.expectEqual(part2, part2Alt);
}
