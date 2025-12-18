import gleam/dict.{type Dict}
import gleam/int
import gleam/list
import gleam/result
import gleam/set.{type Set}
import gleam/string

pub type Pos =
  #(Int, Int)

pub type Grid {
  Grid(splitters: Set(Pos), start_col: Int, height: Int)
}

/// Parse the grid - find splitters (^) and start column (S)
pub fn parse(input: String) -> Grid {
  let lines =
    input
    |> string.trim
    |> string.split("\n")
    |> list.filter(fn(s) { !string.is_empty(s) })

  let height = list.length(lines)

  let #(splitters, start_col) =
    lines
    |> list.index_fold(#(set.new(), 0), fn(acc, line, row) {
      line
      |> string.to_graphemes
      |> list.index_fold(acc, fn(state, char, col) {
        let #(spl, st) = state
        case char {
          "^" -> #(set.insert(spl, #(row, col)), st)
          "S" -> #(spl, col)
          _ -> state
        }
      })
    })

  Grid(splitters:, start_col:, height:)
}

/// Part 1: Count total splits (beams merge at same column, each splitter hit = 1 split)
pub fn part1(grid: Grid) -> Int {
  let initial = set.from_list([grid.start_col])
  count_splits_merged(grid, 0, initial, 0)
}

fn count_splits_merged(
  grid: Grid,
  row: Int,
  beam_cols: Set(Int),
  total_splits: Int,
) -> Int {
  case row >= grid.height {
    True -> total_splits
    False -> {
      // Process each beam column - beams at same column merge
      let #(new_cols, splits_this_row) =
        beam_cols
        |> set.to_list
        |> list.fold(#(set.new(), 0), fn(acc, col) {
          let #(acc_cols, acc_splits) = acc
          case set.contains(grid.splitters, #(row, col)) {
            True -> {
              // Split: beam splits into left and right (1 split event)
              let new_acc =
                acc_cols
                |> set.insert(col - 1)
                |> set.insert(col + 1)
              #(new_acc, acc_splits + 1)
            }
            False -> {
              // Continue: beam stays at same column
              #(set.insert(acc_cols, col), acc_splits)
            }
          }
        })

      count_splits_merged(
        grid,
        row + 1,
        new_cols,
        total_splits + splits_this_row,
      )
    }
  }
}

/// Part 2: Count total timelines
pub fn part2(grid: Grid) -> Int {
  let initial = dict.from_list([#(grid.start_col, 1)])
  count_timelines_at_row(grid, 0, initial)
}

fn count_timelines_at_row(
  grid: Grid,
  row: Int,
  beam_counts: Dict(Int, Int),
) -> Int {
  case row >= grid.height {
    True -> {
      // Sum all timeline counts
      beam_counts |> dict.values |> int.sum
    }
    False -> {
      // Process each beam column
      let new_counts =
        beam_counts
        |> dict.to_list
        |> list.fold(dict.new(), fn(acc, entry) {
          let #(col, count) = entry
          case set.contains(grid.splitters, #(row, col)) {
            True -> {
              // Split: add count to both left and right columns
              acc
              |> add_to_dict(col - 1, count)
              |> add_to_dict(col + 1, count)
            }
            False -> {
              // Continue: keep count at same column
              add_to_dict(acc, col, count)
            }
          }
        })

      count_timelines_at_row(grid, row + 1, new_counts)
    }
  }
}

fn add_to_dict(d: Dict(Int, Int), key: Int, value: Int) -> Dict(Int, Int) {
  let current =
    dict.get(d, key)
    |> result.unwrap(0)
  dict.insert(d, key, current + value)
}

pub fn run(input: String) -> #(Int, Int) {
  let parsed = parse(input)
  #(part1(parsed), part2(parsed))
}
