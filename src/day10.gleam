import gleam/int
import gleam/list
import gleam/result
import gleam/string

// ============================================================================
// Types
// ============================================================================

pub type Machine {
  Machine(target: List(Bool), buttons: List(List(Int)), joltages: List(Int))
}

// ============================================================================
// Parsing - All on one line: [target] (btn1) (btn2) ... {jolt1,jolt2,...}
// ============================================================================

pub fn parse(input: String) -> List(Machine) {
  input
  |> string.trim
  |> string.split("\n")
  |> list.filter(fn(s) { !string.is_empty(string.trim(s)) })
  |> list.filter_map(parse_line)
}

fn parse_line(line: String) -> Result(Machine, Nil) {
  // Find target [...]
  use #(target, rest1) <- result.try(extract_target(line))

  // Find joltages {...}
  use #(joltages, rest2) <- result.try(extract_joltages(rest1))

  // Parse buttons (...)
  let buttons = extract_buttons(rest2)

  Ok(Machine(target:, buttons:, joltages:))
}

fn extract_target(line: String) -> Result(#(List(Bool), String), Nil) {
  use start <- result.try(string.split_once(line, "["))
  let #(_, after_bracket) = start
  use parts <- result.try(string.split_once(after_bracket, "]"))
  let #(target_str, rest) = parts

  let target =
    target_str
    |> string.to_graphemes
    |> list.map(fn(c) { c == "#" })

  Ok(#(target, rest))
}

fn extract_joltages(line: String) -> Result(#(List(Int), String), Nil) {
  case string.split_once(line, "{") {
    Error(_) -> Ok(#([], line))
    Ok(#(before, after)) -> {
      case string.split_once(after, "}") {
        Error(_) -> Ok(#([], line))
        Ok(#(jolt_str, _)) -> {
          let joltages =
            jolt_str
            |> string.split(",")
            |> list.filter_map(fn(s) { int.parse(string.trim(s)) })
          Ok(#(joltages, before))
        }
      }
    }
  }
}

fn extract_buttons(line: String) -> List(List(Int)) {
  // Find all (...) patterns
  extract_buttons_loop(line, [])
}

fn extract_buttons_loop(
  remaining: String,
  acc: List(List(Int)),
) -> List(List(Int)) {
  case string.split_once(remaining, "(") {
    Error(_) -> list.reverse(acc)
    Ok(#(_, after_open)) -> {
      case string.split_once(after_open, ")") {
        Error(_) -> list.reverse(acc)
        Ok(#(indices_str, rest)) -> {
          let indices =
            indices_str
            |> string.split(",")
            |> list.filter_map(fn(s) { int.parse(string.trim(s)) })
          extract_buttons_loop(rest, [indices, ..acc])
        }
      }
    }
  }
}

// ============================================================================
// Part 1: Minimum button presses (ignoring joltages)
// ============================================================================

pub fn part1(machines: List(Machine)) -> Int {
  machines
  |> list.map(solve_machine)
  |> int.sum
}

fn solve_machine(machine: Machine) -> Int {
  let n_lights = list.length(machine.target)
  let n_buttons = list.length(machine.buttons)

  case n_buttons {
    0 -> {
      case list.all(machine.target, fn(b) { !b }) {
        True -> 0
        False -> 0
      }
    }
    _ -> {
      let matrix = build_augmented_matrix(machine, n_lights, n_buttons)
      solve_gf2(matrix, n_buttons)
    }
  }
}

fn build_augmented_matrix(
  machine: Machine,
  _n_lights: Int,
  _n_buttons: Int,
) -> List(List(Int)) {
  list.index_map(machine.target, fn(target_bit, light_idx) {
    let button_cols =
      machine.buttons
      |> list.map(fn(btn_indices) {
        case list.contains(btn_indices, light_idx) {
          True -> 1
          False -> 0
        }
      })

    let target_col = case target_bit {
      True -> 1
      False -> 0
    }

    list.append(button_cols, [target_col])
  })
}

fn solve_gf2(matrix: List(List(Int)), n_buttons: Int) -> Int {
  let reduced = gaussian_elimination(matrix, 0, 0, n_buttons)
  find_min_solution(reduced, n_buttons)
}

fn gaussian_elimination(
  matrix: List(List(Int)),
  pivot_row: Int,
  pivot_col: Int,
  n_cols: Int,
) -> List(List(Int)) {
  let n_rows = list.length(matrix)

  case pivot_col >= n_cols || pivot_row >= n_rows {
    True -> matrix
    False -> {
      let pivot_idx = find_pivot(matrix, pivot_row, pivot_col)

      case pivot_idx {
        Error(_) -> {
          gaussian_elimination(matrix, pivot_row, pivot_col + 1, n_cols)
        }
        Ok(found_idx) -> {
          let m1 = swap_rows(matrix, pivot_row, found_idx)
          let m2 = eliminate_column(m1, pivot_row, pivot_col)
          gaussian_elimination(m2, pivot_row + 1, pivot_col + 1, n_cols)
        }
      }
    }
  }
}

fn find_pivot(
  matrix: List(List(Int)),
  start_row: Int,
  col: Int,
) -> Result(Int, Nil) {
  matrix
  |> list.index_map(fn(row, idx) { #(idx, row) })
  |> list.drop(start_row)
  |> list.find(fn(pair) {
    let #(_, row) = pair
    get_col(row, col) == 1
  })
  |> result.map(fn(pair) { pair.0 })
}

fn swap_rows(matrix: List(List(Int)), i: Int, j: Int) -> List(List(Int)) {
  case i == j {
    True -> matrix
    False -> {
      let row_i = get_row(matrix, i)
      let row_j = get_row(matrix, j)
      matrix
      |> list.index_map(fn(row, idx) {
        case idx == i {
          True -> row_j
          False ->
            case idx == j {
              True -> row_i
              False -> row
            }
        }
      })
    }
  }
}

fn eliminate_column(
  matrix: List(List(Int)),
  pivot_row: Int,
  col: Int,
) -> List(List(Int)) {
  let pivot = get_row(matrix, pivot_row)

  matrix
  |> list.index_map(fn(row, idx) {
    case idx == pivot_row {
      True -> row
      False -> {
        case get_col(row, col) == 1 {
          True -> xor_rows(row, pivot)
          False -> row
        }
      }
    }
  })
}

fn xor_rows(r1: List(Int), r2: List(Int)) -> List(Int) {
  list.map2(r1, r2, fn(a, b) { int.bitwise_exclusive_or(a, b) })
}

fn get_row(matrix: List(List(Int)), idx: Int) -> List(Int) {
  matrix |> list.drop(idx) |> list.first |> result.unwrap([])
}

fn get_col(row: List(Int), idx: Int) -> Int {
  row |> list.drop(idx) |> list.first |> result.unwrap(0)
}

fn find_min_solution(matrix: List(List(Int)), n_buttons: Int) -> Int {
  let pivot_info = get_pivot_info(matrix, n_buttons)

  let free_cols =
    list.range(0, n_buttons - 1)
    |> list.filter(fn(col) { !list.any(pivot_info, fn(p) { p.1 == col }) })

  let n_free = list.length(free_cols)

  case n_free > 15 {
    True -> {
      compute_solution_weight(matrix, pivot_info, n_buttons, 0)
    }
    False -> {
      list.range(0, power2(n_free) - 1)
      |> list.fold(n_buttons + 1, fn(min_w, mask) {
        let w = compute_solution_weight(matrix, pivot_info, n_buttons, mask)
        int.min(min_w, w)
      })
    }
  }
}

fn get_pivot_info(matrix: List(List(Int)), n_buttons: Int) -> List(#(Int, Int)) {
  matrix
  |> list.index_map(fn(row, row_idx) {
    let pivot_col =
      list.range(0, n_buttons - 1)
      |> list.find(fn(col) { get_col(row, col) == 1 })

    case pivot_col {
      Ok(col) -> Ok(#(row_idx, col))
      Error(_) -> Error(Nil)
    }
  })
  |> list.filter_map(fn(x) { x })
}

fn compute_solution_weight(
  matrix: List(List(Int)),
  pivot_info: List(#(Int, Int)),
  n_buttons: Int,
  free_mask: Int,
) -> Int {
  let pivot_cols = list.map(pivot_info, fn(p) { p.1 })
  let free_cols =
    list.range(0, n_buttons - 1)
    |> list.filter(fn(col) { !list.contains(pivot_cols, col) })

  let free_vals =
    free_cols
    |> list.index_map(fn(col, idx) {
      let bit = int.bitwise_and(int.bitwise_shift_right(free_mask, idx), 1)
      #(col, bit)
    })

  let solution =
    pivot_info
    |> list.reverse
    |> list.fold(free_vals, fn(sol, pivot) {
      let #(row_idx, pivot_col) = pivot
      let row = get_row(matrix, row_idx)

      let rhs = get_col(row, n_buttons)

      let contribution =
        sol
        |> list.fold(0, fn(acc, pair) {
          let #(col, val) = pair
          case col != pivot_col {
            True -> {
              let coef = get_col(row, col)
              int.bitwise_exclusive_or(acc, int.bitwise_and(coef, val))
            }
            False -> acc
          }
        })

      let pivot_val = int.bitwise_exclusive_or(rhs, contribution)
      [#(pivot_col, pivot_val), ..sol]
    })

  solution
  |> list.filter(fn(pair) { pair.1 == 1 })
  |> list.length
}

fn power2(n: Int) -> Int {
  int.bitwise_shift_left(1, n)
}

// ============================================================================
// Part 2: Minimum button presses to reach exact joltage counter values
// Buttons now INCREMENT counters (not toggle). Solve Ax = b with x >= 0.
// ============================================================================

pub fn part2(machines: List(Machine)) -> Int {
  machines
  |> list.map(solve_joltage_counters)
  |> int.sum
}

fn solve_joltage_counters(machine: Machine) -> Int {
  // Use proper Gaussian elimination with GCD normalization
  solve_linear_system_proper(machine)
}

fn solve_linear_system_proper(machine: Machine) -> Int {
  let n_buttons = list.length(machine.buttons)
  let n_counters = list.length(machine.joltages)

  case n_counters == 0 || n_buttons == 0 {
    True -> 0
    False -> {
      // Build augmented matrix [A | b]
      let matrix =
        machine.joltages
        |> list.index_map(fn(target, counter_idx) {
          let coeffs =
            machine.buttons
            |> list.map(fn(btn) {
              case list.contains(btn, counter_idx) {
                True -> 1
                False -> 0
              }
            })
          list.append(coeffs, [target])
        })

      // Gaussian elimination with GCD normalization
      let #(reduced, pivot_info) =
        gaussian_with_gcd(matrix, 0, 0, n_buttons, [])

      // Check for inconsistent equations (0 = non-zero)
      let has_inconsistency =
        reduced
        |> list.index_map(fn(row, row_idx) { #(row_idx, row) })
        |> list.any(fn(pair) {
          let #(row_idx, row) = pair
          let is_pivot_row = list.any(pivot_info, fn(p) { p.0 == row_idx })
          case is_pivot_row {
            True -> False
            False -> {
              // Non-pivot row: check if 0 = non-zero
              let rhs = row |> list.last |> result.unwrap(0)
              rhs != 0
            }
          }
        })

      case has_inconsistency {
        True -> 0
        False -> back_substitute_v2(reduced, pivot_info, n_buttons)
      }
    }
  }
}

fn gaussian_with_gcd(
  matrix: List(List(Int)),
  row: Int,
  col: Int,
  n_cols: Int,
  pivot_info: List(#(Int, Int)),
) -> #(List(List(Int)), List(#(Int, Int))) {
  // pivot_info is list of (row_idx, col_idx) pairs
  let n_rows = list.length(matrix)

  case col >= n_cols || row >= n_rows {
    True -> #(matrix, list.reverse(pivot_info))
    False -> {
      // Find pivot (non-zero entry in column)
      case find_pivot_row(matrix, row, col) {
        Error(_) -> {
          // No pivot in this column, move to next
          gaussian_with_gcd(matrix, row, col + 1, n_cols, pivot_info)
        }
        Ok(pivot_row) -> {
          // Swap rows if needed
          let m1 = case pivot_row == row {
            True -> matrix
            False -> swap_rows(matrix, row, pivot_row)
          }

          // Eliminate other entries in this column
          let m2 = eliminate_col_gcd(m1, row, col)

          gaussian_with_gcd(m2, row + 1, col + 1, n_cols, [
            #(row, col),
            ..pivot_info
          ])
        }
      }
    }
  }
}

fn find_pivot_row(
  matrix: List(List(Int)),
  start_row: Int,
  col: Int,
) -> Result(Int, Nil) {
  matrix
  |> list.index_map(fn(r, i) { #(i, r) })
  |> list.drop(start_row)
  |> list.find(fn(pair) {
    let val = list.drop(pair.1, col) |> list.first |> result.unwrap(0)
    val != 0
  })
  |> result.map(fn(pair) { pair.0 })
}

fn eliminate_col_gcd(
  matrix: List(List(Int)),
  pivot_row: Int,
  col: Int,
) -> List(List(Int)) {
  let pivot_row_data = get_row(matrix, pivot_row)
  let pivot_val =
    pivot_row_data |> list.drop(col) |> list.first |> result.unwrap(0)

  matrix
  |> list.index_map(fn(row, idx) {
    case idx == pivot_row {
      True -> normalize_row(row)
      False -> {
        let row_val = row |> list.drop(col) |> list.first |> result.unwrap(0)
        case row_val == 0 {
          True -> row
          False -> {
            // row = row * pivot_val - pivot_row * row_val
            let new_row =
              list.map2(row, pivot_row_data, fn(r, p) {
                r * pivot_val - p * row_val
              })
            normalize_row(new_row)
          }
        }
      }
    }
  })
}

fn normalize_row(row: List(Int)) -> List(Int) {
  let g = row |> list.fold(0, gcd)
  let divided = case g <= 1 {
    True -> row
    False -> row |> list.map(fn(x) { x / g })
  }

  // Ensure leading non-zero is positive
  let first_nonzero =
    divided
    |> list.find(fn(x) { x != 0 })
    |> result.unwrap(1)
  case first_nonzero < 0 {
    True -> divided |> list.map(fn(x) { -x })
    False -> divided
  }
}

fn gcd(a: Int, b: Int) -> Int {
  let abs_a = case a < 0 {
    True -> -a
    False -> a
  }
  let abs_b = case b < 0 {
    True -> -b
    False -> b
  }
  gcd_helper(abs_a, abs_b)
}

fn gcd_helper(a: Int, b: Int) -> Int {
  case b == 0 {
    True -> a
    False -> gcd_helper(b, a % b)
  }
}

fn back_substitute_v2(
  matrix: List(List(Int)),
  pivot_info: List(#(Int, Int)),
  n_buttons: Int,
) -> Int {
  // Identify free variables (columns not in pivot_info)
  let pivot_cols = list.map(pivot_info, fn(p) { p.1 })
  let free_cols =
    list.range(0, n_buttons - 1)
    |> list.filter(fn(c) { !list.contains(pivot_cols, c) })

  case free_cols {
    [] -> {
      // No free variables, just do direct back substitution
      try_back_substitute_v2(matrix, pivot_info, n_buttons, [])
    }
    _ -> {
      // Has free variables - ALWAYS explore to find minimum
      explore_free_vars_v2(matrix, pivot_info, n_buttons, free_cols)
    }
  }
}

fn try_back_substitute_v2(
  matrix: List(List(Int)),
  pivot_info: List(#(Int, Int)),
  n_buttons: Int,
  free_vals: List(#(Int, Int)),
) -> Int {
  // Start with free variables set
  let initial_solution =
    list.range(0, n_buttons - 1)
    |> list.map(fn(i) {
      case list.find(free_vals, fn(p) { p.0 == i }) {
        Ok(#(_, v)) -> v
        Error(_) -> 0
      }
    })

  // For each pivot row (from bottom to top), solve for pivot variable
  let #(solution, valid) =
    pivot_info
    |> list.reverse
    |> list.fold(#(initial_solution, True), fn(acc, pair) {
      let #(sol, is_valid) = acc
      case is_valid {
        False -> acc
        True -> {
          let #(row_idx, pivot_col) = pair
          let row = get_row(matrix, row_idx)
          let pivot_val =
            row |> list.drop(pivot_col) |> list.first |> result.unwrap(0)
          let rhs = row |> list.last |> result.unwrap(0)

          // Compute contribution from other variables
          let contribution =
            sol
            |> list.index_fold(0, fn(sum, val, idx) {
              case idx == pivot_col {
                True -> sum
                False -> {
                  let coef =
                    row |> list.drop(idx) |> list.first |> result.unwrap(0)
                  sum + coef * val
                }
              }
            })

          let numerator = rhs - contribution
          case pivot_val != 0 && numerator % pivot_val == 0 {
            True -> {
              let x = numerator / pivot_val
              case x >= 0 {
                True -> {
                  let new_sol =
                    sol
                    |> list.index_map(fn(v, i) {
                      case i == pivot_col {
                        True -> x
                        False -> v
                      }
                    })
                  #(new_sol, True)
                }
                False -> #(sol, False)
              }
            }
            False -> #(sol, False)
          }
        }
      }
    })

  case valid {
    True -> solution |> int.sum
    False -> 999_999_999
  }
}

fn explore_free_vars_v2(
  matrix: List(List(Int)),
  pivot_info: List(#(Int, Int)),
  n_buttons: Int,
  free_cols: List(Int),
) -> Int {
  let max_rhs =
    matrix
    |> list.map(fn(row) { row |> list.last |> result.unwrap(0) })
    |> list.fold(0, fn(a, b) { int.max(a, int.absolute_value(b)) })

  let n_free = list.length(free_cols)

  case n_free {
    0 -> try_back_substitute_v2(matrix, pivot_info, n_buttons, [])
    1 -> {
      // Single free var: just iterate
      let col = case free_cols {
        [c, ..] -> c
        [] -> 0
      }
      explore_single_loop(
        matrix,
        pivot_info,
        n_buttons,
        col,
        0,
        max_rhs,
        999_999_999,
      )
    }
    _ -> {
      // Multiple free vars: try zeros first to get a bound
      let zeros_vals = free_cols |> list.map(fn(c) { #(c, 0) })
      let zeros_result =
        try_back_substitute_v2(matrix, pivot_info, n_buttons, zeros_vals)
      // Use bounds based on number of free vars
      let max_per_var = case n_free {
        2 -> int.min(max_rhs, 200)
        _ -> int.min(max_rhs, 100)
      }
      // Use zeros result as bound if valid
      case zeros_result < 999_999_999 {
        True -> {
          // Found valid with zeros, search for better with tight bound
          let bound = int.min(max_per_var, zeros_result)
          explore_multi_free(
            matrix,
            pivot_info,
            n_buttons,
            free_cols,
            bound,
            [],
            zeros_result,
            0,
          )
        }
        False -> {
          // No solution with zeros, need full search
          explore_multi_free(
            matrix,
            pivot_info,
            n_buttons,
            free_cols,
            max_per_var,
            [],
            999_999_999,
            0,
          )
        }
      }
    }
  }
}

fn explore_single_loop(
  matrix: List(List(Int)),
  pivot_info: List(#(Int, Int)),
  n_buttons: Int,
  col: Int,
  val: Int,
  max_val: Int,
  best: Int,
) -> Int {
  case val > max_val || val >= best {
    True -> best
    False -> {
      let result =
        try_back_substitute_v2(matrix, pivot_info, n_buttons, [#(col, val)])
      let new_best = int.min(best, result)
      explore_single_loop(
        matrix,
        pivot_info,
        n_buttons,
        col,
        val + 1,
        max_val,
        new_best,
      )
    }
  }
}

fn explore_multi_free(
  matrix: List(List(Int)),
  pivot_info: List(#(Int, Int)),
  n_buttons: Int,
  remaining: List(Int),
  max_per_var: Int,
  current_vals: List(#(Int, Int)),
  best: Int,
  current_sum: Int,
) -> Int {
  case current_sum >= best {
    True -> best
    False -> {
      case remaining {
        [] -> {
          let result =
            try_back_substitute_v2(matrix, pivot_info, n_buttons, current_vals)
          int.min(best, result)
        }
        [col, ..rest] -> {
          explore_multi_loop(
            matrix,
            pivot_info,
            n_buttons,
            col,
            rest,
            max_per_var,
            current_vals,
            best,
            current_sum,
            0,
          )
        }
      }
    }
  }
}

fn explore_multi_loop(
  matrix: List(List(Int)),
  pivot_info: List(#(Int, Int)),
  n_buttons: Int,
  col: Int,
  rest: List(Int),
  max_per_var: Int,
  current_vals: List(#(Int, Int)),
  best: Int,
  current_sum: Int,
  val: Int,
) -> Int {
  case val > max_per_var || current_sum + val >= best {
    True -> best
    False -> {
      let new_vals = [#(col, val), ..current_vals]
      let new_best =
        explore_multi_free(
          matrix,
          pivot_info,
          n_buttons,
          rest,
          max_per_var,
          new_vals,
          best,
          current_sum + val,
        )
      explore_multi_loop(
        matrix,
        pivot_info,
        n_buttons,
        col,
        rest,
        max_per_var,
        current_vals,
        new_best,
        current_sum,
        val + 1,
      )
    }
  }
}

// ============================================================================
// Run
// ============================================================================

pub fn run(input: String) -> #(Int, Int) {
  let parsed = parse(input)
  #(part1(parsed), part2(parsed))
}
