import day01.{Left, Right, Rotation, parse, parse_rotation, part1, part2, run}
import gleam/list
import gleeunit/should

// ============================================================================
// parse_rotation tests
// ============================================================================

pub fn parse_rotation_left_test() {
  parse_rotation("L5")
  |> should.equal(Ok(Rotation(Left, 5)))
}

pub fn parse_rotation_right_test() {
  parse_rotation("R10")
  |> should.equal(Ok(Rotation(Right, 10)))
}

pub fn parse_rotation_large_distance_test() {
  parse_rotation("R1000")
  |> should.equal(Ok(Rotation(Right, 1000)))
}

pub fn parse_rotation_with_whitespace_test() {
  parse_rotation("  L68  ")
  |> should.equal(Ok(Rotation(Left, 68)))
}

pub fn parse_rotation_invalid_direction_test() {
  parse_rotation("X5")
  |> should.equal(Error(Nil))
}

pub fn parse_rotation_empty_test() {
  parse_rotation("")
  |> should.equal(Error(Nil))
}

pub fn parse_rotation_no_distance_test() {
  parse_rotation("L")
  |> should.equal(Error(Nil))
}

// ============================================================================
// parse tests
// ============================================================================

const example_input = "L68
L30
R48
L5
R60
L55
L1
L99
R14
L82"

pub fn parse_example_test() {
  let rotations = parse(example_input)
  list.length(rotations)
  |> should.equal(10)

  // Check first and last
  list.first(rotations)
  |> should.equal(Ok(Rotation(Left, 68)))

  list.last(rotations)
  |> should.equal(Ok(Rotation(Left, 82)))
}

pub fn parse_empty_test() {
  parse("")
  |> should.equal([])
}

pub fn parse_single_rotation_test() {
  parse("R50")
  |> should.equal([Rotation(Right, 50)])
}

// ============================================================================
// part1 tests
// ============================================================================

pub fn part1_example_test() {
  parse(example_input)
  |> part1
  |> should.equal(3)
}

pub fn part1_single_rotation_to_zero_test() {
  // Start at 50, R50 -> ends at 0
  [Rotation(Right, 50)]
  |> part1
  |> should.equal(1)
}

pub fn part1_wrap_left_no_zero_test() {
  // Start at 50, L60 -> 50 - 60 = -10 mod 100 = 90 (doesn't end at 0)
  [Rotation(Left, 60)]
  |> part1
  |> should.equal(0)
}

pub fn part1_multiple_zeros_test() {
  // Start at 50, R50 -> 0, R100 -> 0, L100 -> 0
  [Rotation(Right, 50), Rotation(Right, 100), Rotation(Left, 100)]
  |> part1
  |> should.equal(3)
}

pub fn part1_empty_test() {
  []
  |> part1
  |> should.equal(0)
}

// ============================================================================
// part2 tests
// ============================================================================

pub fn part2_example_test() {
  parse(example_input)
  |> part2
  |> should.equal(6)
}

pub fn part2_r1000_crosses_ten_times_test() {
  // Start at 50, R1000 crosses 0 ten times (at positions 50, 150, 250, ..., 950)
  [Rotation(Right, 1000)]
  |> part2
  |> should.equal(10)
}

pub fn part2_left_cross_zero_test() {
  // Start at 50, L51 goes from 50 down to 99 (wrapping), crosses 0 once
  [Rotation(Left, 51)]
  |> part2
  |> should.equal(1)
}

pub fn part2_no_cross_test() {
  // Start at 50, R10 -> 60, doesn't cross 0
  [Rotation(Right, 10)]
  |> part2
  |> should.equal(0)
}

pub fn part2_exact_to_zero_test() {
  // Start at 50, R50 -> lands exactly on 0 (counts as crossing)
  [Rotation(Right, 50)]
  |> part2
  |> should.equal(1)
}

pub fn part2_empty_test() {
  []
  |> part2
  |> should.equal(0)
}

// ============================================================================
// run tests
// ============================================================================

pub fn run_example_test() {
  run(example_input)
  |> should.equal(#(3, 6))
}

pub fn run_empty_test() {
  run("")
  |> should.equal(#(0, 0))
}
