import day02.{Range, parse, part1, part2, run}
import gleeunit/should

// ============================================================================
// parse tests
// ============================================================================

pub fn parse_single_range_test() {
  parse("11-22")
  |> should.equal([Range(11, 22)])
}

pub fn parse_multiple_ranges_test() {
  parse("11-22,95-115")
  |> should.equal([Range(11, 22), Range(95, 115)])
}

pub fn parse_with_whitespace_test() {
  parse("  11-22,95-115  ")
  |> should.equal([Range(11, 22), Range(95, 115)])
}

pub fn parse_empty_test() {
  parse("")
  |> should.equal([])
}

pub fn parse_large_numbers_test() {
  parse("1188511880-1188511890")
  |> should.equal([Range(1_188_511_880, 1_188_511_890)])
}

// ============================================================================
// part1 tests (doubled patterns: pattern repeated exactly twice)
// ============================================================================

const example_input = "11-22,95-115,998-1012,1188511880-1188511890,222220-222224,1698522-1698528,446443-446449,38593856-38593862,565653-565659,824824821-824824827,2121212118-2121212124"

pub fn part1_simple_range_test() {
  // Range 1-100 contains: 11, 22, 33, 44, 55, 66, 77, 88, 99
  // Sum = 11+22+33+44+55+66+77+88+99 = 495
  parse("1-100")
  |> part1
  |> should.equal(495)
}

pub fn part1_single_doubled_test() {
  // Range 10-12 contains only 11
  parse("10-12")
  |> part1
  |> should.equal(11)
}

pub fn part1_no_matches_test() {
  // Range 1-10 contains no doubled numbers
  parse("1-10")
  |> part1
  |> should.equal(0)
}

pub fn part1_four_digit_doubled_test() {
  // Range 1000-1020 contains 1010
  parse("1000-1020")
  |> part1
  |> should.equal(1010)
}

pub fn part1_example_test() {
  parse(example_input)
  |> part1
  |> should.equal(1_227_775_554)
}

// ============================================================================
// part2 tests (repeated patterns: pattern repeated 2+ times)
// ============================================================================

pub fn part2_triple_digit_test() {
  // Range 110-112 contains 111 (1 repeated 3 times)
  parse("110-112")
  |> part2
  |> should.equal(111)
}

pub fn part2_range_with_doubled_and_tripled_test() {
  // Range 95-115 contains: 99 (doubled), 111 (tripled)
  // Sum = 99 + 111 = 210
  parse("95-115")
  |> part2
  |> should.equal(210)
}

pub fn part2_range_with_999_and_1010_test() {
  // Range 998-1012 contains: 999 (tripled), 1010 (doubled)
  // Sum = 999 + 1010 = 2009
  parse("998-1012")
  |> part2
  |> should.equal(2009)
}

pub fn part2_no_matches_test() {
  // Range 12-20 contains no repeated patterns
  parse("12-20")
  |> part2
  |> should.equal(0)
}

pub fn part2_example_test() {
  parse(example_input)
  |> part2
  |> should.equal(4_174_379_265)
}

// ============================================================================
// run tests
// ============================================================================

pub fn run_example_test() {
  run(example_input)
  |> should.equal(#(1_227_775_554, 4_174_379_265))
}

pub fn run_empty_test() {
  run("")
  |> should.equal(#(0, 0))
}

// ============================================================================
// Edge case tests
// ============================================================================

pub fn part1_boundary_doubled_test() {
  // Exactly at boundary: 11 is in range 11-11
  parse("11-11")
  |> part1
  |> should.equal(11)
}

pub fn part2_six_digit_pattern_test() {
  // 123123 is 123 repeated twice
  parse("123120-123125")
  |> part2
  |> should.equal(123_123)
}

pub fn part2_single_digit_repeated_test() {
  // 1111 is 1 repeated 4 times (pattern_len=1, repeat_count=4)
  parse("1110-1112")
  |> part2
  |> should.equal(1111)
}

pub fn part2_single_digit_twice_test() {
  // 11, 22, ..., 99 are single digits repeated twice
  parse("11-11")
  |> part2
  |> should.equal(11)
}

pub fn part1_empty_ranges_test() {
  // Empty ranges should return 0
  parse("")
  |> part1
  |> should.equal(0)
}

pub fn part2_empty_ranges_test() {
  // Empty ranges should return 0
  parse("")
  |> part2
  |> should.equal(0)
}

pub fn part1_multiple_doubled_in_range_test() {
  // Range 1000-2000 contains 1010, 1111, 1212, ..., 1919
  // Count: 1010, 1111, 1212, 1313, 1414, 1515, 1616, 1717, 1818, 1919 = 10 numbers
  // Sum = 1010+1111+1212+1313+1414+1515+1616+1717+1818+1919 = 14645
  parse("1000-2000")
  |> part1
  |> should.equal(14_645)
}
