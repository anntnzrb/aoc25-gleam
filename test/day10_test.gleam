import day10.{parse, part1, part2, run}
import gleam/list
import gleeunit/should

// ============================================================================
// Test inputs - single line format: [target] (btn1) (btn2) ... {joltages}
// ============================================================================

const simple_input = "[.##.] (0,2) (0,1) {10,20,30,40}"

// ============================================================================
// Parse tests
// ============================================================================

pub fn parse_simple_test() {
  let machines = parse(simple_input)
  machines |> list.length |> should.equal(1)
}

pub fn parse_single_line_test() {
  let input = "[.##.] (0,2) (0,1) {1,2,3,4}"
  let machines = parse(input)
  machines |> list.length |> should.equal(1)
}

pub fn parse_multiple_machines_test() {
  let input =
    "[.#] (0) (1) {5,10}
[##] (0,1) {15,20}"
  let machines = parse(input)
  machines |> list.length |> should.equal(2)
}

pub fn parse_empty_test() {
  parse("") |> should.equal([])
}

// ============================================================================
// Part 1 tests
// ============================================================================

pub fn part1_simple_machine_test() {
  // Machine: [.##.] with buttons (0,2) and (0,1)
  // Target: lights 1 and 2 ON
  // Press (0,2) -> lights 0,2 on
  // Press (0,1) -> light 0 off, light 1 on
  // Result: lights 1,2 on = 2 presses
  parse(simple_input)
  |> part1
  |> should.equal(2)
}

pub fn part1_single_toggle_test() {
  // Target: [.#] (second light on)
  // Button: (1) toggles index 1
  // Solution: press once = 1
  let input = "[.#] (1) {5,10}"
  parse(input) |> part1 |> should.equal(1)
}

pub fn part1_all_off_test() {
  // Target: [..] (all off)
  // Already matches starting state, 0 presses needed
  let input = "[..] (0) (1) {5,10}"
  parse(input) |> part1 |> should.equal(0)
}

pub fn part1_two_buttons_test() {
  // Target: [##] (both on)
  // Button (0): toggles first
  // Button (1): toggles second
  // Need both = 2
  let input = "[##] (0) (1) {5,10}"
  parse(input) |> part1 |> should.equal(2)
}

pub fn part1_overlapping_buttons_test() {
  // Target: [#.] (first on, second off)
  // Button (0,1): toggles both
  // Button (1): toggles second
  // Solution: press both = 2 (first: on, second: on then off)
  let input = "[#.] (0,1) (1) {5,10}"
  parse(input) |> part1 |> should.equal(2)
}

pub fn part1_no_buttons_test() {
  // Target with no buttons - only solvable if all off
  let input = "[..] {5,10}"
  parse(input) |> part1 |> should.equal(0)
}

pub fn part1_xor_cancel_test() {
  // Target: [##] both on
  // Button (0,1): toggles both
  // Press once = 1
  let input = "[##] (0,1) {10,20}"
  parse(input) |> part1 |> should.equal(1)
}

pub fn part1_independent_buttons_test() {
  // Target: [###] all on
  // Buttons toggle each independently
  let input = "[###] (0) (1) (2) {10,20,30}"
  parse(input) |> part1 |> should.equal(3)
}

// ============================================================================
// Run tests
// ============================================================================

pub fn run_simple_test() {
  let #(p1, _p2) = run(simple_input)
  p1 |> should.equal(2)
}

pub fn run_empty_test() {
  run("") |> should.equal(#(0, 0))
}

// ============================================================================
// Part 2 tests - counter increment problem
// ============================================================================

pub fn part2_example_first_machine_test() {
  // From problem: [.##.] (3) (1,3) (2) (2,3) (0,2) (0,1) {3,5,4,7}
  // Expected: 10 button presses
  let input = "[.##.] (3) (1,3) (2) (2,3) (0,2) (0,1) {3,5,4,7}"
  parse(input) |> part2 |> should.equal(10)
}

pub fn part2_simple_test() {
  // [.#.#] (1,3) (0,1,2) {2,4,2,2}
  // Button 0: affects counters 1,3
  // Button 1: affects counters 0,1,2
  // Target: [2,4,2,2]
  // Solution: press button 0 twice, button 1 twice = 4
  // Counter 0: 2 (from button 1)
  // Counter 1: 2 + 2 = 4
  // Counter 2: 2 (from button 1)
  // Counter 3: 2 (from button 0)
  let input = "[.#.#] (1,3) (0,1,2) {2,4,2,2}"
  parse(input) |> part2 |> should.equal(4)
}

pub fn part2_example_all_three_test() {
  // All three example machines from problem
  // Machine 1: 10 presses
  // Machine 2: 12 presses
  // Machine 3: 11 presses
  // Total: 33
  let input =
    "[.##.] (3) (1,3) (2) (2,3) (0,2) (0,1) {3,5,4,7}
[...#.] (0,2,3,4) (2,3) (0,4) (0,1,2) (1,2,3,4) {7,5,12,7,2}
[.###.#] (0,1,2,3,4) (0,3,4) (0,1,2,4,5) (1,2) {10,11,11,5,10,5}"
  parse(input) |> part2 |> should.equal(33)
}
