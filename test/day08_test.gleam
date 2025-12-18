import day08.{Point, parse, part1, part2, run}
import gleam/list
import gleeunit/should

// ============================================================================
// Parse tests
// ============================================================================

pub fn parse_single_point_test() {
  let points = parse("1,2,3")
  points |> list.length |> should.equal(1)
  points |> should.equal([Point(1, 2, 3)])
}

pub fn parse_multiple_points_test() {
  let points = parse("1,2,3\n4,5,6\n7,8,9")
  points |> list.length |> should.equal(3)
  points |> should.equal([Point(1, 2, 3), Point(4, 5, 6), Point(7, 8, 9)])
}

pub fn parse_with_whitespace_test() {
  let points = parse("  1 , 2 , 3  \n  4,5,6  ")
  points |> list.length |> should.equal(2)
}

pub fn parse_negative_coords_test() {
  let points = parse("-1,-2,-3")
  points |> should.equal([Point(-1, -2, -3)])
}

pub fn parse_empty_input_test() {
  let points = parse("")
  points |> should.equal([])
}

pub fn parse_invalid_lines_skipped_test() {
  let points = parse("1,2,3\ninvalid\n4,5,6")
  points |> list.length |> should.equal(2)
}

// ============================================================================
// Part 1: Circuit sizes after 1000 connections
// ============================================================================

pub fn part1_empty_test() {
  parse("")
  |> part1
  |> should.equal(0)
}

pub fn part1_single_point_test() {
  parse("0,0,0")
  |> part1
  |> should.equal(1)
}

pub fn part1_two_points_test() {
  // Two points connect into one circuit of size 2
  // With only 1 pair (< 1000), they connect
  // Part1 returns product of top 3 sizes
  // Only size 2 available: 2 * 1 * 1 or just 2
  parse("0,0,0\n1,0,0")
  |> part1
  |> should.equal(2)
}

pub fn part1_three_points_line_test() {
  // Three points in a line
  // Two closest pairs connect: 0-1, 1-2 (or 0-1, 0-2 depending on distances)
  // All in one circuit of size 3
  parse("0,0,0\n1,0,0\n2,0,0")
  |> part1
  |> should.equal(3)
}

pub fn part1_four_points_two_clusters_test() {
  // Two distant clusters - with few points, all will connect
  parse("0,0,0\n1,0,0\n100,0,0\n101,0,0")
  |> part1
  // 4 points, 6 pairs, all < 1000, so all connect
  // One circuit of size 4
  |> should.equal(4)
}

pub fn part1_five_points_test() {
  // Five points forming a pattern
  parse("0,0,0\n1,0,0\n0,1,0\n1,1,0\n0,0,1")
  |> part1
  // 5 points, 10 pairs, all connect (< 1000)
  |> should.equal(5)
}

// ============================================================================
// Part 2: MST bottleneck (last connection X product)
// ============================================================================

pub fn part2_empty_test() {
  parse("")
  |> part2
  |> should.equal(0)
}

pub fn part2_single_point_test() {
  parse("0,0,0")
  |> part2
  |> should.equal(0)
}

pub fn part2_two_points_test() {
  // Two points: last (only) connection is between them
  // x1 * x2 = 0 * 1 = 0
  parse("0,0,0\n1,0,0")
  |> part2
  |> should.equal(0)
}

pub fn part2_two_points_nonzero_x_test() {
  // x1 * x2 = 2 * 3 = 6
  parse("2,0,0\n3,0,0")
  |> part2
  |> should.equal(6)
}

pub fn part2_three_points_line_test() {
  // Three points on x-axis: 0, 1, 10
  // MST: connect 0-1 (dist 1), then 1-10 (dist 9)
  // Last connection is 1-10, x product = 1 * 10 = 10
  parse("0,0,0\n1,0,0\n10,0,0")
  |> part2
  |> should.equal(10)
}

pub fn part2_three_points_triangle_test() {
  // Equilateral-ish triangle at x=1,2,3
  parse("1,0,0\n2,1,0\n3,0,0")
  |> part2
  // Distances: 1-2: sqrt(2), 2-3: sqrt(2), 1-3: 2
  // MST: 1-2, 2-3 (both sqrt(2))
  // Last edge could be either, both have same distance
  // One of them completes the MST
  |> fn(x) { x > 0 }
  |> should.equal(True)
}

pub fn part2_four_points_clusters_test() {
  // Two clusters far apart
  // Cluster A: (1,0,0), (2,0,0) at x=1,2
  // Cluster B: (100,0,0), (101,0,0) at x=100,101
  // MST: 1-2 (dist 1), 100-101 (dist 1), then 2-100 (dist 98)
  // Last connection: 2 * 100 = 200
  parse("1,0,0\n2,0,0\n100,0,0\n101,0,0")
  |> part2
  |> should.equal(200)
}

// ============================================================================
// run tests
// ============================================================================

pub fn run_empty_test() {
  run("")
  |> should.equal(#(0, 0))
}

pub fn run_single_test() {
  run("5,5,5")
  |> should.equal(#(1, 0))
}

pub fn run_two_points_test() {
  run("2,0,0\n3,0,0")
  |> should.equal(#(2, 6))
}

// ============================================================================
// Distance calculation (implicit tests through behavior)
// ============================================================================

pub fn closest_pair_selected_first_test() {
  // Points at varying distances on x-axis
  // 0, 10, 11 - closest pair is 10-11 (dist 1)
  parse("0,0,0\n10,0,0\n11,0,0")
  |> part1
  |> should.equal(3)
}

pub fn three_dimensional_distance_test() {
  // Test 3D distance calculation
  // (0,0,0) to (1,1,1) = sqrt(3) ≈ 1.73
  // (0,0,0) to (2,0,0) = 2
  // Closer pair is (0,0,0)-(1,1,1)
  parse("0,0,0\n1,1,1\n2,0,0")
  |> part1
  |> should.equal(3)
}

// ============================================================================
// Edge cases
// ============================================================================

pub fn large_coordinates_test() {
  // Large coordinate values
  parse("1000000,1000000,1000000\n1000001,1000000,1000000")
  |> part2
  |> should.equal(1_000_000 * 1_000_001)
}

pub fn negative_x_product_test() {
  // Negative coordinates
  parse("-5,0,0\n-3,0,0\n10,0,0")
  |> part2
  // MST: -5 to -3 (dist 2), then -3 to 10 (dist 13)
  // Last connection: -3 * 10 = -30
  |> should.equal(-30)
}

pub fn all_same_point_test() {
  // All points at same location (degenerate case)
  parse("1,1,1\n1,1,1\n1,1,1")
  |> part1
  |> should.equal(3)
}

// ============================================================================
// Additional coverage tests
// ============================================================================

pub fn parse_extra_whitespace_test() {
  // Whitespace around coordinates
  let points = parse("  1 , 2 , 3  ")
  points |> list.length |> should.equal(1)
}

pub fn parse_wrong_number_of_coords_test() {
  // Wrong number of coordinates - should be skipped
  let points = parse("1,2\n3,4,5\n6,7,8,9")
  points |> list.length |> should.equal(1)
  // Only 3,4,5 is valid
}

pub fn union_find_self_union_test() {
  // Union with self (same root)
  parse("0,0,0\n1,0,0")
  |> part1
  |> should.equal(2)
}

pub fn part2_three_points_same_line_test() {
  // Three collinear points on x-axis
  // MST starts at node 0 (x=0), connects to node 1 (x=5), then node 2 (x=10)
  // Both edges have same distance, max_edge updated only when strictly greater
  // First bottleneck edge is 0-5 with x product = 0 * 5 = 0
  parse("0,0,0\n5,0,0\n10,0,0")
  |> part2
  |> should.equal(0)
}

pub fn part1_many_points_test() {
  // More than 3 points - top 3 sizes
  parse("0,0,0\n1,0,0\n2,0,0\n10,0,0\n11,0,0")
  |> part1
  // All connect into one circuit of size 5
  |> should.equal(5)
}

pub fn part2_zero_coordinates_test() {
  // Points at origin
  parse("0,0,0\n0,0,1")
  |> part2
  |> should.equal(0)
  // x1 * x2 = 0 * 0 = 0
}

pub fn distance_3d_test() {
  // Test 3D distance affects sorting
  // (0,0,0) to (1,1,1) = sqrt(3) ≈ 1.73
  // (0,0,0) to (0,0,2) = 2
  parse("0,0,0\n1,1,1\n0,0,2")
  |> part2
  // Closer pair (0,0,0)-(1,1,1) connects first
  // Then (1,1,1)-(0,0,2) or (0,0,0)-(0,0,2)
  |> fn(x) { x >= 0 }
  |> should.equal(True)
}

pub fn circuit_sizes_ranking_test() {
  // Multiple disconnected clusters (if connection limit hit)
  // With small number of points, all connect
  parse("0,0,0\n1,0,0\n100,0,0")
  |> part1
  |> should.equal(3)
}
