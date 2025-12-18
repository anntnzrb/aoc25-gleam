import day12.{parse, part1, run}
import gleam/dict
import gleam/list
import gleam/set
import gleeunit/should

// ============================================================================
// Example input - matching actual format
// ============================================================================

const example_input = "0:
##
#.

1:
#
#
#

2:
.#
##

3x3: 1 0 0
2x3: 0 1 0
2x2: 0 0 1"

// ============================================================================
// Parse tests
// ============================================================================

pub fn parse_shapes_test() {
  let input = parse(example_input)
  input.shapes |> dict.size |> should.equal(3)
}

pub fn parse_shape_coords_test() {
  let input = parse(example_input)
  let shape0 = dict.get(input.shapes, 0)
  case shape0 {
    Ok(s) -> {
      // Shape 0 is:
      // ##
      // #.
      // Coords: (0,0), (0,1), (1,0)
      s |> set.size |> should.equal(3)
      s |> set.contains(#(0, 0)) |> should.equal(True)
      s |> set.contains(#(0, 1)) |> should.equal(True)
      s |> set.contains(#(1, 0)) |> should.equal(True)
    }
    Error(_) -> should.fail()
  }
}

pub fn parse_regions_test() {
  let input = parse(example_input)
  input.regions |> list.length |> should.equal(3)
}

pub fn parse_region_dimensions_test() {
  let input = parse(example_input)
  case input.regions {
    [r1, r2, r3] -> {
      r1.width |> should.equal(3)
      r1.height |> should.equal(3)
      r2.width |> should.equal(2)
      r2.height |> should.equal(3)
      r3.width |> should.equal(2)
      r3.height |> should.equal(2)
    }
    _ -> should.fail()
  }
}

pub fn parse_empty_test() {
  let input = parse("")
  input.shapes |> dict.size |> should.equal(0)
  input.regions |> should.equal([])
}

// ============================================================================
// Part 1 tests
// ============================================================================

pub fn part1_simple_fit_test() {
  // 2x2 region with 1 single-cell shape
  let input =
    "0:
#

2x2: 1"
  parse(input) |> part1 |> should.equal(1)
}

pub fn part1_no_fit_test() {
  // 1x1 region with 2-cell shape
  let input =
    "0:
##

1x1: 1"
  parse(input) |> part1 |> should.equal(0)
}

pub fn part1_two_shapes_fit_test() {
  // 2x2 region with two 1-cell shapes
  let input =
    "0:
#

2x2: 2"
  parse(input) |> part1 |> should.equal(1)
}

pub fn part1_rotation_needed_test() {
  // 3x1 region with vertical 3-cell shape (needs rotation)
  let input =
    "0:
#
#
#

3x1: 1"
  parse(input) |> part1 |> should.equal(1)
}

pub fn part1_multiple_regions_test() {
  // Some regions fit, some don't
  let input =
    "0:
#

2x2: 1
1x1: 2"
  // First region fits (1 shape in 2x2), second doesn't (2 shapes in 1x1)
  parse(input) |> part1 |> should.equal(1)
}

// ============================================================================
// Run tests
// ============================================================================

pub fn run_empty_test() {
  run("") |> should.equal(#(0, 0))
}

pub fn run_simple_test() {
  let input =
    "0:
#

2x2: 1"
  run(input) |> should.equal(#(1, 1))
}
