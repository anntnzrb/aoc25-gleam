import day11.{parse, part1, run}
import gleam/dict
import gleeunit/should

// ============================================================================
// Example input from problem
// ============================================================================

const example_input = "aaa: you hhh
you: bbb ccc
bbb: ddd eee
ccc: ddd eee fff
ddd: ggg
eee: out
fff: out
ggg: out
hhh: ccc fff iii
iii: out"

// ============================================================================
// Parse tests
// ============================================================================

pub fn parse_example_test() {
  let graph = parse(example_input)
  graph |> dict.size |> should.equal(10)
}

pub fn parse_single_node_test() {
  let graph = parse("a: b c d")
  graph |> dict.get("a") |> should.equal(Ok(["b", "c", "d"]))
}

pub fn parse_empty_outputs_test() {
  let graph = parse("end:")
  graph |> dict.get("end") |> should.equal(Ok([]))
}

pub fn parse_empty_test() {
  parse("") |> dict.size |> should.equal(0)
}

pub fn parse_whitespace_handling_test() {
  let graph = parse("node:   a   b   c  ")
  graph |> dict.get("node") |> should.equal(Ok(["a", "b", "c"]))
}

// ============================================================================
// Part 1 tests
// ============================================================================

pub fn part1_example_test() {
  // 5 paths from "you" to "out"
  parse(example_input)
  |> part1
  |> should.equal(5)
}

pub fn part1_simple_test() {
  // Direct path: you -> out
  let input = "you: out"
  parse(input) |> part1 |> should.equal(1)
}

pub fn part1_two_paths_test() {
  // you -> a -> out
  // you -> b -> out
  let input =
    "you: a b
a: out
b: out"
  parse(input) |> part1 |> should.equal(2)
}

pub fn part1_diamond_test() {
  // Diamond pattern:
  // you -> a -> c -> out
  // you -> a -> d -> out
  // you -> b -> c -> out
  // you -> b -> d -> out
  let input =
    "you: a b
a: c d
b: c d
c: out
d: out"
  parse(input) |> part1 |> should.equal(4)
}

pub fn part1_no_path_test() {
  // No connection to out (dead end)
  let input =
    "you: a
a: b
b:"
  parse(input) |> part1 |> should.equal(0)
}

pub fn part1_single_chain_test() {
  // you -> a -> b -> c -> out
  let input =
    "you: a
a: b
b: c
c: out"
  parse(input) |> part1 |> should.equal(1)
}

pub fn part1_multiple_outs_test() {
  // Multiple paths to same intermediate node
  let input =
    "you: a
a: b c
b: out
c: out"
  parse(input) |> part1 |> should.equal(2)
}

pub fn part1_self_is_out_test() {
  // Direct: you = out? Edge case (shouldn't happen but handle)
  let input =
    "you: out
out: you"
  parse(input) |> part1 |> should.equal(1)
}

// ============================================================================
// Run tests
// ============================================================================

pub fn run_example_test() {
  let #(p1, _p2) = run(example_input)
  p1 |> should.equal(5)
}

pub fn run_empty_test() {
  run("") |> should.equal(#(0, 0))
}

pub fn run_simple_test() {
  // Part 2 needs svr, dac, fft nodes - simple input returns 0 for part2
  run("you: out") |> should.equal(#(1, 0))
}

pub fn part2_with_both_nodes_test() {
  // svr -> fft -> dac -> out (fft before dac)
  let input =
    "svr: fft
fft: dac
dac: out"
  let graph = parse(input)
  day11.part2(graph) |> should.equal(1)
}

pub fn part2_reverse_order_test() {
  // svr -> dac -> fft -> out (dac before fft)
  let input =
    "svr: dac
dac: fft
fft: out"
  let graph = parse(input)
  day11.part2(graph) |> should.equal(1)
}

pub fn part2_both_orders_test() {
  // Two paths: one with dac first, one with fft first
  // No cycles - distinct nodes for each order
  let input =
    "svr: a b
a: dac
b: fft
dac: x
x: fft
fft: y
y: dac2
dac2: out"
  let graph = parse(input)
  // path a->dac->x->fft->y->dac2->out (dac before fft, but dac2 doesn't count as dac)
  // This test needs rethinking - let's simplify
  // With this input:
  // svr->a->dac->x->fft->y->dac2->out = dac before fft but no real dac after fft
  // svr->b->fft->y->dac2->out = fft before dac2, but dac2 isn't "dac"
  // Actually this won't work - the nodes must be literally "dac" and "fft"
  // Let's just count: svr->dac paths * dac->fft paths * fft->out paths
  //                 + svr->fft paths * fft->dac paths * dac->out paths
  // svr->dac: svr->a->dac = 1
  // dac->fft: dac->x->fft = 1
  // fft->out: fft->y->dac2->out = 1 (no direct fft->out path)
  // So dac first = 1*1*1 = 1
  // svr->fft: svr->b->fft = 1
  // fft->dac: fft->y->dac2? No, dac2 isn't dac. fft->dac = 0
  // So fft first = 1*0*? = 0
  day11.part2(graph) |> should.equal(1)
}
