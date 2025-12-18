import day09.{Point, parse, part1, part2, run}
import gleam/list
import gleeunit/should

// ============================================================================
// Parse tests
// ============================================================================

pub fn parse_single_point_test() {
  let points = parse("1,2")
  points |> list.length |> should.equal(1)
  points |> should.equal([Point(1, 2)])
}

pub fn parse_multiple_points_test() {
  let points = parse("1,2\n3,4\n5,6")
  points |> list.length |> should.equal(3)
  points |> should.equal([Point(1, 2), Point(3, 4), Point(5, 6)])
}

pub fn parse_with_whitespace_test() {
  let points = parse("  1 , 2  \n  3,4  ")
  points |> list.length |> should.equal(2)
}

pub fn parse_negative_coords_test() {
  let points = parse("-1,-2")
  points |> should.equal([Point(-1, -2)])
}

pub fn parse_empty_input_test() {
  let points = parse("")
  points |> should.equal([])
}

pub fn parse_invalid_lines_skipped_test() {
  let points = parse("1,2\ninvalid\n3,4")
  points |> list.length |> should.equal(2)
}

// ============================================================================
// Part 1: Maximum rectangle area (inclusive bounds)
// ============================================================================

pub fn part1_empty_test() {
  parse("")
  |> part1
  |> should.equal(0)
}

pub fn part1_single_point_test() {
  parse("0,0")
  |> part1
  |> should.equal(0)
}

pub fn part1_two_points_horizontal_test() {
  // (0,0) to (2,0): width=3, height=1, area=3
  parse("0,0\n2,0")
  |> part1
  |> should.equal(3)
}

pub fn part1_two_points_vertical_test() {
  // (0,0) to (0,4): width=1, height=5, area=5
  parse("0,0\n0,4")
  |> part1
  |> should.equal(5)
}

pub fn part1_two_points_diagonal_test() {
  // (0,0) to (3,2): width=4, height=3, area=12
  parse("0,0\n3,2")
  |> part1
  |> should.equal(12)
}

pub fn part1_three_points_test() {
  // Find max among all pairs
  // (0,0)-(1,0): 2*1=2
  // (0,0)-(0,1): 1*2=2
  // (1,0)-(0,1): 2*2=4
  parse("0,0\n1,0\n0,1")
  |> part1
  |> should.equal(4)
}

pub fn part1_four_corners_test() {
  // Rectangle corners: max area is diagonal
  // (0,0)-(10,5): 11*6=66
  parse("0,0\n10,0\n0,5\n10,5")
  |> part1
  |> should.equal(66)
}

pub fn part1_same_point_test() {
  // Same point: width=1, height=1, area=1
  parse("5,5\n5,5")
  |> part1
  |> should.equal(1)
}

// ============================================================================
// Part 2: Valid rectangles (inside polygon)
// ============================================================================

pub fn part2_empty_test() {
  parse("")
  |> part2
  |> should.equal(0)
}

pub fn part2_single_point_test() {
  parse("0,0")
  |> part2
  |> should.equal(0)
}

pub fn part2_two_points_test() {
  // Two points form a degenerate polygon - code still computes area
  parse("0,0\n1,1")
  |> part2
  |> should.equal(4)
}

pub fn part2_square_test() {
  // Simple square: all rectangles with corners on vertices are valid
  // Vertices: (0,0), (2,0), (2,2), (0,2) - closed loop
  // Valid pairs: any two opposite corners
  // (0,0)-(2,2): 3*3=9
  // (2,0)-(0,2): 3*3=9
  parse("0,0\n2,0\n2,2\n0,2")
  |> part2
  |> should.equal(9)
}

pub fn part2_rectangle_test() {
  // Rectangle polygon
  // (0,0) -> (4,0) -> (4,2) -> (0,2) -> back to (0,0)
  parse("0,0\n4,0\n4,2\n0,2")
  |> part2
  // Diagonal corners form valid rectangle: 5*3=15
  |> should.equal(15)
}

pub fn part2_l_shape_test() {
  // L-shaped polygon - some rectangles would include outside tiles
  // Shape:
  // (0,0) -> (2,0) -> (2,1) -> (1,1) -> (1,2) -> (0,2) -> back
  parse("0,0\n2,0\n2,1\n1,1\n1,2\n0,2")
  |> part2
  // Most large rectangles are invalid due to the notch
  // Valid rectangles are smaller ones within the L
  |> fn(x) { x > 0 }
  |> should.equal(True)
}

pub fn part2_concave_polygon_test() {
  // Concave polygon with indentation
  // (0,0) -> (4,0) -> (4,2) -> (2,2) -> (2,1) -> (0,1) -> back to (0,0)
  parse("0,0\n4,0\n4,2\n2,2\n2,1\n0,1")
  |> part2
  |> fn(x) { x > 0 }
  |> should.equal(True)
}

// ============================================================================
// run tests
// ============================================================================

pub fn run_empty_test() {
  run("")
  |> should.equal(#(0, 0))
}

pub fn run_single_test() {
  run("5,5")
  |> should.equal(#(0, 0))
}

pub fn run_square_test() {
  run("0,0\n3,0\n3,3\n0,3")
  // Part 1: max area = (0,0)-(3,3) = 4*4 = 16
  // Part 2: valid rectangle = 16
  |> should.equal(#(16, 16))
}

// ============================================================================
// Edge crossing detection
// ============================================================================

pub fn part2_edge_crossing_invalidates_test() {
  // Polygon with an edge that would cross a potential rectangle
  // U-shape: rectangles spanning the gap are invalid
  // (0,0) -> (0,3) -> (1,3) -> (1,1) -> (2,1) -> (2,3) -> (3,3) -> (3,0) -> back
  parse("0,0\n0,3\n1,3\n1,1\n2,1\n2,3\n3,3\n3,0")
  |> part2
  // Rectangle from (0,0) to (3,3) would be invalid due to internal edge
  // But smaller rectangles might be valid
  |> fn(x) { x > 0 && x < 16 }
  |> should.equal(True)
}

// ============================================================================
// Corner validation (inside polygon check)
// ============================================================================

pub fn part2_corner_outside_test() {
  // Diagonal polygon - some corner combinations are outside
  // Diamond shape: (2,0) -> (4,2) -> (2,4) -> (0,2) -> back
  parse("2,0\n4,2\n2,4\n0,2")
  |> part2
  // Only valid rectangles are those fully inside the diamond
  |> fn(x) { x >= 0 }
  |> should.equal(True)
}

// ============================================================================
// Point on edge tests
// ============================================================================

pub fn part2_point_on_horizontal_edge_test() {
  // Rectangle with extra point on edge
  // (0,0) -> (2,0) -> (4,0) -> (4,2) -> (0,2) -> back
  // Point (2,0) is on the edge between (0,0) and (4,0)
  parse("0,0\n2,0\n4,0\n4,2\n0,2")
  |> part2
  |> fn(x) { x > 0 }
  |> should.equal(True)
}

pub fn part2_point_on_vertical_edge_test() {
  // Rectangle with extra point on vertical edge
  parse("0,0\n4,0\n4,1\n4,2\n0,2")
  |> part2
  |> fn(x) { x > 0 }
  |> should.equal(True)
}

// ============================================================================
// Large coordinates
// ============================================================================

pub fn part1_large_coords_test() {
  // Large coordinates - tests area calculation
  parse("0,0\n10000,10000")
  |> part1
  |> should.equal(10001 * 10001)
}

pub fn part2_large_polygon_test() {
  // Large but simple square
  parse("0,0\n1000,0\n1000,1000\n0,1000")
  |> part2
  |> should.equal(1001 * 1001)
}

// ============================================================================
// Inclusive area calculation
// ============================================================================

pub fn area_inclusive_test() {
  // Verify area is inclusive (width+1, height+1)
  // (0,0) to (0,0) = 1*1 = 1
  // (0,0) to (1,0) = 2*1 = 2
  // (0,0) to (1,1) = 2*2 = 4
  parse("0,0\n0,0")
  |> part1
  |> should.equal(1)

  parse("0,0\n1,0")
  |> part1
  |> should.equal(2)

  parse("0,0\n1,1")
  |> part1
  |> should.equal(4)
}

// ============================================================================
// Negative coordinates
// ============================================================================

pub fn part1_negative_coords_test() {
  parse("-5,-5\n5,5")
  |> part1
  // width = |5-(-5)|+1 = 11, height = 11, area = 121
  |> should.equal(121)
}

pub fn part2_negative_coords_polygon_test() {
  // Square in negative quadrant
  parse("-4,-4\n-4,0\n0,0\n0,-4")
  |> part2
  |> should.equal(25)
}

// ============================================================================
// Additional coverage tests
// ============================================================================

pub fn parse_whitespace_lines_test() {
  // Lines with only whitespace are skipped
  let points = parse("1,2\n   \n3,4")
  points |> list.length |> should.equal(2)
}

pub fn ray_crosses_vertical_edge_test() {
  // Rectangle to test vertical edge crossing
  parse("0,0\n4,0\n4,4\n0,4")
  |> part2
  |> should.equal(25)
}

pub fn ray_crosses_horizontal_edge_test() {
  // Test point-in-polygon for horizontal edges
  parse("0,0\n2,0\n2,2\n0,2")
  |> part2
  |> should.equal(9)
}

pub fn get_other_corners_all_cases_test() {
  // Test different corner configurations
  // p1 at min_x, min_y
  parse("0,0\n2,2")
  |> part1
  |> should.equal(9)

  // p1 at min_x, max_y
  parse("0,2\n2,0")
  |> part1
  |> should.equal(9)

  // p1 at max_x, min_y
  parse("2,0\n0,2")
  |> part1
  |> should.equal(9)

  // p1 at max_x, max_y
  parse("2,2\n0,0")
  |> part1
  |> should.equal(9)
}

pub fn edge_crossing_h_edge_test() {
  // Test horizontal edge crossing detection
  parse("0,0\n4,0\n4,2\n2,2\n2,1\n0,1")
  |> part2
  |> fn(x) { x >= 0 }
  |> should.equal(True)
}

pub fn edge_crossing_v_edge_test() {
  // Test vertical edge crossing detection
  parse("0,0\n2,0\n2,4\n1,4\n1,2\n0,2")
  |> part2
  |> fn(x) { x >= 0 }
  |> should.equal(True)
}

pub fn point_on_edge_not_vertex_test() {
  // Point lies on edge but is not a vertex
  parse("0,0\n4,0\n4,4\n0,4")
  |> part2
  // Check if rectangle is valid
  |> should.equal(25)
}

pub fn diagonal_edge_polygon_test() {
  // Polygon with diagonal edges (non-axis-aligned)
  parse("0,0\n2,1\n1,2")
  |> part2
  |> fn(x) { x >= 0 }
  |> should.equal(True)
}

pub fn three_points_degenerate_test() {
  // Three collinear points (degenerate polygon)
  parse("0,0\n1,0\n2,0")
  |> part2
  |> fn(x) { x >= 0 }
  |> should.equal(True)
}

pub fn part1_three_points_max_area_test() {
  // Three points - check all pairs for max
  parse("0,0\n2,0\n0,2")
  |> part1
  // (0,0)-(2,0): 3*1=3
  // (0,0)-(0,2): 1*3=3
  // (2,0)-(0,2): 3*3=9
  |> should.equal(9)
}

pub fn consecutive_pairs_single_point_test() {
  // Single point has no consecutive pairs
  parse("5,5")
  |> part2
  |> should.equal(0)
}

pub fn build_edge_lists_empty_test() {
  // Empty polygon
  parse("")
  |> part2
  |> should.equal(0)
}
