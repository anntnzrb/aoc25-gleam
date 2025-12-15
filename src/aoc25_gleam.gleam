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

pub fn main() {
  let args = argv.load().arguments
  let bench_mode = list.contains(args, "--bench")
  let args_filtered = list.filter(args, fn(a) { a != "--bench" })

  case args_filtered {
    ["all"] -> run_all(bench_mode)
    [day_str] -> {
      case run_day(day_str, bench_mode) {
        Ok(_) -> Nil
        Error(e) -> io.println("Error: " <> e)
      }
    }
    _ -> io.println("Usage: gleam run -- <day|all> [--bench]")
  }
}

fn run_all(bench_mode: Bool) -> Nil {
  let days = [1, 2, 3]
  list.each(days, fn(day) {
    case run_day(int.to_string(day), bench_mode) {
      Ok(_) -> Nil
      Error(e) -> io.println("Error on day " <> int.to_string(day) <> ": " <> e)
    }
    io.println("")
  })
}

fn run_day(day_str: String, bench_mode: Bool) -> Result(Nil, String) {
  use day <- result.try(
    int.parse(day_str)
    |> result.map_error(fn(_) { "Invalid day number" }),
  )
  use _ <- result.try(
    dotenv_gleam.config()
    |> result.map_error(fn(_) { "Failed to load .env" }),
  )
  use session <- result.try(
    envoy.get("AOC_SESSION")
    |> result.map_error(fn(_) { "AOC_SESSION not set" }),
  )

  // Fetch instructions (ignore errors, just nice to have)
  let _ = input.get_instructions(2025, day, session)

  // Fetch input
  use puzzle_input <- result.try(
    input.get_input(2025, day, session)
    |> result.map_error(fn(_) { "Failed to fetch input" }),
  )

  io.println("Day " <> int.to_string(day) <> ":")

  // Run the appropriate day
  case day, bench_mode {
    1, False -> {
      let parsed = day01.parse(puzzle_input)
      io.println("Part 1: " <> int.to_string(day01.part1(parsed)))
      io.println("Part 2: " <> int.to_string(day01.part2(parsed)))
      Ok(Nil)
    }
    1, True -> {
      let parsed = day01.parse(puzzle_input)
      let p1 = day01.part1(parsed)
      let b1 = bench.run(bench.default_iterations, fn() { day01.part1(parsed) })
      io.println(
        "Part 1: " <> int.to_string(p1) <> " (" <> bench.format(b1) <> ")",
      )
      let p2 = day01.part2(parsed)
      let b2 = bench.run(bench.default_iterations, fn() { day01.part2(parsed) })
      io.println(
        "Part 2: " <> int.to_string(p2) <> " (" <> bench.format(b2) <> ")",
      )
      Ok(Nil)
    }
    2, False -> {
      let parsed = day02.parse(puzzle_input)
      io.println("Part 1: " <> int.to_string(day02.part1(parsed)))
      io.println("Part 2: " <> int.to_string(day02.part2(parsed)))
      Ok(Nil)
    }
    2, True -> {
      let parsed = day02.parse(puzzle_input)
      let p1 = day02.part1(parsed)
      let b1 = bench.run(bench.default_iterations, fn() { day02.part1(parsed) })
      io.println(
        "Part 1: " <> int.to_string(p1) <> " (" <> bench.format(b1) <> ")",
      )
      let p2 = day02.part2(parsed)
      let b2 = bench.run(bench.default_iterations, fn() { day02.part2(parsed) })
      io.println(
        "Part 2: " <> int.to_string(p2) <> " (" <> bench.format(b2) <> ")",
      )
      Ok(Nil)
    }
    3, False -> {
      let parsed = day03.parse(puzzle_input)
      io.println("Part 1: " <> int.to_string(day03.part1(parsed)))
      io.println("Part 2: " <> int.to_string(day03.part2(parsed)))
      Ok(Nil)
    }
    3, True -> {
      let parsed = day03.parse(puzzle_input)
      let p1 = day03.part1(parsed)
      let b1 = bench.run(bench.default_iterations, fn() { day03.part1(parsed) })
      io.println(
        "Part 1: " <> int.to_string(p1) <> " (" <> bench.format(b1) <> ")",
      )
      let p2 = day03.part2(parsed)
      let b2 = bench.run(bench.default_iterations, fn() { day03.part2(parsed) })
      io.println(
        "Part 2: " <> int.to_string(p2) <> " (" <> bench.format(b2) <> ")",
      )
      Ok(Nil)
    }
    _, _ -> Error("Day " <> int.to_string(day) <> " not implemented")
  }
}
