import day04.{parse, part1, run}
import gleam/list
import gleam/set
import gleeunit/should

// ============================================================================
// Example from puzzle
// ============================================================================

const example_input = "..@@.@@@@.
@@@.@.@.@@
@@@@@.@.@@
@.@@@@..@.
@@.@@@@.@@
.@@@@@@@.@
.@.@.@.@@@
@.@@@.@@@@
.@@@@@@@@.
@.@.@@@.@."

pub fn part1_example_test() {
  parse(example_input)
  |> part1
  |> should.equal(13)
}

// ============================================================================
// Parse tests
// ============================================================================

pub fn parse_simple_test() {
  let rolls = parse("@.\n.@")
  rolls
  |> day04.find_rolls
  |> list.length
  |> should.equal(2)

  // Check both positions are present
  set.contains(rolls, #(0, 0)) |> should.equal(True)
  set.contains(rolls, #(1, 1)) |> should.equal(True)
}

// ============================================================================
// Accessibility tests
// ============================================================================

pub fn single_roll_accessible_test() {
  // Single roll with no neighbors
  parse("...\n.@.\n...")
  |> part1
  |> should.equal(1)
}

pub fn roll_with_four_neighbors_not_accessible_test() {
  // Roll in center with 4 neighbors (not accessible)
  parse(".@.\n@@@\n.@.")
  |> part1
  // Center has 4 neighbors, not accessible
  // Top has 1 neighbor, accessible
  // Left has 2 neighbors, accessible
  // Right has 2 neighbors, accessible
  // Bottom has 1 neighbor, accessible
  |> should.equal(4)
}

pub fn all_rolls_blocked_test() {
  // 3x3 grid of rolls - center has 8 neighbors
  parse("@@@\n@@@\n@@@")
  |> part1
  // Corners have 3 neighbors (accessible)
  // Edges have 5 neighbors (not accessible)
  // Center has 8 neighbors (not accessible)
  |> should.equal(4)
}

// ============================================================================
// Part 2 tests
// ============================================================================

pub fn part2_example_test() {
  // Example: 43 rolls can be removed total
  parse(example_input)
  |> day04.part2
  |> should.equal(43)
}

pub fn part2_single_roll_test() {
  // Single accessible roll: remove it
  parse("...\n.@.\n...")
  |> day04.part2
  |> should.equal(1)
}

pub fn part2_chain_removal_test() {
  // After removing corners, more become accessible
  parse("@@@\n@@@\n@@@")
  |> day04.part2
  // Corners (4) -> edges become accessible -> center
  |> should.equal(9)
}

// ============================================================================
// run tests
// ============================================================================

pub fn run_example_test() {
  run(example_input)
  |> should.equal(#(13, 43))
}

pub fn run_empty_test() {
  run("")
  |> should.equal(#(0, 0))
}

// ============================================================================
// Additional coverage tests
// ============================================================================

pub fn parse_no_rolls_test() {
  // Grid with no @ characters
  let rolls = parse("...\n...\n...")
  rolls |> set.size |> should.equal(0)
}

pub fn parse_mixed_characters_test() {
  // Grid with various non-@ characters
  let rolls = parse("#.x\n@y@\nz.#")
  rolls |> set.size |> should.equal(2)
}

pub fn part1_empty_set_test() {
  // Empty set of rolls
  set.new()
  |> part1
  |> should.equal(0)
}

pub fn part2_empty_set_test() {
  // Empty set of rolls
  set.new()
  |> day04.part2
  |> should.equal(0)
}

pub fn neighbors_coverage_test() {
  // Roll with exactly 3 neighbors (corner case)
  parse("@@.\n@@.\n...")
  |> part1
  // All 4 rolls have < 4 neighbors
  |> should.equal(4)
}

pub fn part2_all_accessible_test() {
  // All rolls accessible immediately
  parse("@.@\n...\n@.@")
  |> day04.part2
  |> should.equal(4)
}

pub fn diagonal_neighbors_test() {
  // Test diagonal neighbor counting
  // Center @ has 4 diagonal neighbors
  parse("@.@\n.@.\n@.@")
  |> part1
  // Center has 4 neighbors (all diagonal), so not accessible
  // Corners have 1 neighbor each (accessible)
  |> should.equal(4)
}
