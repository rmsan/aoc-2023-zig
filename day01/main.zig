const std = @import("std");

pub fn main() !void {
    const fileContent = @embedFile("input.txt");
    var lines = std.mem.tokenizeAny(u8, fileContent, "\n");

    var part1: usize = 0;
    var part2: usize = 0;
    while (lines.next()) |line| {
        part1 += try solvePart1(line);
        part2 += try solvePart2(line);
    }

    std.debug.print("Part1: {d}\nPart2: {d}\n", .{ part1, part2 });
}

fn solvePart1(input: []const u8) !usize {
    var firstDigit: usize = 0;
    var lastDigit: usize = 0;
    for (input) |char| {
        if (!std.ascii.isDigit(char)) {
            continue;
        }
        const digit = char - '0';
        if (firstDigit == 0) {
            firstDigit = digit;
        }
        lastDigit = digit;
    }

    return 10 * firstDigit + lastDigit;
}

const NUMBERS = [_][]const u8{ "one", "two", "three", "four", "five", "six", "seven", "eight", "nine" };

fn solvePart2(input: []const u8) !usize {
    var firstDigit: usize = 0;
    var lastDigit: usize = 0;
    for (input, 0..) |char, i| {
        var digit: ?usize = null;
        if (!std.ascii.isDigit(char)) {
            for (NUMBERS, 1..) |numberChar, j| {
                // std.ascii.startsWithIgnoreCase also possible
                if (std.mem.startsWith(u8, input[i..], numberChar)) {
                    digit = j;
                }
            }
        } else {
            digit = char - '0';
        }

        if (digit) |realDigit| {
            if (firstDigit == 0) {
                firstDigit = realDigit;
            }
            lastDigit = realDigit;
        }
    }

    return 10 * firstDigit + lastDigit;
}

test "test-input" {
    const fileContentTest1 = @embedFile("test1.txt");
    var lines1 = std.mem.tokenizeAny(u8, fileContentTest1, "\n");
    var part1: usize = 0;
    while (lines1.next()) |line| {
        part1 += try solvePart1(line);
    }

    const fileContentTest2 = @embedFile("test2.txt");
    var lines2 = std.mem.tokenizeAny(u8, fileContentTest2, "\n");
    var part2: usize = 0;
    while (lines2.next()) |line| {
        part2 += try solvePart2(line);
    }

    try std.testing.expectEqual(part1, 142);
    try std.testing.expectEqual(part2, 281);
}
