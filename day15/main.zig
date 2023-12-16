const std = @import("std");

pub fn main() !void {
    var gpa = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer gpa.deinit();
    var allocator = gpa.allocator();
    const fileContent = @embedFile("input.txt");

    var timer = try std.time.Timer.start();
    var part1 = try solvePart1(fileContent);
    var part2 = try solvePart2(fileContent, &allocator);

    std.debug.print("Part1: {d}\nPart2: {d}\nTime: {d}us\n", .{ part1, part2, timer.lap() / std.time.ns_per_us });
}

inline fn hash(string: []const u8) usize {
    var hashValue: usize = 0;
    for (string) |char| {
        hashValue += char - 0x00;
        hashValue *= 17;
        hashValue %= 256;
    }
    return hashValue;
}

fn solvePart1(input: []const u8) !usize {
    var result: usize = 0;
    var strings = std.mem.tokenizeScalar(u8, input, ',');
    while (strings.next()) |string| {
        result += hash(string);
    }
    return result;
}

fn solvePart2(input: []const u8, allocator: *std.mem.Allocator) !usize {
    var result: usize = 0;
    var lensMap = std.StringHashMap(usize).init(allocator.*);
    defer lensMap.deinit();
    var boxes = try std.ArrayList(std.ArrayList([]const u8)).initCapacity(allocator.*, 256);
    defer boxes.deinit();
    for (0..256) |_| {
        try boxes.append(std.ArrayList([]const u8).init(allocator.*));
    }
    var strings = std.mem.tokenizeScalar(u8, input, ',');
    while (strings.next()) |string| {
        if (std.mem.indexOfScalar(u8, string, '-')) |_| {
            const label = string[0 .. string.len - 1];
            const index = hash(label);
            for (boxes.items[index].items, 0..) |item, innerIndex| {
                if (std.mem.eql(u8, item, label)) {
                    _ = boxes.items[index].orderedRemove(innerIndex);
                }
            }
        } else {
            var split = std.mem.splitScalar(u8, string, '=');
            const label = split.next().?;
            const index = hash(label);
            const lengthString = split.next().?;
            const length = try std.fmt.parseInt(usize, lengthString, 10);
            try lensMap.put(label, length);
            if (boxes.items[index].items.len == 0) {
                try boxes.items[index].append(label);
                continue;
            }
            var found = false;
            for (boxes.items[index].items) |item| {
                if (!found and std.mem.eql(u8, item, label)) {
                    found = true;
                }
            }
            if (!found) {
                try boxes.items[index].append(label);
            }
        }
    }
    for (boxes.items, 0..) |box, boxIndex| {
        defer box.deinit();
        for (box.items, 0..) |label, lensIndex| {
            result += (boxIndex + 1) * (lensIndex + 1) * lensMap.get(label).?;
        }
    }

    return result;
}

test "test-input" {
    var allocator = std.testing.allocator;
    const fileContent = @embedFile("test.txt");

    var part1 = try solvePart1(fileContent);
    var part2 = try solvePart2(fileContent, &allocator);

    try std.testing.expectEqual(part1, 1320);
    try std.testing.expectEqual(part2, 145);
}
