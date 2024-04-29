const std = @import("std");

pub fn main() !void {
    var gpa = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer gpa.deinit();
    var allocator = gpa.allocator();
    const fileContent = @embedFile("input.txt");

    var timer = try std.time.Timer.start();
    const part1 = try solvePart1(fileContent);
    const part2 = try solvePart2(fileContent, &allocator);

    std.debug.print("Part1: {d}\nPart2: {d}\nTime: {d}us\n", .{ part1, part2, timer.lap() / std.time.ns_per_us });
}

fn getIntersections(input: []const u8) !usize {
    const bitSet = std.bit_set.StaticBitSet(100);
    var gameCards = std.mem.tokenizeScalar(u8, input, '|');
    const deck = gameCards.next().?;
    const hand = gameCards.next().?;
    var deckSplit = std.mem.tokenizeScalar(u8, deck, ' ');
    var handSplit = std.mem.tokenizeScalar(u8, hand, ' ');
    var deckBag = bitSet.initEmpty();
    var handBag = bitSet.initEmpty();
    while (deckSplit.next()) |deckCard| {
        const deckCardValue = try std.fmt.parseInt(usize, deckCard, 10);
        deckBag.set(deckCardValue);
    }
    while (handSplit.next()) |handCard| {
        const handCardValue = try std.fmt.parseInt(usize, handCard, 10);
        handBag.set(handCardValue);
    }
    const intersection = deckBag.intersectWith(handBag);
    return intersection.count();
}

fn solvePart1(input: []const u8) !usize {
    var result: usize = 0;
    var lines = std.mem.tokenizeScalar(u8, input, '\n');
    while (lines.next()) |line| {
        var game = std.mem.tokenizeScalar(u8, line, ':');
        _ = game.next();
        const gameSet = game.next().?;
        const intersections = try getIntersections(gameSet);
        if (intersections > 0) {
            result += std.math.pow(usize, 2, intersections - 1);
        }
    }

    return result;
}

fn solvePart2(input: []const u8, allocator: *std.mem.Allocator) !usize {
    var bucket = std.AutoHashMap(usize, usize).init(allocator.*);
    defer bucket.deinit();

    var index: usize = 0;
    var lines = std.mem.tokenizeAny(u8, input, "\n");
    while (lines.next()) |line| : (index += 1) {
        const entry = try bucket.getOrPut(index);
        if (!entry.found_existing) {
            entry.value_ptr.* = 1;
        } else {
            entry.value_ptr.* += 1;
        }

        var game = std.mem.tokenizeAny(u8, line, ":");
        _ = game.next();
        const gameSet = game.next().?;
        const intersections = try getIntersections(gameSet);
        for (intersections, 0..) |_, intersectionIndex| {
            const newIndex = index + 1 + intersectionIndex;
            // Always there, because we insert it at the beginning of the loop
            const indexValue = bucket.get(index).?;
            const newEntry = try bucket.getOrPut(newIndex);
            if (!newEntry.found_existing) {
                newEntry.value_ptr.* = indexValue;
            } else {
                newEntry.value_ptr.* += indexValue;
            }
        }
    }
    var result: usize = 0;
    var bucketIterator = bucket.valueIterator();
    while (bucketIterator.next()) |bucketValue| {
        result += bucketValue.*;
    }
    return result;
}

test "test-input" {
    var allocator = std.testing.allocator;
    const fileContent = @embedFile("test.txt");

    const part1 = try solvePart1(fileContent);
    const part2 = try solvePart2(fileContent, &allocator);

    try std.testing.expectEqual(part1, 13);
    try std.testing.expectEqual(part2, 30);
}
