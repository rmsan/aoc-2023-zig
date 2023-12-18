const std = @import("std");

pub fn main() !void {
    const fileContent = @embedFile("input.txt");

    var timer = try std.time.Timer.start();
    const part1 = try solvePart1(fileContent);
    const part2 = try solvePart2(fileContent);

    std.debug.print("Part1: {d}\nPart2: {d}\nTime: {d}us\n", .{ part1, part2, timer.lap() / std.time.ns_per_us });
}

fn solvePart1(input: []const u8) !usize {
    var result: usize = 0;
    var lines = std.mem.tokenizeScalar(u8, input, '\n');
    while (lines.next()) |line| {
        var firstDigit: usize = 0;
        var lastDigit: usize = 0;
        for (line) |char| {
            if (!std.ascii.isDigit(char)) {
                continue;
            }
            const digit = char - '0';
            if (firstDigit == 0) {
                firstDigit = digit;
            }
            lastDigit = digit;
        }

        result += 10 * firstDigit + lastDigit;
    }
    return result;
}

const NUMBERS = [_][]const u8{ "one", "two", "three", "four", "five", "six", "seven", "eight", "nine" };

fn solvePart2(input: []const u8) !usize {
    var result: usize = 0;
    var lines = std.mem.tokenizeScalar(u8, input, '\n');
    while (lines.next()) |line| {
        var firstDigit: usize = 0;
        var lastDigit: usize = 0;
        for (line, 0..) |char, charIndex| {
            var digit: ?usize = null;
            if (!std.ascii.isDigit(char)) {
                for (NUMBERS, 1..) |numberChar, numberIndex| {
                    if (std.mem.startsWith(u8, line[charIndex..], numberChar)) {
                        digit = numberIndex;
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

        result += 10 * firstDigit + lastDigit;
    }

    return result;
}

test "test-input" {
    const fileContentTest1 = @embedFile("test1.txt");
    const fileContentTest2 = @embedFile("test2.txt");

    const part1 = try solvePart1(fileContentTest1);
    const part2 = try solvePart2(fileContentTest2);

    try std.testing.expectEqual(part1, 142);
    try std.testing.expectEqual(part2, 281);
}
