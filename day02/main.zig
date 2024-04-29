const std = @import("std");

const Colors = struct { red: usize, blue: usize, green: usize };

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
        var gameInput = std.mem.splitScalar(u8, line, ':');
        var gameIdString = gameInput.next().?;
        const gameId = try std.fmt.parseInt(usize, gameIdString[5..], 10);
        const gameString = gameInput.next().?;

        const colors = try getColors(gameString);
        const red = colors.red;
        const blue = colors.blue;
        const green = colors.green;

        if (red <= 12 and green <= 13 and blue <= 14) {
            result += gameId;
        }
    }

    return result;
}

fn solvePart2(input: []const u8) !usize {
    var result: usize = 0;
    var lines = std.mem.tokenizeScalar(u8, input, '\n');
    while (lines.next()) |line| {
        var gameInput = std.mem.splitScalar(u8, line, ':');
        _ = gameInput.next().?;
        const gameString = gameInput.next().?;

        const colors = try getColors(gameString);
        const red = colors.red;
        const blue = colors.blue;
        const green = colors.green;

        result += red * blue * green;
    }

    return result;
}

inline fn getColors(input: []const u8) !Colors {
    var red: usize = 0;
    var blue: usize = 0;
    var green: usize = 0;
    var games = std.mem.splitScalar(u8, input, ';');
    while (games.next()) |game| {
        var gameSets = std.mem.splitScalar(u8, game, ',');
        while (gameSets.next()) |gameSet| {
            var gameSetSegment = std.mem.tokenizeScalar(u8, gameSet, ' ');
            const numberString = gameSetSegment.next().?;
            const colorString = gameSetSegment.next().?;
            const numberValue = try std.fmt.parseInt(usize, numberString, 10);

            if (std.mem.eql(u8, colorString, "red")) {
                red = @max(red, numberValue);
            }

            if (std.mem.eql(u8, colorString, "blue")) {
                blue = @max(blue, numberValue);
            }

            if (std.mem.eql(u8, colorString, "green")) {
                green = @max(green, numberValue);
            }
        }
    }
    return .{ .red = red, .green = green, .blue = blue };
}

test "test-input" {
    const fileContent = @embedFile("test.txt");

    const part1 = try solvePart1(fileContent);
    const part2 = try solvePart2(fileContent);

    try std.testing.expectEqual(part1, 8);
    try std.testing.expectEqual(part2, 2286);
}
