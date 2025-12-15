import aoc/bench
import aoc/input
import argv
import day01
import day02
import day03
import dotenv_gleam
import envoy
import gleam/int
import gleam/io
import gleam/list
import gleam/result

// ---------------------------------------------------------------------------
// CLI entry point
// ---------------------------------------------------------------------------

pub fn main() {
  let #(args, bench_mode) = argv.load().arguments |> parse_args

  case args {
    ["all"] -> run_all(bench_mode)
    [day_str] -> day_str |> run_day(bench_mode) |> handle_result
    _ -> io.println("Usage: gleam run -- <day|all> [--bench]")
  }
}

fn parse_args(args: List(String)) -> #(List(String), Bool) {
  let bench_mode = args |> list.contains("--bench")
  let filtered = args |> list.filter(fn(a) { a != "--bench" })
  #(filtered, bench_mode)
}

fn handle_result(result: Result(Nil, String)) -> Nil {
  case result {
    Ok(_) -> Nil
    Error(e) -> { "Error: " <> e } |> io.println
  }
}

// ---------------------------------------------------------------------------
// Run all days
// ---------------------------------------------------------------------------

fn run_all(bench_mode: Bool) -> Nil {
  list.range(1, 12)
  |> list.each(fn(day) {
    day
    |> int.to_string
    |> run_day(bench_mode)
    |> handle_day_result(day)

    io.println("")
  })
}

fn handle_day_result(result: Result(Nil, String), day: Int) -> Nil {
  case result {
    Ok(_) -> Nil
    Error(e) ->
      { "Error on day " <> int.to_string(day) <> ": " <> e } |> io.println
  }
}

// ---------------------------------------------------------------------------
// Day execution
// ---------------------------------------------------------------------------

fn execute(
  run: fn(String) -> #(Int, Int),
  input: String,
  bench_mode: Bool,
) -> Nil {
  let #(p1, p2) = run(input)
  case bench_mode {
    False -> {
      { "Part 1: " <> int.to_string(p1) } |> io.println
      { "Part 2: " <> int.to_string(p2) } |> io.println
    }
    True -> {
      let b = bench.run(bench.default_iterations, fn() { run(input) })
      { "Part 1: " <> int.to_string(p1) } |> io.println
      { "Part 2: " <> int.to_string(p2) } |> io.println
      { "Total: " <> bench.format(b) } |> io.println
    }
  }
}

// ---------------------------------------------------------------------------
// Configuration and input loading
// ---------------------------------------------------------------------------

fn load_session() -> Result(String, String) {
  use _ <- result.try(
    dotenv_gleam.config()
    |> result.map_error(fn(_) { "Failed to load .env" }),
  )
  envoy.get("AOC_SESSION")
  |> result.map_error(fn(_) { "AOC_SESSION not set" })
}

fn fetch_input(day: Int, session: String) -> Result(String, String) {
  let _ = input.get_instructions(2025, day, session)
  input.get_input(2025, day, session)
  |> result.map_error(fn(_) { "Failed to fetch input" })
}

// ---------------------------------------------------------------------------
// Day dispatch
// ---------------------------------------------------------------------------

fn solvers() -> List(fn(String) -> #(Int, Int)) {
  [day01.run, day02.run, day03.run]
}

fn dispatch_day(
  day: Int,
  input: String,
  bench_mode: Bool,
) -> Result(Nil, String) {
  solvers()
  |> list.drop(day - 1)
  |> list.first
  |> result.map_error(fn(_) {
    "Day " <> int.to_string(day) <> " not implemented"
  })
  |> result.map(fn(run) { execute(run, input, bench_mode) })
}

fn run_day(day_str: String, bench_mode: Bool) -> Result(Nil, String) {
  use day <- result.try(
    day_str
    |> int.parse
    |> result.map_error(fn(_) { "Invalid day number" }),
  )
  use session <- result.try(load_session())
  use puzzle_input <- result.try(fetch_input(day, session))

  { "Day " <> int.to_string(day) <> ":" } |> io.println
  dispatch_day(day, puzzle_input, bench_mode)
}
