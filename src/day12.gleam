import gleam/dict.{type Dict}
import gleam/int
import gleam/list
import gleam/result
import gleam/set.{type Set}
import gleam/string

// ============================================================================
// Types
// ============================================================================

pub type Shape =
  Set(#(Int, Int))

pub type Region {
  Region(width: Int, height: Int, requirements: List(#(Int, Int)))
}

pub type Input {
  Input(shapes: Dict(Int, Shape), regions: List(Region))
}

// ============================================================================
// Parsing
// ============================================================================

pub fn parse(input: String) -> Input {
  let lines =
    input
    |> string.trim
    |> string.split("\n")

  let #(shape_lines, region_lines) = split_shapes_regions(lines)

  let shapes = parse_all_shapes(shape_lines)
  let regions = parse_regions(region_lines)

  Input(shapes:, regions:)
}

fn split_shapes_regions(lines: List(String)) -> #(List(String), List(String)) {
  split_shapes_regions_loop(lines, [], False)
}

fn split_shapes_regions_loop(
  lines: List(String),
  shape_acc: List(String),
  found_region: Bool,
) -> #(List(String), List(String)) {
  case lines {
    [] -> #(list.reverse(shape_acc), [])
    [line, ..rest] -> {
      case found_region {
        True -> #(list.reverse(shape_acc), [line, ..rest])
        False -> {
          case is_region_header(line) {
            True -> #(list.reverse(shape_acc), [line, ..rest])
            False -> split_shapes_regions_loop(rest, [line, ..shape_acc], False)
          }
        }
      }
    }
  }
}

fn is_region_header(line: String) -> Bool {
  let trimmed = string.trim(line)
  case string.split_once(trimmed, "x") {
    Error(_) -> False
    Ok(#(w_str, rest)) -> {
      case int.parse(w_str) {
        Error(_) -> False
        Ok(_) -> {
          case string.split_once(rest, ":") {
            Error(_) -> False
            Ok(#(h_str, _)) -> {
              case int.parse(h_str) {
                Ok(_) -> True
                Error(_) -> False
              }
            }
          }
        }
      }
    }
  }
}

fn parse_all_shapes(lines: List(String)) -> Dict(Int, Shape) {
  parse_shapes_loop(lines, dict.new(), -1, [])
}

fn parse_shapes_loop(
  lines: List(String),
  acc: Dict(Int, Shape),
  current_idx: Int,
  current_rows: List(String),
) -> Dict(Int, Shape) {
  case lines {
    [] -> {
      case current_idx >= 0 && current_rows != [] {
        True -> dict.insert(acc, current_idx, rows_to_shape(current_rows))
        False -> acc
      }
    }
    [line, ..rest] -> {
      let trimmed = string.trim(line)
      case string.is_empty(trimmed) {
        True -> {
          let new_acc = case current_idx >= 0 && current_rows != [] {
            True -> dict.insert(acc, current_idx, rows_to_shape(current_rows))
            False -> acc
          }
          parse_shapes_loop(rest, new_acc, current_idx, [])
        }
        False -> {
          case parse_shape_header(line) {
            Ok(idx) -> {
              let new_acc = case current_idx >= 0 && current_rows != [] {
                True ->
                  dict.insert(acc, current_idx, rows_to_shape(current_rows))
                False -> acc
              }
              parse_shapes_loop(rest, new_acc, idx, [])
            }
            Error(_) -> {
              parse_shapes_loop(
                rest,
                acc,
                current_idx,
                list.append(current_rows, [line]),
              )
            }
          }
        }
      }
    }
  }
}

fn parse_shape_header(line: String) -> Result(Int, Nil) {
  let trimmed = string.trim(line)
  case string.ends_with(trimmed, ":") {
    False -> Error(Nil)
    True -> {
      trimmed
      |> string.drop_end(1)
      |> int.parse
    }
  }
}

fn rows_to_shape(rows: List(String)) -> Shape {
  rows
  |> list.index_fold(set.new(), fn(shape, row, r) {
    row
    |> string.to_graphemes
    |> list.index_fold(shape, fn(s, char, c) {
      case char == "#" {
        True -> set.insert(s, #(r, c))
        False -> s
      }
    })
  })
}

fn parse_regions(lines: List(String)) -> List(Region) {
  lines
  |> list.filter_map(parse_region_line)
}

fn parse_region_line(line: String) -> Result(Region, Nil) {
  let trimmed = string.trim(line)
  case string.split_once(trimmed, ":") {
    Error(_) -> Error(Nil)
    Ok(#(dims, counts_str)) -> {
      use #(width, height) <- result.try(parse_dimensions(dims))

      let counts =
        counts_str
        |> string.trim
        |> string.split(" ")
        |> list.filter(fn(s) { !string.is_empty(string.trim(s)) })
        |> list.filter_map(fn(s) { int.parse(string.trim(s)) })

      let requirements =
        counts
        |> list.index_map(fn(count, idx) { #(idx, count) })
        |> list.filter(fn(pair) { pair.1 > 0 })

      Ok(Region(width:, height:, requirements:))
    }
  }
}

fn parse_dimensions(s: String) -> Result(#(Int, Int), Nil) {
  case string.split_once(string.trim(s), "x") {
    Error(_) -> Error(Nil)
    Ok(#(w_str, h_str)) -> {
      use w <- result.try(int.parse(w_str))
      use h <- result.try(int.parse(h_str))
      Ok(#(w, h))
    }
  }
}

// ============================================================================
// Part 1: Count regions where total shape area <= region area
// ============================================================================

pub fn part1(input: Input) -> Int {
  input.regions
  |> list.filter(fn(region) { can_fit_by_area(input.shapes, region) })
  |> list.length
}

fn can_fit_by_area(shapes: Dict(Int, Shape), region: Region) -> Bool {
  let region_area = region.width * region.height

  let total_shape_area =
    region.requirements
    |> list.fold(0, fn(acc, req) {
      let #(shape_idx, count) = req
      let shape_size = case dict.get(shapes, shape_idx) {
        Ok(s) -> set.size(s)
        Error(_) -> 0
      }
      acc + shape_size * count
    })

  total_shape_area <= region_area
}

// ============================================================================
// Part 2: Same as part 1
// ============================================================================

pub fn part2(input: Input) -> Int {
  part1(input)
}

// ============================================================================
// Run
// ============================================================================

pub fn run(input: String) -> #(Int, Int) {
  let parsed = parse(input)
  #(part1(parsed), part2(parsed))
}
