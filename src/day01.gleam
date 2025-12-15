import gleam/int
import gleam/list
import gleam/result
import gleam/string

pub type Direction {
  Left
  Right
}

pub type Rotation {
  Rotation(dir: Direction, dist: Int)
}

pub fn parse_rotation(line: String) -> Result(Rotation, Nil) {
  let trimmed = string.trim(line)
  case string.pop_grapheme(trimmed) {
    Ok(#("L", rest)) -> {
      use dist <- result.try(int.parse(rest))
      Ok(Rotation(Left, dist))
    }
    Ok(#("R", rest)) -> {
      use dist <- result.try(int.parse(rest))
      Ok(Rotation(Right, dist))
    }
    _ -> Error(Nil)
  }
}

pub fn parse_input(input: String) -> List(Rotation) {
  input
  |> string.split("\n")
  |> list.filter_map(parse_rotation)
}

fn mod100(n: Int) -> Int {
  let m = n % 100
  case m < 0 {
    True -> m + 100
    False -> m
  }
}

pub fn part1(input: String) -> Int {
  let rotations = parse_input(input)
  let start_pos = 50

  // Count times dial ENDS at 0 after each rotation
  let #(_, count) =
    list.fold(rotations, #(start_pos, 0), fn(acc, rot) {
      let #(pos, count) = acc
      let new_pos = case rot.dir {
        Left -> mod100(pos - rot.dist)
        Right -> mod100(pos + rot.dist)
      }
      let new_count = case new_pos == 0 {
        True -> count + 1
        False -> count
      }
      #(new_pos, new_count)
    })

  count
}

/// Count how many times we cross/land on 0 when moving in a direction
fn count_zeros_crossed(pos: Int, dist: Int, dir: Direction) -> Int {
  case dir {
    Left -> {
      // Moving left (decreasing): we hit 0 when we go from 1 to 0, or wrap from 0 to 99
      // Positions visited: pos-1, pos-2, ..., pos-dist (all mod 100)
      // We hit 0 when (pos - k) mod 100 == 0, for k in 1..dist
      // That means k = pos, pos+100, pos+200, ... while k <= dist
      case pos == 0 {
        True -> {
          // Starting at 0, going left: first step goes to 99, we don't hit 0
          // We hit 0 again at step 100, 200, etc.
          dist / 100
        }
        False -> {
          // First hit at step = pos (if pos <= dist)
          // Then every 100 steps after
          case pos <= dist {
            True -> 1 + { dist - pos } / 100
            False -> 0
          }
        }
      }
    }
    Right -> {
      // Moving right (increasing): we hit 0 when we wrap from 99 to 0
      // Positions visited: pos+1, pos+2, ..., pos+dist (all mod 100)
      // We hit 0 when (pos + k) mod 100 == 0, for k in 1..dist
      // That means k = 100-pos, 200-pos, ... while k <= dist and k > 0
      let first_hit = case pos == 0 {
        True -> 100
        False -> 100 - pos
      }
      case first_hit <= dist {
        True -> 1 + { dist - first_hit } / 100
        False -> 0
      }
    }
  }
}

pub fn part2(input: String) -> Int {
  let rotations = parse_input(input)
  let start_pos = 50

  let #(_, count) =
    list.fold(rotations, #(start_pos, 0), fn(acc, rot) {
      let #(pos, count) = acc
      let zeros = count_zeros_crossed(pos, rot.dist, rot.dir)
      let new_pos = case rot.dir {
        Left -> mod100(pos - rot.dist)
        Right -> mod100(pos + rot.dist)
      }
      #(new_pos, count + zeros)
    })

  count
}

pub fn run(input: String) -> #(Int, Int) {
  #(part1(input), part2(input))
}
