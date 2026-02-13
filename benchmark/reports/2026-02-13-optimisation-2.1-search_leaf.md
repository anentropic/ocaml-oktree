# Nearest-search optimisation experiments (2026-02-13)

This report benchmarks candidate optimisations in `lib/oktree.ml` for nearest-neighbour search.

## Test setup

- Command (each run):

  ```sh
  OCAML_LANDMARKS=auto,off dune exec --instrument-with landmarks benchmark/profile.exe -- --n-points 4096 --n-queries 10000 --seed 20260213
  ```

- Instrumented nested profiling enabled (`--instrument-with landmarks`) so child functions are visible.
- Each variant measured with **3 runs**; values below use the **median** run.
- Main metric: `Time` cycles for
  - `oktree.nearest` (top-level measured region)
  - `Oktree.Make.search_leaf`
  - `Oktree.Make.distance_sq_coords`

## Variants

### Baseline

Current code before optimisation changes.

### Optimisation 1 (individual)

- Change: add `[@inline]` to `distance_sq_coords` only.
- No loop logic change.

### Optimisation 2 (individual)

- Change: rewrite `search_leaf` to use early-exit partial distance checks:
  - compute `dx²`, skip point if `dx² >= best_d2`
  - compute `dx² + dy²`, skip if `>= best_d2`
  - compute full `+ dz²` only if needed
- This also removes calls to `distance_sq_coords` from the hot loop.

### Cumulative (Optimisation 1 + 2)

- Both changes together.

## Results (median of 3 runs)

| Variant | `oktree.nearest` | Δ vs baseline | `search_leaf` | Δ vs baseline | `distance_sq_coords` |
|---|---:|---:|---:|---:|---:|
| Baseline | 28,880,000 | — | 24,870,000 | — | 8,310,000 |
| Opt 1 only | 29,330,000 | +1.56% | 25,240,000 | +1.49% | 8,470,000 |
| Opt 2 only | 7,170,000 | **-75.17%** | 3,160,000 | **-87.30%** | 0 |
| Cumulative (1+2) | 7,110,000 | **-75.38%** | 3,130,000 | **-87.42%** | 0 |

## Interpretation

- `Opt 1` (inline annotation only) did not help in this workload; small regression within low-single-digit range.
- `Opt 2` is the major win: early pruning in `search_leaf` drastically cuts work.
- Cumulative is essentially the same as `Opt 2` (slightly better in this sample, but tiny delta).

## Outcome

Recommended optimisation to keep: **Optimisation 2** (early-exit `search_leaf` distance accumulation).

## Validation

- `dune test` after final code: **PASS (17/17)**.
