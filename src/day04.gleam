import gleam/list
import gleam/set.{type Set}
import gleam/string

pub type Pos =
  #(Int, Int)

/// Parse input into a set of roll positions
pub fn parse(input: String) -> Set(Pos) {
  input
  |> string.trim
  |> string.split("\n")
  |> list.index_fold(set.new(), fn(acc, line, row) {
    line
    |> string.to_graphemes
    |> list.index_fold(acc, fn(rolls, char, col) {
      case char {
        "@" -> set.insert(rolls, #(row, col))
        _ -> rolls
      }
    })
  })
}

/// Get all 8 neighbor positions
fn neighbors(pos: Pos) -> List(Pos) {
  let #(r, c) = pos
  [
    #(r - 1, c - 1),
    #(r - 1, c),
    #(r - 1, c + 1),
    #(r, c - 1),
    #(r, c + 1),
    #(r + 1, c - 1),
    #(r + 1, c),
    #(r + 1, c + 1),
  ]
}

/// Count adjacent rolls for a position
fn count_adjacent(rolls: Set(Pos), pos: Pos) -> Int {
  neighbors(pos)
  |> list.count(fn(n) { set.contains(rolls, n) })
}

/// Check if a roll is accessible (fewer than 4 adjacent rolls)
fn is_accessible(rolls: Set(Pos), pos: Pos) -> Bool {
  count_adjacent(rolls, pos) < 4
}

/// Find all accessible rolls
fn find_accessible(rolls: Set(Pos)) -> List(Pos) {
  rolls
  |> set.to_list
  |> list.filter(fn(pos) { is_accessible(rolls, pos) })
}

pub fn part1(rolls: Set(Pos)) -> Int {
  find_accessible(rolls) |> list.length
}

/// Get all neighbors of a list of positions (for targeted rechecking)
fn all_neighbors(positions: List(Pos)) -> Set(Pos) {
  positions
  |> list.flat_map(neighbors)
  |> set.from_list
}

/// Part 2: Iteratively remove accessible rolls
/// Optimization: only recheck neighbors of removed rolls
pub fn part2(rolls: Set(Pos)) -> Int {
  // Initial accessible rolls
  let accessible = find_accessible(rolls)
  remove_loop(rolls, accessible, 0)
}

fn remove_loop(rolls: Set(Pos), accessible: List(Pos), total: Int) -> Int {
  case accessible {
    [] -> total
    _ -> {
      let count = list.length(accessible)

      // Remove accessible rolls
      let new_rolls =
        list.fold(accessible, rolls, fn(r, pos) { set.delete(r, pos) })

      // Only recheck neighbors of removed rolls (that are still rolls)
      let candidates = all_neighbors(accessible)
      let next_accessible =
        candidates
        |> set.intersection(new_rolls)
        |> set.to_list
        |> list.filter(fn(pos) { is_accessible(new_rolls, pos) })

      remove_loop(new_rolls, next_accessible, total + count)
    }
  }
}

/// For test compatibility
pub fn find_rolls(rolls: Set(Pos)) -> List(Pos) {
  set.to_list(rolls)
}

pub fn run(input: String) -> #(Int, Int) {
  let parsed = parse(input)
  #(part1(parsed), part2(parsed))
}
