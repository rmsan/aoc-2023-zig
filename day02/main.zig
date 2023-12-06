const std = @import("std");

const Colors = struct { red: usize, blue: usize, green: usize };

// 12 red cubes, 13 green cubes, and 14 blue cubes
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
    var gameInput = std.mem.splitScalar(u8, input, ':');
    var gameIdString = gameInput.next().?;
    const gameId = try std.fmt.parseInt(usize, gameIdString[5..], 10);
    var gameString = gameInput.next().?;

    const colors = try getColors(gameString);
    var red: usize = colors.red;
    var blue: usize = colors.blue;
    var green: usize = colors.green;

    var result: usize = 0;
    if (red <= 12 and green <= 13 and blue <= 14) {
        result += gameId;
    }

    return result;
}

fn solvePart2(input: []const u8) !usize {
    var gameInput = std.mem.splitScalar(u8, input, ':');
    _ = gameInput.next().?;
    var gameString = gameInput.next().?;
    var result: usize = 0;

    const colors = try getColors(gameString);
    var red: usize = colors.red;
    var blue: usize = colors.blue;
    var green: usize = colors.green;

    result = red * blue * green;

    return result;
}

fn getColors(input: []const u8) !Colors {
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
    var lines1 = std.mem.tokenizeAny(u8, fileContent, "\n");
    var part1: usize = 0;
    var part2: usize = 0;
    while (lines1.next()) |line| {
        part1 += try solvePart1(line);
        part2 += try solvePart2(line);
    }

    try std.testing.expectEqual(part1, 8);
    try std.testing.expectEqual(part2, 2286);
}
