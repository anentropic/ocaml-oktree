# Benchmarking and profiling

This folder contains two runnable Dune aliases:

- `@benchmark`: micro-benchmarks using `core_bench`
- `@profile`: callgraph profiling using `landmarks`

## Prerequisites

Use the project-local opam switch and install dev dependencies:

```sh
eval "$(opam env --switch=. --set-switch)"
opam install . --deps-only --with-dev-setup
```

## 1) Run `@benchmark` (`core_bench`)

Run the default benchmark suite:

```sh
dune build @benchmark
```

Equivalent executable invocation (if you want to tune options):

```sh
dune exec benchmark/benchmark.exe -- -quota 3 -stabilize-gc
```

### How to interpret `core_bench` output

- Focus on **time per run** (ns/us/ms) for each benchmark group.
- Compare like-for-like cases (same distribution and point counts).
- Lower is better.
- If variance is high, increase `-quota` to collect more stable samples.

## 2) Run `@profile` (`landmarks`)

Run the profiling target with defaults (top-level landmark from `profile.ml`):

```sh
dune build @profile
```

To profile nested calls inside `oktree` without manually instrumenting every function,
run with Dune instrumentation enabled:

```sh
dune clean && OCAML_LANDMARKS=auto dune build --instrument-with landmarks @profile
```

This is intended for developers only. It does **not** affect normal builds, and
it is **not** required for users of the published library.

`off` keeps runtime profiling disabled at startup so setup code is excluded. The
program then explicitly starts profiling only around nearest-query execution.

Defaults used by `benchmark/profile.ml`:

- `--n-points 4096`
- `--n-queries 10000`
- `--seed` omitted (random seed each run)

Run with custom parameters:

```sh
dune exec benchmark/profile.exe -- --n-points 32768 --n-queries 10000 --seed 20260213
```

To make runs reproducible, always pass an explicit `--seed` value.

### How to interpret `landmarks` output

You will see a callgraph line similar to:

```text
[    8.96M cycles in 10000 calls ]     - 95.01% : oktree.nearest
```

Use this to compute per-query cost:

- `cycles_per_query = total_cycles / calls`
- Example above: `8.96M / 10000 ≈ 896 cycles/query`

Also check the aggregated table:

- `oktree.nearest` row: the metric you care about for nearest lookup cost.
- `ROOT` row: includes benchmark/profiler overhead around your instrumented region.
- `Allocated bytes`: useful signal for allocation pressure and GC impact.

When using `--instrument-with landmarks` + `OCAML_LANDMARKS=auto,off`, you should also
see nested entries such as `Oktree.Make.search_node`, `Oktree.Make.search_leaf`,
and `Oktree.Make.distance_sq_coords`, which lets you identify where nearest-search
time is actually spent.

## Practical workflow

- Use `@benchmark` when comparing implementations or parameter sweeps statistically.
- Use `@profile` when finding where time/allocations are spent inside a single scenario.
- For trend checks, hold `--seed` and `--n-queries` constant and vary only `--n-points`.
