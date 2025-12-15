import gleam/int
import gleam/list
import gleam/result
import gleam/string

pub type Range {
  Range(start: Int, end: Int)
}

/// Parse "11-22" -> Range(11, 22)
fn parse_range(s: String) -> Result(Range, Nil) {
  case string.split(s, "-") {
    [start_str, end_str] -> {
      use start <- result.try(int.parse(start_str))
      use end <- result.try(int.parse(end_str))
      Ok(Range(start, end))
    }
    _ -> Error(Nil)
  }
}

/// Parse "11-22,95-115,..." -> List(Range)
fn parse_input(input: String) -> List(Range) {
  input
  |> string.trim
  |> string.split(",")
  |> list.filter_map(parse_range)
}

/// Part 1: Check if number is a sequence repeated exactly twice
/// e.g., 55 (5×2), 6464 (64×2), 123123 (123×2)
fn is_doubled(n: Int) -> Bool {
  let s = int.to_string(n)
  let len = string.length(s)
  len > 0
  && len % 2 == 0
  && {
    let half = len / 2
    string.slice(s, 0, half) == string.slice(s, half, half)
  }
}

/// Part 2: Check if number is a sequence repeated 2+ times
/// e.g., 111 (1×3), 123123123 (123×3), 1212121212 (12×5)
fn is_repeated(n: Int) -> Bool {
  let s = int.to_string(n)
  let len = string.length(s)
  // Need at least 2 digits to have a repeated pattern
  len >= 2
  && {
    // Try all repeat counts from 2 to len
    list.range(2, len)
    |> list.any(fn(repeats) {
      repeats >= 2
      && len % repeats == 0
      && {
        let pattern_len = len / repeats
        let pattern = string.slice(s, 0, pattern_len)
        string.repeat(pattern, repeats) == s
      }
    })
  }
}

/// Generate all integers in a range (inclusive)
fn range_to_list(r: Range) -> List(Int) {
  list.range(r.start, r.end)
}

/// Sum all invalid IDs across ranges using given predicate
fn sum_invalid(ranges: List(Range), is_invalid: fn(Int) -> Bool) -> Int {
  ranges
  |> list.flat_map(range_to_list)
  |> list.filter(is_invalid)
  |> int.sum
}

pub fn part1(input: String) -> Int {
  parse_input(input) |> sum_invalid(is_doubled)
}

pub fn part2(input: String) -> Int {
  parse_input(input) |> sum_invalid(is_repeated)
}

pub fn run(input: String) -> #(Int, Int) {
  #(part1(input), part2(input))
}
