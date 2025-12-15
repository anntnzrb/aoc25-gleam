import gleam/int
import gleam/list
import gleam/string

/// Parse input into list of battery banks (lines)
pub fn parse(input: String) -> List(String) {
  input
  |> string.trim
  |> string.split("\n")
  |> list.filter(fn(s) { !string.is_empty(s) })
}

/// Convert a digit character to int, or -1 if invalid
fn digit_to_int(c: String) -> Int {
  case int.parse(c) {
    Ok(n) -> n
    Error(_) -> -1
  }
}

/// Compute suffix maximums: suffix_max[i] = max of elements from i to end
fn suffix_maxes(digits: List(Int)) -> List(Int) {
  digits
  |> list.reverse
  |> list.fold([], fn(acc, d) {
    case acc {
      [] -> [d]
      [prev_max, ..] -> [int.max(d, prev_max), ..acc]
    }
  })
}

/// Find max 2-digit joltage from a single bank
/// For each position i, compute: digit[i] * 10 + max(digits after i)
fn max_joltage(bank: String) -> Int {
  let digits =
    bank
    |> string.to_graphemes
    |> list.map(digit_to_int)
    |> list.filter(fn(d) { d >= 0 })

  let suffix_max = suffix_maxes(digits)

  // Pair each digit with the suffix max AFTER it
  // suffix_max has same length as digits, so suffix_max[i+1] is what we need
  case digits, suffix_max {
    [], _ | _, [] -> 0
    _, _ -> {
      // zip digits with tail of suffix_max to get (digit[i], max_after[i])
      let after_maxes = list.drop(suffix_max, 1)
      list.zip(digits, after_maxes)
      |> list.map(fn(pair) { pair.0 * 10 + pair.1 })
      |> list.fold(0, int.max)
    }
  }
}

pub fn part1(banks: List(String)) -> Int {
  banks
  |> list.map(max_joltage)
  |> int.sum
}

/// Find max digit and its index in a list
fn find_max_with_index(digits: List(Int)) -> #(Int, Int) {
  list.index_fold(digits, #(-1, 0), fn(acc, d, i) {
    case d > acc.0 {
      True -> #(d, i)
      False -> acc
    }
  })
}

/// Greedy: pick k digits to form the largest number
fn pick_k_digits(remaining: List(Int), k: Int, acc: List(Int)) -> List(Int) {
  case k {
    0 -> list.reverse(acc)
    _ -> {
      let n = list.length(remaining)
      // Can pick from index 0 to n-k (need k-1 remaining after)
      let searchable = list.take(remaining, n - k + 1)
      let #(max_digit, idx) = find_max_with_index(searchable)
      let after = list.drop(remaining, idx + 1)
      pick_k_digits(after, k - 1, [max_digit, ..acc])
    }
  }
}

/// Convert list of digits to number
fn digits_to_int(digits: List(Int)) -> Int {
  list.fold(digits, 0, fn(acc, d) { acc * 10 + d })
}

/// Find max 12-digit joltage from a single bank
fn max_12_joltage(bank: String) -> Int {
  let digits =
    bank
    |> string.to_graphemes
    |> list.map(digit_to_int)
    |> list.filter(fn(d) { d >= 0 })

  pick_k_digits(digits, 12, [])
  |> digits_to_int
}

pub fn part2(banks: List(String)) -> Int {
  banks
  |> list.map(max_12_joltage)
  |> int.sum
}

pub fn run(input: String) -> #(Int, Int) {
  let parsed = parse(input)
  #(part1(parsed), part2(parsed))
}
