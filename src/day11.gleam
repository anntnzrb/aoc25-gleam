import gleam/dict.{type Dict}
import gleam/list
import gleam/string

// ============================================================================
// Types
// ============================================================================

pub type Graph =
  Dict(String, List(String))

// ============================================================================
// Parsing
// ============================================================================

pub fn parse(input: String) -> Graph {
  input
  |> string.trim
  |> string.split("\n")
  |> list.filter(fn(s) { !string.is_empty(string.trim(s)) })
  |> list.fold(dict.new(), fn(graph, line) {
    case parse_line(line) {
      Error(_) -> graph
      Ok(#(node, outputs)) -> dict.insert(graph, node, outputs)
    }
  })
}

fn parse_line(line: String) -> Result(#(String, List(String)), Nil) {
  case string.split(line, ":") {
    [name, rest] -> {
      let outputs =
        rest
        |> string.trim
        |> string.split(" ")
        |> list.filter(fn(s) { !string.is_empty(string.trim(s)) })
        |> list.map(string.trim)
      Ok(#(string.trim(name), outputs))
    }
    _ -> Error(Nil)
  }
}

// ============================================================================
// Part 1: Count all paths from "you" to "out" (DAG - memoization)
// ============================================================================

pub fn part1(graph: Graph) -> Int {
  count_paths_dag(graph, "you", "out", dict.new()).0
}

fn count_paths_dag(
  graph: Graph,
  from: String,
  to: String,
  memo: Dict(String, Int),
) -> #(Int, Dict(String, Int)) {
  case from == to {
    True -> #(1, memo)
    False -> {
      case dict.get(memo, from) {
        Ok(cached) -> #(cached, memo)
        Error(_) -> {
          let neighbors = dict.get(graph, from) |> unwrap_or([])

          let #(total, new_memo) =
            neighbors
            |> list.fold(#(0, memo), fn(acc, neighbor) {
              let #(sum, m) = acc
              let #(paths, m2) = count_paths_dag(graph, neighbor, to, m)
              #(sum + paths, m2)
            })

          #(total, dict.insert(new_memo, from, total))
        }
      }
    }
  }
}

fn unwrap_or(result: Result(a, b), default: a) -> a {
  case result {
    Ok(value) -> value
    Error(_) -> default
  }
}

// ============================================================================
// Part 2: Count paths from "svr" to "out" that visit both "dac" AND "fft"
// ============================================================================

pub fn part2(graph: Graph) -> Int {
  // Paths that visit both dac and fft can either:
  // 1. Visit dac before fft: svr -> dac -> fft -> out
  // 2. Visit fft before dac: svr -> fft -> dac -> out

  let paths_svr_dac = count_paths(graph, "svr", "dac")
  let paths_dac_fft = count_paths(graph, "dac", "fft")
  let paths_fft_out = count_paths(graph, "fft", "out")

  let paths_svr_fft = count_paths(graph, "svr", "fft")
  let paths_fft_dac = count_paths(graph, "fft", "dac")
  let paths_dac_out = count_paths(graph, "dac", "out")

  // dac before fft
  let dac_first = paths_svr_dac * paths_dac_fft * paths_fft_out
  // fft before dac
  let fft_first = paths_svr_fft * paths_fft_dac * paths_dac_out

  dac_first + fft_first
}

fn count_paths(graph: Graph, from: String, to: String) -> Int {
  count_paths_dag(graph, from, to, dict.new()).0
}

// ============================================================================
// Run
// ============================================================================

pub fn run(input: String) -> #(Int, Int) {
  let parsed = parse(input)
  #(part1(parsed), part2(parsed))
}
