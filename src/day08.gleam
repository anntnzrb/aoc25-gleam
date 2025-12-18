import gleam/dict.{type Dict}
import gleam/int
import gleam/list
import gleam/result
import gleam/string

pub type Point {
  Point(x: Int, y: Int, z: Int)
}

pub fn parse(input: String) -> List(Point) {
  input
  |> string.trim
  |> string.split("\n")
  |> list.filter_map(fn(line) {
    case string.split(line, ",") {
      [x_str, y_str, z_str] -> {
        use x <- result.try(int.parse(string.trim(x_str)))
        use y <- result.try(int.parse(string.trim(y_str)))
        use z <- result.try(int.parse(string.trim(z_str)))
        Ok(Point(x, y, z))
      }
      _ -> Error(Nil)
    }
  })
}

fn distance_squared(a: Point, b: Point) -> Int {
  let dx = a.x - b.x
  let dy = a.y - b.y
  let dz = a.z - b.z
  dx * dx + dy * dy + dz * dz
}

/// Generate and sort all pairs - using list directly for faster access
fn all_pairs_sorted(points: List(Point)) -> List(#(Int, Int, Int)) {
  let indexed = list.index_map(points, fn(p, i) { #(i, p) })

  indexed
  |> list.flat_map(fn(ip) {
    let #(i, p1) = ip
    indexed
    |> list.filter_map(fn(jp) {
      let #(j, p2) = jp
      case j > i {
        True -> Ok(#(distance_squared(p1, p2), i, j))
        False -> Error(Nil)
      }
    })
  })
  |> list.sort(fn(a, b) {
    let #(d1, _, _) = a
    let #(d2, _, _) = b
    int.compare(d1, d2)
  })
}

/// Prim's MST - returns max weight edge (bottleneck)
fn prims_mst_bottleneck(points: List(Point)) -> #(Int, Int, Int) {
  let n = list.length(points)
  case n {
    0 | 1 -> #(0, 0, 0)
    _ -> {
      let points_arr = list.index_map(points, fn(p, i) { #(i, p) }) |> dict.from_list
      let p0 = dict.get(points_arr, 0) |> result.unwrap(Point(0, 0, 0))

      let dist_to_tree =
        list.range(1, n - 1)
        |> list.fold(dict.new(), fn(d, i) {
          let pi = dict.get(points_arr, i) |> result.unwrap(Point(0, 0, 0))
          dict.insert(d, i, #(distance_squared(p0, pi), 0))
        })

      build_mst_find_max(points_arr, n, 1, dist_to_tree, #(0, 0, 0))
    }
  }
}

fn build_mst_find_max(
  points: Dict(Int, Point),
  n: Int,
  tree_size: Int,
  dist_to_tree: Dict(Int, #(Int, Int)),
  max_edge: #(Int, Int, Int),
) -> #(Int, Int, Int) {
  case tree_size >= n {
    True -> max_edge
    False -> {
      let #(min_node, min_dist, min_tree_node) =
        dist_to_tree
        |> dict.to_list
        |> list.fold(#(-1, 999_999_999_999, -1), fn(acc, entry) {
          let #(_, best_dist, _) = acc
          let #(node, #(dist, tree_node)) = entry
          case dist < best_dist {
            True -> #(node, dist, tree_node)
            False -> acc
          }
        })

      let #(max_dist, _, _) = max_edge
      let new_max_edge = case min_dist > max_dist {
        True -> #(min_dist, min_tree_node, min_node)
        False -> max_edge
      }

      let min_point = dict.get(points, min_node) |> result.unwrap(Point(0, 0, 0))
      let new_dist_to_tree =
        dist_to_tree
        |> dict.delete(min_node)
        |> dict.to_list
        |> list.fold(dict.new(), fn(d, entry) {
          let #(node, #(old_dist, old_tree)) = entry
          let node_point = dict.get(points, node) |> result.unwrap(Point(0, 0, 0))
          let new_dist = distance_squared(min_point, node_point)
          case new_dist < old_dist {
            True -> dict.insert(d, node, #(new_dist, min_node))
            False -> dict.insert(d, node, #(old_dist, old_tree))
          }
        })

      build_mst_find_max(points, n, tree_size + 1, new_dist_to_tree, new_max_edge)
    }
  }
}

pub type UnionFind {
  UnionFind(parent: Dict(Int, Int), rank: Dict(Int, Int))
}

fn uf_new(n: Int) -> UnionFind {
  let parent = list.range(0, n - 1) |> list.fold(dict.new(), fn(d, i) { dict.insert(d, i, i) })
  let rank = list.range(0, n - 1) |> list.fold(dict.new(), fn(d, i) { dict.insert(d, i, 0) })
  UnionFind(parent:, rank:)
}

fn uf_find(uf: UnionFind, x: Int) -> #(UnionFind, Int) {
  let parent_x = dict.get(uf.parent, x) |> result.unwrap(x)
  case parent_x == x {
    True -> #(uf, x)
    False -> {
      let #(uf2, root) = uf_find(uf, parent_x)
      let new_parent = dict.insert(uf2.parent, x, root)
      #(UnionFind(..uf2, parent: new_parent), root)
    }
  }
}

fn uf_union(uf: UnionFind, x: Int, y: Int) -> UnionFind {
  let #(uf1, root_x) = uf_find(uf, x)
  let #(uf2, root_y) = uf_find(uf1, y)
  case root_x == root_y {
    True -> uf2
    False -> {
      let rank_x = dict.get(uf2.rank, root_x) |> result.unwrap(0)
      let rank_y = dict.get(uf2.rank, root_y) |> result.unwrap(0)
      case rank_x < rank_y {
        True -> UnionFind(..uf2, parent: dict.insert(uf2.parent, root_x, root_y))
        False ->
          case rank_x > rank_y {
            True -> UnionFind(..uf2, parent: dict.insert(uf2.parent, root_y, root_x))
            False -> {
              let new_parent = dict.insert(uf2.parent, root_y, root_x)
              let new_rank = dict.insert(uf2.rank, root_x, rank_x + 1)
              UnionFind(parent: new_parent, rank: new_rank)
            }
          }
      }
    }
  }
}

fn get_circuit_sizes(uf: UnionFind, n: Int) -> List(Int) {
  let #(final_uf, _) =
    list.range(0, n - 1)
    |> list.fold(#(uf, []), fn(acc, i) {
      let #(u, _) = acc
      let #(u2, _) = uf_find(u, i)
      #(u2, [])
    })

  list.range(0, n - 1)
  |> list.fold(dict.new(), fn(counts, i) {
    let #(_, root) = uf_find(final_uf, i)
    let current = dict.get(counts, root) |> result.unwrap(0)
    dict.insert(counts, root, current + 1)
  })
  |> dict.values
}

fn solve_both(points: List(Point)) -> #(Int, Int) {
  let n = list.length(points)
  case n {
    0 -> #(0, 0)
    1 -> #(1, 0)
    _ -> {
      let points_arr = list.index_map(points, fn(p, i) { #(i, p) }) |> dict.from_list

      // Part 2: Prim's MST bottleneck
      let #(_, i2, j2) = prims_mst_bottleneck(points)
      let p2_1 = dict.get(points_arr, i2) |> result.unwrap(Point(0, 0, 0))
      let p2_2 = dict.get(points_arr, j2) |> result.unwrap(Point(0, 0, 0))
      let part2 = p2_1.x * p2_2.x

      // Part 1: Sort all pairs, take 1000
      let pairs = all_pairs_sorted(points)
      let uf = uf_new(n)
      let final_uf =
        pairs
        |> list.take(1000)
        |> list.fold(uf, fn(u, pair) {
          let #(_, i, j) = pair
          uf_union(u, i, j)
        })

      let sizes =
        get_circuit_sizes(final_uf, n)
        |> list.sort(fn(a, b) { int.compare(b, a) })
        |> list.take(3)

      let part1 = case sizes {
        [a, b, c, ..] -> a * b * c
        [a, b] -> a * b
        [a] -> a
        [] -> 0
      }

      #(part1, part2)
    }
  }
}

pub fn part1(points: List(Point)) -> Int {
  let #(p1, _) = solve_both(points)
  p1
}

pub fn part2(points: List(Point)) -> Int {
  let #(_, p2) = solve_both(points)
  p2
}

pub fn run(input: String) -> #(Int, Int) {
  let parsed = parse(input)
  solve_both(parsed)
}
