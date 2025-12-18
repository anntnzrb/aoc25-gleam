import day05.{Input, Range, parse, part1, run}
import gleeunit/should

// ============================================================================
// Example from puzzle
// ============================================================================

const example_input = "3-5
10-14
16-20
12-18

1
5
8
11
17
32"

pub fn part1_example_test() {
  parse(example_input)
  |> part1
  |> should.equal(3)
}

// ============================================================================
// Parse tests
// ============================================================================

pub fn parse_example_test() {
  let input = parse(example_input)

  input.ranges
  |> should.equal([
    Range(3, 5),
    Range(10, 14),
    Range(16, 20),
    Range(12, 18),
  ])

  input.ids
  |> should.equal([1, 5, 8, 11, 17, 32])
}

pub fn parse_empty_test() {
  parse("")
  |> should.equal(Input(ranges: [], ids: []))
}

// ============================================================================
// Freshness tests
// ============================================================================

pub fn all_fresh_test() {
  let input = Input(ranges: [Range(1, 100)], ids: [1, 50, 100])
  part1(input) |> should.equal(3)
}

pub fn none_fresh_test() {
  let input = Input(ranges: [Range(1, 5)], ids: [6, 7, 8])
  part1(input) |> should.equal(0)
}

pub fn overlapping_ranges_test() {
  // ID 5 is in both ranges - should only count once
  let input = Input(ranges: [Range(1, 5), Range(3, 10)], ids: [5])
  part1(input) |> should.equal(1)
}

pub fn boundary_test() {
  // Test exact boundaries
  let input = Input(ranges: [Range(5, 10)], ids: [4, 5, 10, 11])
  part1(input) |> should.equal(2)
}

// ============================================================================
// Part 2 tests
// ============================================================================

pub fn part2_example_test() {
  // Example: 3-5, 10-14, 16-20, 12-18 -> 14 unique IDs
  // 3,4,5 (3) + 10-20 merged (11) = 14
  parse(example_input)
  |> day05.part2
  |> should.equal(14)
}

pub fn part2_single_range_test() {
  let input = Input(ranges: [Range(1, 10)], ids: [])
  day05.part2(input) |> should.equal(10)
}

pub fn part2_overlapping_ranges_test() {
  // 1-5 and 3-7 should merge to 1-7 = 7 IDs
  let input = Input(ranges: [Range(1, 5), Range(3, 7)], ids: [])
  day05.part2(input) |> should.equal(7)
}

pub fn part2_adjacent_ranges_test() {
  // 1-5 and 6-10 should merge to 1-10 = 10 IDs
  let input = Input(ranges: [Range(1, 5), Range(6, 10)], ids: [])
  day05.part2(input) |> should.equal(10)
}

pub fn part2_disjoint_ranges_test() {
  // 1-5 and 10-15 = 5 + 6 = 11 IDs
  let input = Input(ranges: [Range(1, 5), Range(10, 15)], ids: [])
  day05.part2(input) |> should.equal(11)
}

// ============================================================================
// run tests
// ============================================================================

pub fn run_example_test() {
  run(example_input)
  |> should.equal(#(3, 14))
}

pub fn run_empty_test() {
  run("")
  |> should.equal(#(0, 0))
}

// ============================================================================
// Additional coverage tests
// ============================================================================

pub fn part2_empty_ranges_test() {
  // Empty ranges list
  let input = Input(ranges: [], ids: [1, 2, 3])
  day05.part2(input) |> should.equal(0)
}

pub fn parse_invalid_range_format_test() {
  // Invalid range format is skipped
  let input = parse("1-5\ninvalid\n10-15\n\n1\n2")
  input.ranges |> should.equal([Range(1, 5), Range(10, 15)])
}

pub fn parse_single_section_test() {
  // Only ranges section (no blank line separator)
  let input = parse("1-5\n10-15")
  input.ranges |> should.equal([])
  input.ids |> should.equal([])
}

pub fn merge_ranges_fully_contained_test() {
  // One range fully contains another
  let input = Input(ranges: [Range(1, 10), Range(3, 7)], ids: [])
  day05.part2(input) |> should.equal(10)
}

pub fn merge_ranges_unsorted_test() {
  // Ranges given in reverse order
  let input = Input(ranges: [Range(10, 15), Range(1, 5)], ids: [])
  day05.part2(input) |> should.equal(11)
}

pub fn part1_id_at_range_boundary_test() {
  // ID exactly at range start and end
  let input = Input(ranges: [Range(5, 10)], ids: [5, 10])
  part1(input) |> should.equal(2)
}

pub fn part1_multiple_ranges_same_id_test() {
  // ID could be in multiple ranges
  let input = Input(ranges: [Range(1, 10), Range(5, 15)], ids: [7])
  part1(input) |> should.equal(1)
}
