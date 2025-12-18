import gleam/dict.{type Dict}
import gleam/int
import gleam/list
import gleam/string

pub type Op {
  Add
  Mul
}

pub type Problem {
  Problem(numbers: List(Int), op: Op)
}

/// Grid representation: Dict(#(row, col), char)
type CharGrid =
  Dict(#(Int, Int), String)

/// Parse input into a character grid for fast access
fn to_grid(input: String) -> #(CharGrid, Int, Int) {
  let lines =
    input
    |> string.split("\n")
    |> list.filter(fn(s) { !string.is_empty(s) })

  let height = list.length(lines)
  let width =
    lines
    |> list.map(string.length)
    |> list.fold(0, int.max)

  let grid =
    lines
    |> list.index_fold(dict.new(), fn(acc, line, row) {
      line
      |> string.to_graphemes
      |> list.index_fold(acc, fn(g, char, col) {
        dict.insert(g, #(row, col), char)
      })
    })

  #(grid, width, height)
}

/// Get character at position, default to space
fn get_char(grid: CharGrid, row: Int, col: Int) -> String {
  dict.get(grid, #(row, col)) |> fn(r) {
    case r {
      Ok(c) -> c
      Error(_) -> " "
    }
  }
}

/// Check if a column is all spaces (separator)
fn is_separator_col(grid: CharGrid, col: Int, height: Int) -> Bool {
  list.range(0, height - 1)
  |> list.all(fn(row) { get_char(grid, row, col) == " " })
}

/// Find problem boundaries (start_col, end_col pairs)
fn find_problem_bounds(grid: CharGrid, width: Int, height: Int) -> List(#(Int, Int)) {
  find_bounds_loop(grid, 0, width, height, -1, [])
}

fn find_bounds_loop(
  grid: CharGrid,
  col: Int,
  width: Int,
  height: Int,
  start: Int,
  acc: List(#(Int, Int)),
) -> List(#(Int, Int)) {
  case col >= width {
    True -> {
      case start >= 0 {
        True -> list.reverse([#(start, col - 1), ..acc])
        False -> list.reverse(acc)
      }
    }
    False -> {
      let is_sep = is_separator_col(grid, col, height)
      case is_sep, start >= 0 {
        True, True ->
          // End of problem
          find_bounds_loop(grid, col + 1, width, height, -1, [
            #(start, col - 1),
            ..acc
          ])
        True, False ->
          // Still in separator
          find_bounds_loop(grid, col + 1, width, height, -1, acc)
        False, True ->
          // Continue problem
          find_bounds_loop(grid, col + 1, width, height, start, acc)
        False, False ->
          // Start new problem
          find_bounds_loop(grid, col + 1, width, height, col, acc)
      }
    }
  }
}

/// Find operation in a problem region
fn find_op(grid: CharGrid, start_col: Int, end_col: Int, height: Int) -> Op {
  // Check last row first (most likely location)
  let last_row = height - 1
  case find_op_in_row(grid, start_col, end_col, last_row) {
    Ok(op) -> op
    Error(_) -> Add
    // Default fallback
  }
}

fn find_op_in_row(
  grid: CharGrid,
  start_col: Int,
  end_col: Int,
  row: Int,
) -> Result(Op, Nil) {
  list.range(start_col, end_col)
  |> list.find_map(fn(col) {
    case get_char(grid, row, col) {
      "+" -> Ok(Add)
      "*" -> Ok(Mul)
      _ -> Error(Nil)
    }
  })
}

/// Parse digit character to int
fn digit_value(c: String) -> Result(Int, Nil) {
  case c {
    "0" -> Ok(0)
    "1" -> Ok(1)
    "2" -> Ok(2)
    "3" -> Ok(3)
    "4" -> Ok(4)
    "5" -> Ok(5)
    "6" -> Ok(6)
    "7" -> Ok(7)
    "8" -> Ok(8)
    "9" -> Ok(9)
    _ -> Error(Nil)
  }
}

/// Part 1: Extract numbers row-wise (left to right within each row)
fn extract_numbers_part1(
  grid: CharGrid,
  start_col: Int,
  end_col: Int,
  height: Int,
) -> List(Int) {
  list.range(0, height - 2)
  // Skip last row (operator)
  |> list.filter_map(fn(row) {
    let digits =
      list.range(start_col, end_col)
      |> list.filter_map(fn(col) { digit_value(get_char(grid, row, col)) })
    case digits {
      [] -> Error(Nil)
      _ -> Ok(list.fold(digits, 0, fn(acc, d) { acc * 10 + d }))
    }
  })
}

/// Part 2: Extract numbers column-wise (right to left, top to bottom per column)
fn extract_numbers_part2(
  grid: CharGrid,
  start_col: Int,
  end_col: Int,
  height: Int,
) -> List(Int) {
  // Read columns right to left
  list.range(start_col, end_col)
  |> list.reverse
  |> list.filter_map(fn(col) {
    let digits =
      list.range(0, height - 2)
      // Skip last row (operator)
      |> list.filter_map(fn(row) { digit_value(get_char(grid, row, col)) })
    case digits {
      [] -> Error(Nil)
      _ -> Ok(list.fold(digits, 0, fn(acc, d) { acc * 10 + d }))
    }
  })
}

/// Evaluate a problem
fn evaluate(problem: Problem) -> Int {
  case problem.op {
    Add -> int.sum(problem.numbers)
    Mul -> list.fold(problem.numbers, 1, fn(a, b) { a * b })
  }
}

/// Parse problems for Part 1
pub fn parse(input: String) -> List(Problem) {
  let #(grid, width, height) = to_grid(input)
  case height {
    0 -> []
    _ -> {
      let bounds = find_problem_bounds(grid, width, height)
      bounds
      |> list.map(fn(b) {
        let #(start, end) = b
        let op = find_op(grid, start, end, height)
        let nums = extract_numbers_part1(grid, start, end, height)
        Problem(numbers: nums, op: op)
      })
    }
  }
}

pub fn part1(problems: List(Problem)) -> Int {
  problems |> list.map(evaluate) |> int.sum
}

/// Parse and solve Part 2 directly
pub fn part2(input: String) -> Int {
  let #(grid, width, height) = to_grid(input)
  case height {
    0 -> 0
    _ -> {
      let bounds = find_problem_bounds(grid, width, height)
      bounds
      |> list.map(fn(b) {
        let #(start, end) = b
        let op = find_op(grid, start, end, height)
        let nums = extract_numbers_part2(grid, start, end, height)
        evaluate(Problem(numbers: nums, op: op))
      })
      |> int.sum
    }
  }
}

pub fn run(input: String) -> #(Int, Int) {
  let #(grid, width, height) = to_grid(input)
  case height {
    0 -> #(0, 0)
    _ -> {
      let bounds = find_problem_bounds(grid, width, height)

      let p1 =
        bounds
        |> list.map(fn(b) {
          let #(start, end) = b
          let op = find_op(grid, start, end, height)
          let nums = extract_numbers_part1(grid, start, end, height)
          evaluate(Problem(numbers: nums, op: op))
        })
        |> int.sum

      let p2 =
        bounds
        |> list.map(fn(b) {
          let #(start, end) = b
          let op = find_op(grid, start, end, height)
          let nums = extract_numbers_part2(grid, start, end, height)
          evaluate(Problem(numbers: nums, op: op))
        })
        |> int.sum

      #(p1, p2)
    }
  }
}
