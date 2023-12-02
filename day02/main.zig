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
            const redPos = std.mem.indexOf(u8, gameSet, "red");
            const bluePos = std.mem.indexOf(u8, gameSet, "blue");
            const greenPos = std.mem.indexOf(u8, gameSet, "green");

            if (redPos) |redFound| {
                const redString = std.mem.trim(u8, gameSet[0..redFound], " ");
                const redValue = try std.fmt.parseInt(usize, redString, 10);
                red = @max(red, redValue);
            }
            if (bluePos) |blueFound| {
                const blueString = std.mem.trim(u8, gameSet[0..blueFound], " ");
                const blueValue = try std.fmt.parseInt(usize, blueString, 10);
                blue = @max(blue, blueValue);
            }
            if (greenPos) |greenFound| {
                const greenString = std.mem.trim(u8, gameSet[0..greenFound], " ");
                const greenValue = try std.fmt.parseInt(usize, greenString, 10);
                green = @max(green, greenValue);
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
