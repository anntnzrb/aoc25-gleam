import day03.{parse, part1, part2, run}
import gleam/list
import gleeunit/should

// ============================================================================
// parse tests
// ============================================================================

const example_input = "987654321111111
811111111111119
234234234234278
818181911112111"

pub fn parse_example_test() {
  let banks = parse(example_input)
  list.length(banks)
  |> should.equal(4)
}

pub fn parse_filters_empty_lines_test() {
  parse("abc\n\ndef")
  |> should.equal(["abc", "def"])
}

pub fn parse_empty_test() {
  parse("")
  |> should.equal([])
}

pub fn parse_single_bank_test() {
  parse("12345")
  |> should.equal(["12345"])
}

pub fn parse_with_trailing_newline_test() {
  parse("12345\n67890\n")
  |> should.equal(["12345", "67890"])
}

// ============================================================================
// part1 tests (max 2-digit joltage)
// ============================================================================

pub fn part1_bank1_test() {
  // 987654321111111 -> first two digits 98 is max
  part1(["987654321111111"])
  |> should.equal(98)
}

pub fn part1_bank2_test() {
  // 811111111111119 -> 8 and 9 = 89
  part1(["811111111111119"])
  |> should.equal(89)
}

pub fn part1_bank3_test() {
  // 234234234234278 -> last two 78
  part1(["234234234234278"])
  |> should.equal(78)
}

pub fn part1_bank4_test() {
  // 818181911112111 -> 9 and then 2 = 92
  part1(["818181911112111"])
  |> should.equal(92)
}

pub fn part1_example_test() {
  // 98 + 89 + 78 + 92 = 357
  parse(example_input)
  |> part1
  |> should.equal(357)
}

pub fn part1_simple_test() {
  // 12345 -> best is 45 (4 followed by 5)
  part1(["12345"])
  |> should.equal(45)
}

pub fn part1_descending_test() {
  // 54321 -> best is 54 (5 followed by 4, or any first digit * 10 + max after)
  part1(["54321"])
  |> should.equal(54)
}

pub fn part1_all_same_test() {
  // 11111 -> best is 11
  part1(["11111"])
  |> should.equal(11)
}

pub fn part1_two_digits_test() {
  // 39 -> only option is 39
  part1(["39"])
  |> should.equal(39)
}

pub fn part1_empty_test() {
  part1([])
  |> should.equal(0)
}

// ============================================================================
// part2 tests (max 12-digit joltage)
// ============================================================================

pub fn part2_bank1_test() {
  // 987654321111111 -> pick first 12: 987654321111
  part2(["987654321111111"])
  |> should.equal(987_654_321_111)
}

pub fn part2_bank2_test() {
  // 811111111111119 -> 811111111119 (skip one 1, keep the 9)
  part2(["811111111111119"])
  |> should.equal(811_111_111_119)
}

pub fn part2_bank3_test() {
  // 234234234234278 -> 434234234278 (skip 2, 3, 2 at start)
  part2(["234234234234278"])
  |> should.equal(434_234_234_278)
}

pub fn part2_bank4_test() {
  // 818181911112111 -> 888911112111
  part2(["818181911112111"])
  |> should.equal(888_911_112_111)
}

pub fn part2_example_test() {
  // 987654321111 + 811111111119 + 434234234278 + 888911112111 = 3121910778619
  parse(example_input)
  |> part2
  |> should.equal(3_121_910_778_619)
}

pub fn part2_exactly_12_digits_test() {
  // Exactly 12 digits: pick all
  part2(["123456789012"])
  |> should.equal(123_456_789_012)
}

pub fn part2_greedy_selection_test() {
  // 999111111111111 -> should pick all 9s first: 999111111111
  part2(["999111111111111"])
  |> should.equal(999_111_111_111)
}

pub fn part2_empty_test() {
  part2([])
  |> should.equal(0)
}

// ============================================================================
// run tests
// ============================================================================

pub fn run_example_test() {
  run(example_input)
  |> should.equal(#(357, 3_121_910_778_619))
}

pub fn run_empty_test() {
  run("")
  |> should.equal(#(0, 0))
}

// ============================================================================
// Edge case tests
// ============================================================================

pub fn part1_max_at_end_test() {
  // 1119 -> best is 19 (1*10 + 9 = 19)
  part1(["1119"])
  |> should.equal(19)
}

pub fn part2_multiple_banks_test() {
  // Sum of two banks
  part2(["987654321111111", "811111111111119"])
  |> should.equal(987_654_321_111 + 811_111_111_119)
}
