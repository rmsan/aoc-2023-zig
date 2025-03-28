const std = @import("std");

pub fn main() !void {
    var gpa = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer gpa.deinit();
    var allocator = gpa.allocator();
    const fileContent = @embedFile("input.txt");

    var timer = try std.time.Timer.start();
    const part1 = try solvePart1(fileContent, &allocator);
    const part2 = try solvePart2(fileContent, &allocator);

    std.debug.print("Part1: {d}\nPart2: {d}\nTime: {d}us\n", .{ part1, part2, timer.lap() / std.time.ns_per_us });
}

const Operator = enum { lt, gt };

const Condition = struct { toCheck: u8, operator: Operator, limit: usize };

const Instruction = struct {
    condition: ?Condition,
    jumpTo: ?[]const u8,
};

const WorkflowMapAndRatings = struct {
    workflowMap: std.StringHashMap(std.ArrayList(Instruction)),
    ratings: []const u8,
};

inline fn getWorkflowMapAndRatings(input: []const u8, allocator: *std.mem.Allocator) !WorkflowMapAndRatings {
    var segments = std.mem.tokenizeSequence(u8, input, "\n\n");
    const workflows = segments.next().?;
    const ratings = segments.next().?;
    var workflowMap = std.StringHashMap(std.ArrayList(Instruction)).init(allocator.*);
    var workflowSegments = std.mem.tokenizeScalar(u8, workflows, '\n');
    while (workflowSegments.next()) |workflowString| {
        var workflowBranchSegments = std.mem.tokenizeScalar(u8, workflowString, '{');
        const workflowName = workflowBranchSegments.next().?;
        var workflowBranches = workflowBranchSegments.next().?;
        workflowBranches = workflowBranches[0 .. workflowBranches.len - 1];
        var branches = std.mem.tokenizeScalar(u8, workflowBranches, ',');
        while (branches.next()) |branch| {
            if (!workflowMap.contains(workflowName)) {
                // Assumption: Input do not have more than 4 branches (rules) per workflow to process
                const list = try std.ArrayList(Instruction).initCapacity(allocator.*, 4);
                try workflowMap.put(workflowName, list);
            }

            // Assumption: Workflow names are a maximum of 3 characters
            if (branch.len > 3) {
                var branchSegments = std.mem.tokenizeScalar(u8, branch, ':');
                var firstPart = branchSegments.next().?;
                const jumpTo = branchSegments.next().?;

                var conditionSegments = std.mem.tokenizeAny(u8, firstPart, "<>");
                const toCheck = conditionSegments.next().?[0];
                const limitString = conditionSegments.next().?;
                const limit = try std.fmt.parseInt(usize, limitString, 10);
                const operatorString = firstPart[1..2];
                const operator = if (operatorString[0] == '<') Operator.lt else Operator.gt;
                const condition = Condition{ .toCheck = toCheck, .limit = limit, .operator = operator };
                var list = workflowMap.get(workflowName).?;
                list.appendAssumeCapacity(Instruction{
                    .jumpTo = jumpTo,
                    .condition = condition,
                });
                try workflowMap.put(workflowName, list);
            } else {
                var list = workflowMap.get(workflowName).?;
                list.appendAssumeCapacity(Instruction{ .jumpTo = branch, .condition = undefined });
                try workflowMap.put(workflowName, list);
            }
        }
    }

    return .{ .workflowMap = workflowMap, .ratings = ratings };
}

fn solvePart1(input: []const u8, allocator: *std.mem.Allocator) !usize {
    var result: usize = 0;
    const workflowMapAndRatings = try getWorkflowMapAndRatings(input, allocator);
    var workflowMap = workflowMapAndRatings.workflowMap;
    defer {
        var it = workflowMap.valueIterator();
        while (it.next()) |item| {
            item.deinit();
        }
        workflowMap.deinit();
    }

    const ratings = workflowMapAndRatings.ratings;
    var ratingSegments = std.mem.tokenizeScalar(u8, ratings, '\n');
    while (ratingSegments.next()) |rating| {
        const ratingString = rating[1 .. rating.len - 1];
        var xmasSegment = std.mem.tokenizeScalar(u8, ratingString, ',');
        const x = xmasSegment.next().?;
        const m = xmasSegment.next().?;
        const a = xmasSegment.next().?;
        const s = xmasSegment.next().?;
        const xCount = try std.fmt.parseInt(usize, x[2..], 10);
        const mCount = try std.fmt.parseInt(usize, m[2..], 10);
        const aCount = try std.fmt.parseInt(usize, a[2..], 10);
        const sCount = try std.fmt.parseInt(usize, s[2..], 10);

        var entryToCheck: []const u8 = "in";
        outer: while (true) {
            const firstChar = entryToCheck[0];
            if (firstChar == 'A' or firstChar == 'R') {
                if (firstChar == 'A') {
                    result += xCount + mCount + aCount + sCount;
                }
                break :outer;
            }
            const entry = workflowMap.get(entryToCheck).?;
            for (entry.items) |instruction| {
                if (instruction.condition) |condition| {
                    const jumpTo = instruction.jumpTo.?;
                    const valueToCheck = switch (condition.toCheck) {
                        'x' => xCount,
                        'm' => mCount,
                        'a' => aCount,
                        's' => sCount,
                        else => unreachable,
                    };
                    const limit = condition.limit;
                    if (condition.operator == Operator.lt) {
                        if (valueToCheck < limit) {
                            entryToCheck = jumpTo;
                            break;
                        }
                    } else {
                        if (valueToCheck > limit) {
                            entryToCheck = jumpTo;
                            break;
                        }
                    }
                } else {
                    if (instruction.jumpTo) |jumpTo| {
                        entryToCheck = jumpTo;
                    }
                }
            }
        }
    }

    return result;
}

fn solvePart2(input: []const u8, allocator: *std.mem.Allocator) !usize {
    const workflowMapAndRatings = try getWorkflowMapAndRatings(input, allocator);
    var workflowMap = workflowMapAndRatings.workflowMap;
    defer {
        var it = workflowMap.valueIterator();
        while (it.next()) |item| {
            item.deinit();
        }
        workflowMap.deinit();
    }

    var possibleList = try std.ArrayList([2]usize).initCapacity(allocator.*, 4);
    for (0..4) |_| {
        possibleList.appendAssumeCapacity([2]usize{ 1, 4000 });
    }
    const possible = try possibleList.toOwnedSlice();
    defer allocator.free(possible);
    return try process(&workflowMap, "in", possible, allocator);
}

fn process(workflowMap: *std.StringHashMap(std.ArrayList(Instruction)), rule: []const u8, possible: [][2]usize, allocator: *std.mem.Allocator) !usize {
    const firstChar = rule[0];
    if (firstChar == 'A') {
        var product: usize = 1;
        for (possible) |inner| {
            const low = inner[0];
            const high = inner[1];
            product *= high - low + 1;
        }
        return product;
    }
    if (firstChar == 'R') {
        return 0;
    }

    var innerPossible = possible;
    var total: usize = 0;
    var entry = workflowMap.get(rule).?;
    const fallbackEntry = entry.pop();
    const fallback = fallbackEntry.?.jumpTo.?;
    for (entry.items) |instruction| {
        const target = instruction.jumpTo.?;
        if (instruction.condition) |condition| {
            const index: usize = switch (condition.toCheck) {
                'x' => 0,
                'm' => 1,
                'a' => 2,
                's' => 3,
                else => unreachable,
            };
            const limit = condition.limit;
            const low = possible[index][0];
            const high = possible[index][1];
            var trueHalf: [2]usize = undefined;
            var falseHalf: [2]usize = undefined;
            if (condition.operator == Operator.lt) {
                trueHalf = [2]usize{ low, limit - 1 };
                falseHalf = [2]usize{ limit, high };
            } else {
                trueHalf = [2]usize{ limit + 1, high };
                falseHalf = [2]usize{ low, limit };
            }

            if (trueHalf[0] <= trueHalf[1]) {
                var copy = try std.ArrayList([2]usize).initCapacity(allocator.*, possible.len);
                for (possible) |item| {
                    copy.appendAssumeCapacity(item);
                }
                var copyPossible = try copy.toOwnedSlice();
                defer allocator.free(copyPossible);
                copyPossible[index] = trueHalf;
                total += try process(workflowMap, target, copyPossible, allocator);
            }
            if (falseHalf[0] <= falseHalf[1]) {
                innerPossible[index] = falseHalf;
            } else {
                break;
            }
        }
    } else {
        total += try process(workflowMap, fallback, innerPossible, allocator);
    }

    return total;
}

test "test-input" {
    var allocator = std.testing.allocator;
    const fileContent = @embedFile("test.txt");

    const part1 = try solvePart1(fileContent, &allocator);
    const part2 = try solvePart2(fileContent, &allocator);

    try std.testing.expectEqual(part1, 19114);
    try std.testing.expectEqual(part2, 167409079868000);
}
