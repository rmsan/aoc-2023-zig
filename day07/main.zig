const std = @import("std");

pub fn main() !void {
    var gpa = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer gpa.deinit();
    var allocator = gpa.allocator();
    const fileContent = @embedFile("input.txt");

    var timer = try std.time.Timer.start();
    var part1 = try solvePart1(fileContent, &allocator);
    var part2 = try solvePart2(fileContent, &allocator);

    std.debug.print("Part1: {d}\nPart2: {d}\nTime: {d}us\n", .{ part1, part2, timer.lap() / std.time.ns_per_us });
}

const CardValue = enum(u8) { A = 14, K = 13, Q = 12, J = 11, T = 10, J_ALT = 1 };

const HandType = enum(u3) { FIVE_OF_A_KIND = 6, FOUR_OF_A_KIND = 5, FULL_HOUSE = 4, THREE_OF_A_KIND = 3, TWO_PAIR = 2, ONE_PAIR = 1, HIGH_HAND = 0 };

const HandWithBid = struct { hand: []const u8, handType: HandType, bid: usize };

fn cmpHand(context: void, a: u8, b: u8) bool {
    _ = context;
    return (a > b);
}

fn cmpHandWithBidInner(context: void, a: HandWithBid, b: HandWithBid, comptime alt: bool) std.math.Order {
    _ = context;
    const firstOrder = std.math.order(@intFromEnum(a.handType), @intFromEnum(b.handType));
    if (firstOrder.compare(.eq)) {
        for (a.hand, 0..) |leftHandOrig, index| {
            var leftHand = leftHandOrig;
            var rightHand = b.hand[index];
            if (!std.ascii.isDigit(leftHand)) {
                leftHand = @intFromEnum(handCharToCardValue(leftHand, alt)) + '0';
            }
            if (!std.ascii.isDigit(rightHand)) {
                rightHand = @intFromEnum(handCharToCardValue(rightHand, alt)) + '0';
            }
            if (leftHand == rightHand) {
                continue;
            }
            return std.math.order(leftHand, rightHand);
        }
    }
    return firstOrder;
}

fn cmpHandWithBid(context: void, a: HandWithBid, b: HandWithBid) std.math.Order {
    return cmpHandWithBidInner(context, a, b, false);
}

fn cmpHandWithBidAlt(context: void, a: HandWithBid, b: HandWithBid) std.math.Order {
    return cmpHandWithBidInner(context, a, b, true);
}

inline fn handCharToCardValue(handChar: u8, comptime alt: bool) CardValue {
    return switch (handChar) {
        'A' => CardValue.A,
        'K' => CardValue.K,
        'Q' => CardValue.Q,
        'J' => {
            if (alt) {
                return CardValue.J_ALT;
            } else {
                return CardValue.J;
            }
        },
        'T' => CardValue.T,
        else => unreachable,
    };
}

inline fn getHandWithBid(handString: []const u8, bid: usize, hand: [14]u8) HandWithBid {
    var handCount: u8 = 0;
    for (hand) |handValue| {
        if (handValue > 0) {
            handCount += handValue;
        }
    }
    var value = hand[0];
    const toConsider = hand[1];
    const missing: u8 = 5 - handCount;
    if (missing > 0) {
        value += missing;
    }

    return switch (value) {
        5 => .{ .hand = handString, .bid = bid, .handType = HandType.FIVE_OF_A_KIND },
        4 => .{ .hand = handString, .bid = bid, .handType = HandType.FOUR_OF_A_KIND },
        3 => blk: {
            if (toConsider == 2) {
                break :blk .{ .hand = handString, .bid = bid, .handType = HandType.FULL_HOUSE };
            } else {
                break :blk .{ .hand = handString, .bid = bid, .handType = HandType.THREE_OF_A_KIND };
            }
        },
        2 => blk: {
            if (toConsider == 2) {
                break :blk .{ .hand = handString, .bid = bid, .handType = HandType.TWO_PAIR };
            } else {
                break :blk .{ .hand = handString, .bid = bid, .handType = HandType.ONE_PAIR };
            }
        },
        1 => .{ .hand = handString, .bid = bid, .handType = HandType.HIGH_HAND },
        else => unreachable,
    };
}

fn solve(input: []const u8, allocator: *std.mem.Allocator, comptime part2: bool, comptime compareFn: fn (context: void, a: HandWithBid, b: HandWithBid) std.math.Order) !usize {
    var lines = std.mem.tokenizeScalar(u8, input, '\n');
    var maxHeap = std.PriorityQueue(HandWithBid, void, compareFn).init(allocator.*, {});
    defer maxHeap.deinit();
    while (lines.next()) |line| {
        var hand: [14]u8 = [_]u8{0x00} ** 14;
        var handLine = std.mem.tokenizeScalar(u8, line, ' ');
        const handString = handLine.next().?;
        const bidString = handLine.next().?;
        const bid = try std.fmt.parseInt(usize, bidString, 10);
        for (handString) |handChar| {
            if (std.ascii.isDigit(handChar)) {
                const number = handChar - '0';
                hand[number - 1] += 1;
            } else {
                if (handChar == 'J' and part2) {
                    continue;
                }
                const cardValue = handCharToCardValue(handChar, part2);
                hand[@intFromEnum(cardValue) - 1] += 1;
            }
        }
        std.mem.sort(u8, &hand, {}, cmpHand);
        var handWithBid = getHandWithBid(handString, bid, hand);
        try maxHeap.add(handWithBid);
    }

    var result: usize = 0;
    var index: usize = 0;
    while (maxHeap.removeOrNull()) |item| {
        result += (index + 1) * item.bid;
        index += 1;
    }

    return result;
}

fn solvePart1(input: []const u8, allocator: *std.mem.Allocator) !usize {
    return solve(input, allocator, false, cmpHandWithBid);
}

fn solvePart2(input: []const u8, allocator: *std.mem.Allocator) !usize {
    return solve(input, allocator, true, cmpHandWithBidAlt);
}

test "test-input" {
    var allocator = std.testing.allocator;
    const fileContent = @embedFile("test.txt");

    var part1 = try solvePart1(fileContent, &allocator);
    var part2 = try solvePart2(fileContent, &allocator);

    try std.testing.expectEqual(part1, 6440);
    try std.testing.expectEqual(part2, 5905);
}
