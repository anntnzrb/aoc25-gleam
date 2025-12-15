import aoc/input
import argv
import day01
import day02
import day03
import dotenv_gleam
import envoy
import gleam/int
import gleam/io
import gleam/result

pub fn main() {
  case argv.load().arguments {
    [day_str] -> {
      case run_day(day_str) {
        Ok(_) -> Nil
        Error(e) -> io.println("Error: " <> e)
      }
    }
    _ -> io.println("Usage: gleam run -- <day>")
  }
}

fn run_day(day_str: String) -> Result(Nil, String) {
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

  // Run the appropriate day
  case day {
    1 -> {
      let #(p1, p2) = day01.run(puzzle_input)
      io.println("Part 1: " <> int.to_string(p1))
      io.println("Part 2: " <> int.to_string(p2))
      Ok(Nil)
    }
    2 -> {
      let #(p1, p2) = day02.run(puzzle_input)
      io.println("Part 1: " <> int.to_string(p1))
      io.println("Part 2: " <> int.to_string(p2))
      Ok(Nil)
    }
    3 -> {
      let #(p1, p2) = day03.run(puzzle_input)
      io.println("Part 1: " <> int.to_string(p1))
      io.println("Part 2: " <> int.to_string(p2))
      Ok(Nil)
    }
    _ -> Error("Day " <> int.to_string(day) <> " not implemented")
  }
}
