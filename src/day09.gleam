import gleam/int
import gleam/list
import gleam/result
import gleam/set.{type Set}
import gleam/string

pub type Point {
  Point(x: Int, y: Int)
}

pub fn parse(input: String) -> List(Point) {
  input
  |> string.trim
  |> string.split("\n")
  |> list.filter_map(fn(line) {
    case string.split(line, ",") {
      [x_str, y_str] -> {
        use x <- result.try(int.parse(string.trim(x_str)))
        use y <- result.try(int.parse(string.trim(y_str)))
        Ok(Point(x, y))
      }
      _ -> Error(Nil)
    }
  })
}

fn rect_area(p1: Point, p2: Point) -> Int {
  let width = int.absolute_value(p2.x - p1.x) + 1
  let height = int.absolute_value(p2.y - p1.y) + 1
  width * height
}

pub fn part1(points: List(Point)) -> Int {
  points
  |> list.combination_pairs
  |> list.fold(0, fn(max_area, pair) {
    let #(p1, p2) = pair
    int.max(max_area, rect_area(p1, p2))
  })
}

/// Compact polygon data
pub type PolygonData {
  PolygonData(
    red_set: Set(#(Int, Int)),
    // Sorted horizontal edges by y: #(y, x1, x2)
    h_edges_sorted: List(#(Int, Int, Int)),
    // Sorted vertical edges by x: #(x, y1, y2)
    v_edges_sorted: List(#(Int, Int, Int)),
    polygon_pairs: List(#(Point, Point)),
  )
}

fn build_polygon_data(points: List(Point)) -> PolygonData {
  let red_set =
    points
    |> list.map(fn(p) { #(p.x, p.y) })
    |> set.from_list

  let polygon_pairs = consecutive_pairs(points)

  // Build and sort edges
  let #(h_edges, v_edges) = build_edge_lists(points)

  PolygonData(
    red_set:,
    h_edges_sorted: h_edges
      |> list.sort(fn(a, b) {
        let #(y1, _, _) = a
        let #(y2, _, _) = b
        int.compare(y1, y2)
      }),
    v_edges_sorted: v_edges
      |> list.sort(fn(a, b) {
        let #(x1, _, _) = a
        let #(x2, _, _) = b
        int.compare(x1, x2)
      }),
    polygon_pairs:,
  )
}

fn build_edge_lists(
  points: List(Point),
) -> #(List(#(Int, Int, Int)), List(#(Int, Int, Int))) {
  case points {
    [] | [_] -> #([], [])
    [first, ..] -> {
      let last = list.last(points) |> result.unwrap(first)
      let pairs = list.window_by_2(points)
      let all_pairs = list.append(pairs, [#(last, first)])

      all_pairs
      |> list.fold(#([], []), fn(acc, pair) {
        let #(h_list, v_list) = acc
        let #(pa, pb) = pair
        case pa.y == pb.y {
          True -> {
            let y = pa.y
            let x1 = int.min(pa.x, pb.x)
            let x2 = int.max(pa.x, pb.x)
            #([#(y, x1, x2), ..h_list], v_list)
          }
          False -> {
            let x = pa.x
            let y1 = int.min(pa.y, pb.y)
            let y2 = int.max(pa.y, pb.y)
            #(h_list, [#(x, y1, y2), ..v_list])
          }
        }
      })
    }
  }
}

pub fn part2(points: List(Point)) -> Int {
  case points {
    [] | [_] -> 0
    _ -> {
      let data = build_polygon_data(points)

      points
      |> list.combination_pairs
      |> list.fold(0, fn(max_area, pair) {
        let #(p1, p2) = pair
        case is_valid_rectangle_fast(p1, p2, data) {
          True -> int.max(max_area, rect_area(p1, p2))
          False -> max_area
        }
      })
    }
  }
}

/// Fast rectangle validation - check edge crossing FIRST (most likely fail case)
fn is_valid_rectangle_fast(p1: Point, p2: Point, data: PolygonData) -> Bool {
  let min_x = int.min(p1.x, p2.x)
  let max_x = int.max(p1.x, p2.x)
  let min_y = int.min(p1.y, p2.y)
  let max_y = int.max(p1.y, p2.y)

  // Check edge crossing FIRST - most rectangles fail here
  case
    has_edge_crossing(
      min_x,
      max_x,
      min_y,
      max_y,
      data.h_edges_sorted,
      data.v_edges_sorted,
    )
  {
    True -> False
    False -> {
      // Only 2 corners to check (p1 and p2 are red tiles)
      let other_corners = get_other_corners(p1, p2, min_x, max_x, min_y, max_y)

      other_corners
      |> list.all(fn(corner) { is_inside_or_on_fast(corner, data) })
    }
  }
}

fn get_other_corners(
  p1: Point,
  _p2: Point,
  min_x: Int,
  max_x: Int,
  min_y: Int,
  max_y: Int,
) -> List(Point) {
  case p1.x == min_x && p1.y == min_y {
    True -> [Point(min_x, max_y), Point(max_x, min_y)]
    False ->
      case p1.x == min_x && p1.y == max_y {
        True -> [Point(min_x, min_y), Point(max_x, max_y)]
        False ->
          case p1.x == max_x && p1.y == min_y {
            True -> [Point(min_x, min_y), Point(max_x, max_y)]
            False -> [Point(min_x, max_y), Point(max_x, min_y)]
          }
      }
  }
}

fn has_edge_crossing(
  min_x: Int,
  max_x: Int,
  min_y: Int,
  max_y: Int,
  h_edges: List(#(Int, Int, Int)),
  v_edges: List(#(Int, Int, Int)),
) -> Bool {
  // Check horizontal edges - stop early if y > max_y (sorted by y)
  let h_crossing = check_h_edges_sorted(h_edges, min_x, max_x, min_y, max_y)

  case h_crossing {
    True -> True
    False -> check_v_edges_sorted(v_edges, min_x, max_x, min_y, max_y)
  }
}

fn check_h_edges_sorted(
  edges: List(#(Int, Int, Int)),
  min_x: Int,
  max_x: Int,
  min_y: Int,
  max_y: Int,
) -> Bool {
  case edges {
    [] -> False
    [#(y, x1, x2), ..rest] -> {
      case y >= max_y {
        True -> False
        // Early exit - all remaining edges have y >= max_y
        False -> {
          case y > min_y && x1 < max_x && x2 > min_x {
            True -> True
            False -> check_h_edges_sorted(rest, min_x, max_x, min_y, max_y)
          }
        }
      }
    }
  }
}

fn check_v_edges_sorted(
  edges: List(#(Int, Int, Int)),
  min_x: Int,
  max_x: Int,
  min_y: Int,
  max_y: Int,
) -> Bool {
  case edges {
    [] -> False
    [#(x, y1, y2), ..rest] -> {
      case x >= max_x {
        True -> False
        // Early exit - all remaining edges have x >= max_x
        False -> {
          case x > min_x && y1 < max_y && y2 > min_y {
            True -> True
            False -> check_v_edges_sorted(rest, min_x, max_x, min_y, max_y)
          }
        }
      }
    }
  }
}

fn is_inside_or_on_fast(point: Point, data: PolygonData) -> Bool {
  // Check if it's a red tile
  case set.contains(data.red_set, #(point.x, point.y)) {
    True -> True
    False -> {
      // Check if on any horizontal edge
      let on_h =
        data.h_edges_sorted
        |> list.any(fn(e) {
          let #(y, x1, x2) = e
          point.y == y && point.x >= x1 && point.x <= x2
        })
      case on_h {
        True -> True
        False -> {
          // Check if on any vertical edge
          let on_v =
            data.v_edges_sorted
            |> list.any(fn(e) {
              let #(x, y1, y2) = e
              point.x == x && point.y >= y1 && point.y <= y2
            })
          case on_v {
            True -> True
            False -> is_inside_polygon_fast(point, data.polygon_pairs)
          }
        }
      }
    }
  }
}

fn is_inside_polygon_fast(point: Point, pairs: List(#(Point, Point))) -> Bool {
  let crossings =
    pairs
    |> list.count(fn(pair) {
      let #(e1, e2) = pair
      ray_crosses_edge(point, e1, e2)
    })
  crossings % 2 == 1
}

fn consecutive_pairs(points: List(Point)) -> List(#(Point, Point)) {
  case points {
    [] | [_] -> []
    [first, ..] -> {
      let last = list.last(points) |> result.unwrap(first)
      let pairs = list.window_by_2(points)
      list.append(pairs, [#(last, first)])
    }
  }
}

fn ray_crosses_edge(point: Point, e1: Point, e2: Point) -> Bool {
  let #(low, high) = case e1.y <= e2.y {
    True -> #(e1, e2)
    False -> #(e2, e1)
  }

  // Early exit for horizontal edges
  case low.y == high.y {
    True -> False
    False -> {
      case point.y >= low.y && point.y < high.y {
        False -> False
        True -> {
          // For vertical polygon edges (common case), check is simple
          case low.x == high.x {
            True -> point.x < low.x
            False -> {
              let t =
                int.to_float(point.y - low.y) /. int.to_float(high.y - low.y)
              let x_intersect =
                int.to_float(low.x) +. t *. int.to_float(high.x - low.x)
              int.to_float(point.x) <. x_intersect
            }
          }
        }
      }
    }
  }
}

pub fn run(input: String) -> #(Int, Int) {
  let parsed = parse(input)
  #(part1(parsed), part2(parsed))
}
