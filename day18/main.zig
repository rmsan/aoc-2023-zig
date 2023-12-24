const std = @import("std");

pub fn main() !void {
    const fileContent = @embedFile("input.txt");

    var timer = try std.time.Timer.start();
    const part1 = try solvePart1(fileContent);
    const part2 = try solvePart2(fileContent);

    std.debug.print("Part1: {d}\nPart2: {d}\nTime: {d}us\n", .{ part1, part2, timer.lap() / std.time.ns_per_us });
}

inline fn directionToXY(direction: u8) [2]isize {
    return switch (direction) {
        'U' => [2]isize{ 0, -1 },
        'D' => [2]isize{ 0, 1 },
        'R' => [2]isize{ 1, 0 },
        'L' => [2]isize{ -1, 0 },
        else => unreachable,
    };
}

inline fn numberToXY(number: u8) [2]isize {
    return switch (number) {
        '0' => [2]isize{ 1, 0 },
        '1' => [2]isize{ 0, 1 },
        '2' => [2]isize{ -1, 0 },
        '3' => [2]isize{ 0, -1 },
        else => unreachable,
    };
}

inline fn solve(input: []const u8, comptime hex: bool) !usize {
    var lines = std.mem.tokenizeScalar(u8, input, '\n');
    var area: isize = 0;
    var start: [2]isize = [_]isize{ 0, 0 };
    while (lines.next()) |line| {
        var segments = std.mem.tokenizeScalar(u8, line, ' ');
        const directionString = segments.next().?;
        const timesString = segments.next().?;
        var rgbString = segments.next().?;
        var times: isize = 0;
        var xy: [2]isize = undefined;
        if (!hex) {
            const direction: u8 = directionString[0];
            times = try std.fmt.parseInt(isize, timesString, 10);
            xy = directionToXY(direction);
        } else {
            rgbString = rgbString[2 .. rgbString.len - 1];
            const number: u8 = rgbString[rgbString.len - 1 ..][0];
            times = try std.fmt.parseInt(isize, rgbString[0 .. rgbString.len - 1], 16);
            xy = numberToXY(number);
        }

        var next: [2]isize = [_]isize{ start[0] + xy[0] * times, start[1] + xy[1] * times };
        area += (start[0] * next[1] - start[1] * next[0]) + times;
        start = next;
    }
    return @intCast(@divExact(area, 2) + 1);
}

fn solvePart1(input: []const u8) !usize {
    return solve(input, false);
}

fn solvePart2(input: []const u8) !usize {
    return solve(input, true);
}

test "test-input" {
    const fileContent = @embedFile("test.txt");

    const part1 = try solvePart1(fileContent);
    const part2 = try solvePart2(fileContent);

    try std.testing.expectEqual(part1, 62);
    try std.testing.expectEqual(part2, 952408144115);
}
