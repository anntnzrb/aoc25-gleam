import day07.{parse, part1, part2, run}
import gleam/set
import gleeunit/should

// ============================================================================
// Example from puzzle
// ============================================================================

const example_input = ".......S.......
...............
.......^.......
...............
......^.^......
...............
.....^.^.^.....
...............
....^.^...^....
...............
...^.^...^.^...
...............
..^...^.....^..
...............
.^.^.^.^.^...^.
..............."

pub fn part1_example_test() {
  parse(example_input)
  |> part1
  |> should.equal(21)
}

pub fn part2_example_test() {
  parse(example_input)
  |> part2
  |> should.equal(40)
}

pub fn run_example_test() {
  run(example_input)
  |> should.equal(#(21, 40))
}

// ============================================================================
// Parse tests
// ============================================================================

pub fn parse_finds_start_column_test() {
  let grid = parse("..S..\n.....\n.....")
  grid.start_col |> should.equal(2)
}

pub fn parse_finds_splitters_test() {
  let grid = parse("..S..\n..^..\n.^.^.")
  grid.splitters |> set.size |> should.equal(3)
  set.contains(grid.splitters, #(1, 2)) |> should.equal(True)
  set.contains(grid.splitters, #(2, 1)) |> should.equal(True)
  set.contains(grid.splitters, #(2, 3)) |> should.equal(True)
}

pub fn parse_counts_height_test() {
  let grid = parse("S\n.\n.\n.")
  grid.height |> should.equal(4)
}

pub fn parse_empty_input_test() {
  let grid = parse("")
  grid.height |> should.equal(0)
  grid.splitters |> set.size |> should.equal(0)
}

// ============================================================================
// Part 1: Split counting (beams merge)
// ============================================================================

pub fn part1_no_splitters_test() {
  // Beam goes straight through with no splits
  parse("S\n.\n.\n.")
  |> part1
  |> should.equal(0)
}

pub fn part1_single_splitter_test() {
  // One splitter = one split
  parse("S\n^\n.")
  |> part1
  |> should.equal(1)
}

pub fn part1_two_sequential_splitters_test() {
  // Beam hits first splitter, splits into two beams
  // Each of those hits second row splitters
  parse(".S.\n.^.\n^.^")
  |> part1
  |> should.equal(3)
}

pub fn part1_beams_merge_test() {
  // Two beams merging into same column count as one beam
  parse("..S..\n..^..\n.^.^.\n..^..")
  |> part1
  // Row 1: 1 split (col 2 -> col 1, col 3)
  // Row 2: 2 splits (col 1 -> col 0, col 2) + (col 3 -> col 2, col 4)
  // Row 3: 1 split at col 2 (merged beams)
  |> should.equal(4)
}

pub fn part1_splitter_not_hit_test() {
  // Splitter exists but beam doesn't hit it
  parse("S....\n.....\n....^\n.....")
  |> part1
  |> should.equal(0)
}

// ============================================================================
// Part 2: Timeline counting (quantum splitting)
// ============================================================================

pub fn part2_no_splitters_test() {
  // No splits = 1 timeline
  parse("S\n.\n.\n.")
  |> part2
  |> should.equal(1)
}

pub fn part2_single_splitter_test() {
  // One split = 2 timelines
  parse("S\n^\n.")
  |> part2
  |> should.equal(2)
}

pub fn part2_two_sequential_splitters_test() {
  // First split: 2 timelines
  // Second row: each beam splits again
  parse(".S.\n.^.\n^.^")
  |> part2
  |> should.equal(4)
}

pub fn part2_exponential_growth_test() {
  // Beam at col 0 hits ^ at row 1, splits to -1 and 1
  // Subsequent ^ at col 0 are NOT hit (beams are now at -1 and 1)
  parse("S\n^\n^\n^")
  |> part1
  |> should.equal(1)

  // Only one split = 2 timelines
  parse("S\n^\n^\n^")
  |> part2
  |> should.equal(2)

  // For exponential growth, splitters must be where beams go:
  // ..S.. -> beam at col 2
  // ..^.. -> splits to col 1, 3 (2 timelines)
  // .^.^. -> both hit, splits to 0,2 and 2,4 (4 beams, 2 merged at col 2)
  // ^...^ -> hits at 0 and 4, col 2 beams pass through
  // Final: cols -1,1 (from 0), col 2 (2 timelines), cols 3,5 (from 4) = 6
  parse("..S..\n..^..\n.^.^.\n^...^")
  |> part1
  |> should.equal(5)

  parse("..S..\n..^..\n.^.^.\n^...^")
  |> part2
  |> should.equal(6)
}

pub fn part2_beams_dont_merge_test() {
  // Unlike part1, quantum timelines track separately
  parse("..S..\n..^..\n.^.^.\n.....")
  |> part2
  // Row 1: 1 -> 2 (cols -1, 1 from perspective, actually 1, 3)
  // Row 2: col 1 -> 2 timelines (0, 2), col 3 -> 2 timelines (2, 4)
  // Merged at col 2: 2 timelines from left + 2 from right = 4 at col 2
  |> should.equal(4)
}

// ============================================================================
// Edge cases
// ============================================================================

pub fn empty_grid_test() {
  // Empty grid: 0 splits, but 1 timeline (beam starts and ends)
  run("")
  |> should.equal(#(0, 1))
}

pub fn single_row_no_splitter_test() {
  run("..S..")
  |> should.equal(#(0, 1))
}

pub fn single_row_with_splitter_test() {
  // Splitter on same row as S - beam starts there
  run("..S^.")
  |> should.equal(#(0, 1))
}

pub fn start_on_splitter_test() {
  // S and ^ at same position... unlikely but test it
  // Actually S takes priority, ^ is ignored at that position
  let grid = parse("S\n^")
  grid.start_col |> should.equal(0)
  part1(grid) |> should.equal(1)
}

pub fn wide_grid_test() {
  // Very wide grid with splitters spread out
  // Row 0: S at col 10
  // Row 1: ^ at col 10 -> 1 split, beams at 9,11
  // Row 2: ^ at 9, ^ at 11 -> 2 splits, beams at 8,10,10,12 -> merged: 8,10,12
  // Row 3: ^ at 8, ^ at 12 -> 2 splits
  // Total: 1 + 2 + 2 = 5
  parse(
    "..........S..........\n..........^..........\n.........^.^.........\n........^...^........",
  )
  |> part1
  |> should.equal(5)
}

// ============================================================================
// Additional coverage tests
// ============================================================================

pub fn parse_only_splitters_test() {
  // Grid with splitters but no S (start_col defaults to 0)
  let grid = parse("..^..\n..^..")
  grid.start_col |> should.equal(0)
  grid.splitters |> set.size |> should.equal(2)
}

pub fn part1_beam_continues_no_split_test() {
  // Beam doesn't hit any splitters - continues straight down
  parse("S....\n.....\n.....\n.....")
  |> part1
  |> should.equal(0)
}

pub fn part2_beam_continues_no_split_test() {
  // Beam doesn't hit any splitters - single timeline
  parse("S....\n.....\n.....\n.....")
  |> part2
  |> should.equal(1)
}

pub fn multiple_beams_merge_test() {
  // Multiple beams merge at same column
  parse("..S..\n..^..\n.^.^.\n..^..")
  |> part1
  // Row 1: 1 split
  // Row 2: 2 splits (at cols 1 and 3)
  // Row 3: 1 split at col 2 (merged)
  |> should.equal(4)
}

pub fn add_to_dict_accumulates_test() {
  // Test timeline accumulation when beams hit same column
  parse("..S..\n..^..\n.^.^.\n.....")
  |> part2
  // Row 1: 1->2 timelines (cols 1, 3)
  // Row 2: col 1 splits to 0,2 (2 timelines), col 3 splits to 2,4 (2 timelines)
  // At col 2: 1+1=2 timelines, col 0: 1, col 4: 1
  // Total: 1+2+1 = 4
  |> should.equal(4)
}

pub fn parse_s_and_splitter_same_row_test() {
  // S and splitter on same row
  let grid = parse("S^...")
  grid.start_col |> should.equal(0)
  set.contains(grid.splitters, #(0, 1)) |> should.equal(True)
}

pub fn height_zero_test() {
  // Empty input should have height 0
  let grid = parse("")
  grid.height |> should.equal(0)
}
