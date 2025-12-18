import gleam/int
import gleam/list
import gleam/result
import gleam/string

pub type Range {
  Range(start: Int, end: Int)
}

pub type Input {
  Input(ranges: List(Range), ids: List(Int))
}

/// Parse a single range "X-Y" -> Range(X, Y)
fn parse_range(s: String) -> Result(Range, Nil) {
  case string.split(s, "-") {
    [start_str, end_str] -> {
      use start <- result.try(int.parse(string.trim(start_str)))
      use end <- result.try(int.parse(string.trim(end_str)))
      Ok(Range(start, end))
    }
    _ -> Error(Nil)
  }
}

/// Parse the entire input: ranges section, blank line, IDs section
pub fn parse(input: String) -> Input {
  case string.split(input |> string.trim, "\n\n") {
    [ranges_section, ids_section] -> {
      let ranges =
        ranges_section
        |> string.split("\n")
        |> list.filter_map(parse_range)

      let ids =
        ids_section
        |> string.split("\n")
        |> list.filter_map(fn(line) { int.parse(string.trim(line)) })

      Input(ranges:, ids:)
    }
    _ -> Input(ranges: [], ids: [])
  }
}

/// Check if an ID falls within any range
fn is_fresh(id: Int, ranges: List(Range)) -> Bool {
  list.any(ranges, fn(r) { id >= r.start && id <= r.end })
}

pub fn part1(input: Input) -> Int {
  input.ids
  |> list.filter(fn(id) { is_fresh(id, input.ranges) })
  |> list.length
}

/// Sort ranges by start position
fn sort_ranges(ranges: List(Range)) -> List(Range) {
  list.sort(ranges, fn(a, b) { int.compare(a.start, b.start) })
}

/// Merge overlapping/adjacent ranges
fn merge_ranges(ranges: List(Range)) -> List(Range) {
  case sort_ranges(ranges) {
    [] -> []
    [first, ..rest] -> merge_ranges_loop(rest, first, [])
  }
}

fn merge_ranges_loop(
  ranges: List(Range),
  current: Range,
  acc: List(Range),
) -> List(Range) {
  case ranges {
    [] -> list.reverse([current, ..acc])
    [next, ..rest] -> {
      // Check if current and next overlap or are adjacent
      case current.end >= next.start - 1 {
        True -> {
          // Merge: extend current to include next
          let merged = Range(current.start, int.max(current.end, next.end))
          merge_ranges_loop(rest, merged, acc)
        }
        False -> {
          // No overlap: save current, start new
          merge_ranges_loop(rest, next, [current, ..acc])
        }
      }
    }
  }
}

/// Count total unique IDs covered by all ranges
fn count_covered(ranges: List(Range)) -> Int {
  ranges
  |> merge_ranges
  |> list.map(fn(r) { r.end - r.start + 1 })
  |> int.sum
}

pub fn part2(input: Input) -> Int {
  count_covered(input.ranges)
}

pub fn run(input: String) -> #(Int, Int) {
  let parsed = parse(input)
  #(part1(parsed), part2(parsed))
}
