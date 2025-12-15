import gleam/float
import gleam/int
import gleam/list
import gleam/string
import gleam/time/duration
import gleam/time/timestamp

pub type BenchResult {
  BenchResult(avg_ns: Int, runs: Int)
}

/// Default number of benchmark iterations
pub const default_iterations = 100

/// Run function with 1 warmup + N iterations, return average time
pub fn run(iterations: Int, func: fn() -> a) -> BenchResult {
  // Warmup run (discarded)
  let _ = func()

  // Timed runs
  let total_ns =
    list.range(1, iterations)
    |> list.fold(0, fn(acc, _) {
      let start = timestamp.system_time()
      let _ = func()
      let end = timestamp.system_time()
      let diff = timestamp.difference(start, end)
      let #(secs, nanos) = duration.to_seconds_and_nanoseconds(diff)
      acc + secs * 1_000_000_000 + nanos
    })

  BenchResult(avg_ns: total_ns / iterations, runs: iterations)
}

/// Format benchmark result as human readable string
pub fn format(result: BenchResult) -> String {
  let time_str = format_ns(result.avg_ns)
  "avg " <> time_str <> ", " <> int.to_string(result.runs) <> " runs"
}

fn format_ns(ns: Int) -> String {
  case ns {
    // >= 1 second
    n if n >= 1_000_000_000 -> {
      let secs = int.to_float(n) /. 1_000_000_000.0
      float_to_string(secs, 2) <> "s"
    }
    // >= 1 millisecond
    n if n >= 1_000_000 -> {
      let ms = int.to_float(n) /. 1_000_000.0
      float_to_string(ms, 2) <> "ms"
    }
    // >= 1 microsecond
    n if n >= 1000 -> {
      let us = int.to_float(n) /. 1000.0
      float_to_string(us, 2) <> "µs"
    }
    // nanoseconds
    n -> int.to_string(n) <> "ns"
  }
}

fn float_to_string(f: Float, decimals: Int) -> String {
  let multiplier = pow10(decimals)
  let rounded = float.round(f *. int.to_float(multiplier))
  let int_part = rounded / multiplier
  let frac_part = int.absolute_value(rounded % multiplier)
  int.to_string(int_part)
  <> "."
  <> pad_left(int.to_string(frac_part), decimals, "0")
}

fn pow10(n: Int) -> Int {
  case n {
    0 -> 1
    _ -> 10 * pow10(n - 1)
  }
}

fn pad_left(s: String, len: Int, pad: String) -> String {
  case len - string.length(s) {
    n if n <= 0 -> s
    n -> string.repeat(pad, n) <> s
  }
}
