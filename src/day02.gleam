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
pub fn parse(input: String) -> List(Range) {
  input
  |> string.trim
  |> string.split(",")
  |> list.filter_map(parse_range)
}

/// Check if n falls within any range
fn in_any_range(n: Int, ranges: List(Range)) -> Bool {
  list.any(ranges, fn(r) { n >= r.start && n <= r.end })
}

/// Get the maximum value across all ranges
fn max_in_ranges(ranges: List(Range)) -> Int {
  list.fold(ranges, 0, fn(acc, r) { int.max(acc, r.end) })
}

/// Generate all "doubled" numbers (pattern repeated exactly twice)
/// up to max_val, e.g., 11, 22, ..., 99, 1010, 1111, ..., 123123
fn generate_doubled(max_val: Int) -> List(Int) {
  generate_doubled_loop(1, max_val, [])
}

fn generate_doubled_loop(
  pattern_len: Int,
  max_val: Int,
  acc: List(Int),
) -> List(Int) {
  let min_pattern = pow10(pattern_len - 1)
  let max_pattern = pow10(pattern_len) - 1
  let multiplier = pow10(pattern_len) + 1
  let smallest = min_pattern * multiplier

  case smallest > max_val {
    True -> list.reverse(acc)
    False -> {
      let max_usable_pattern = int.min(max_pattern, max_val / multiplier)
      let new_numbers = case min_pattern > max_usable_pattern {
        True -> []
        False ->
          list.range(min_pattern, max_usable_pattern)
          |> list.map(fn(p) { p * multiplier })
      }
      generate_doubled_loop(
        pattern_len + 1,
        max_val,
        list.append(list.reverse(new_numbers), acc),
      )
    }
  }
}

/// Sum all "repeated" numbers (pattern repeated 2+ times) that fall in ranges
fn sum_repeated_in_ranges(ranges: List(Range), max_val: Int) -> Int {
  sum_repeated_by_total_len(2, max_val, ranges, 0)
}

fn sum_repeated_by_total_len(
  total_len: Int,
  max_val: Int,
  ranges: List(Range),
  acc: Int,
) -> Int {
  let min_with_len = pow10(total_len - 1)
  case min_with_len > max_val {
    True -> acc
    False -> {
      let sum = sum_repeated_with_len(total_len, max_val, ranges)
      sum_repeated_by_total_len(total_len + 1, max_val, ranges, acc + sum)
    }
  }
}

fn sum_repeated_with_len(
  total_len: Int,
  max_val: Int,
  ranges: List(Range),
) -> Int {
  let min_with_len = pow10(total_len - 1)
  let max_with_len = int.min(pow10(total_len) - 1, max_val)

  divisors(total_len)
  |> list.filter(fn(d) { d >= 2 })
  |> list.fold(0, fn(acc, repeat_count) {
    let pattern_len = total_len / repeat_count
    acc
    + sum_patterns_if_minimal(
      pattern_len,
      repeat_count,
      min_with_len,
      max_with_len,
      ranges,
    )
  })
}

fn sum_patterns_if_minimal(
  pattern_len: Int,
  repeat_count: Int,
  min_val: Int,
  max_val: Int,
  ranges: List(Range),
) -> Int {
  let min_pattern = case pattern_len {
    1 -> 1
    _ -> pow10(pattern_len - 1)
  }
  let max_pattern = pow10(pattern_len) - 1
  let multiplier = repeat_multiplier(pattern_len, repeat_count)

  let actual_min =
    int.max(min_pattern, { min_val + multiplier - 1 } / multiplier)
  let actual_max = int.min(max_pattern, max_val / multiplier)

  case actual_min > actual_max {
    True -> 0
    False ->
      list.range(actual_min, actual_max)
      |> list.filter(fn(p) { is_minimal_pattern(p, pattern_len) })
      |> list.map(fn(p) { p * multiplier })
      |> list.filter(fn(n) { in_any_range(n, ranges) })
      |> int.sum
  }
}

/// Check if pattern is minimal (not itself a repeated pattern)
fn is_minimal_pattern(pattern: Int, pattern_len: Int) -> Bool {
  !is_itself_repeated(pattern, pattern_len)
}

/// Check if a number is itself a repeated pattern
fn is_itself_repeated(n: Int, num_digits: Int) -> Bool {
  case num_digits < 2 {
    True -> False
    False -> {
      divisors(num_digits)
      |> list.filter(fn(d) { d >= 2 })
      |> list.any(fn(repeat_count) {
        let sub_pattern_len = num_digits / repeat_count
        // Skip if this would be the same as the original (no actual repetition)
        case sub_pattern_len >= num_digits {
          True -> False
          False -> {
            let multiplier = repeat_multiplier(sub_pattern_len, repeat_count)
            n % multiplier == 0
            && {
              let sub_pattern = n / multiplier
              let min_sub = case sub_pattern_len {
                1 -> 1
                _ -> pow10(sub_pattern_len - 1)
              }
              sub_pattern >= min_sub && sub_pattern < pow10(sub_pattern_len)
            }
          }
        }
      })
    }
  }
}

fn repeat_multiplier(pattern_len: Int, repeat_count: Int) -> Int {
  repeat_multiplier_loop(pattern_len, repeat_count, 0, 0)
}

fn repeat_multiplier_loop(
  pattern_len: Int,
  remaining: Int,
  shift: Int,
  acc: Int,
) -> Int {
  case remaining {
    0 -> acc
    _ ->
      repeat_multiplier_loop(
        pattern_len,
        remaining - 1,
        shift + pattern_len,
        acc + pow10(shift),
      )
  }
}

fn divisors(n: Int) -> List(Int) {
  list.range(1, n)
  |> list.filter(fn(d) { n % d == 0 })
}

fn pow10(n: Int) -> Int {
  case n {
    0 -> 1
    _ -> 10 * pow10(n - 1)
  }
}

pub fn part1(ranges: List(Range)) -> Int {
  let max_val = max_in_ranges(ranges)
  generate_doubled(max_val)
  |> list.filter(fn(n) { in_any_range(n, ranges) })
  |> int.sum
}

pub fn part2(ranges: List(Range)) -> Int {
  let max_val = max_in_ranges(ranges)
  sum_repeated_in_ranges(ranges, max_val)
}

pub fn run(input: String) -> #(Int, Int) {
  let parsed = parse(input)
  #(part1(parsed), part2(parsed))
}
