# Nearest-search optimisation experiment: mutable best-state refs (2026-02-13)

This report evaluates the next optimisation idea for `lib/oktree.ml`:

- Reduce Option/tuple churn in the search path by using mutable locals (`ref`) for best distance/point in `search_leaf`/`search_node`.

## Test setup

- Command (each run):

  ```sh
  OCAML_LANDMARKS=auto,off dune exec --instrument-with landmarks benchmark/profile.exe -- --n-points 4096 --n-queries 10000 --seed 20260213
  ```

- 3 runs per variant, fixed seed and workload.
- Main metrics from `Aggregated table` (`Time` cycles):
  - `oktree.nearest`
  - `Oktree.Make.search_node`
  - `Oktree.Make.search_leaf`
  - `Oktree.Make.cube_dist_sq`

## Variants

### Baseline

Current best implementation before this experiment:

- early-exit partial distance checks in `search_leaf`
- tuple-return based search path (`search_leaf`/`search_child`/`search_node`)

### Optimisation candidate

Use mutable refs for best distance/point in search path:

- `search_leaf` updates `best_d2_ref`/`best_pt_ref`
- `search_child`/`search_node` mutate refs instead of returning `(best_d2, best_pt)` each step

### Cumulative context

This candidate was tested on top of the existing early-exit optimisation (i.e. cumulative with previously accepted optimisation).

## Raw results

### Baseline (runs)

- run1: `nearest=7,600,000` `search_node=7,560,000` `search_leaf=3,340,000` `cube_dist_sq=583,780`
- run2: `nearest=7,140,000` `search_node=7,100,000` `search_leaf=3,140,000` `cube_dist_sq=550,360`
- run3: `nearest=7,200,000` `search_node=7,160,000` `search_leaf=3,160,000` `cube_dist_sq=551,230`

### Candidate (runs)

- run1: `nearest=7,790,000` `search_node=7,740,000` `search_leaf=3,370,000` `cube_dist_sq=568,110`
- run2: `nearest=7,430,000` `search_node=7,390,000` `search_leaf=3,230,000` `cube_dist_sq=547,090`
- run3: `nearest=7,420,000` `search_node=7,380,000` `search_leaf=3,220,000` `cube_dist_sq=547,090`

## Median comparison

| Variant | `oktree.nearest` | Δ vs baseline | `search_node` | Δ vs baseline | `search_leaf` | Δ vs baseline | `cube_dist_sq` | Δ vs baseline |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| Baseline | 7,200,000 | — | 7,160,000 | — | 3,160,000 | — | 551,230 | — |
| Mutable refs candidate | 7,430,000 | +3.19% | 7,390,000 | +3.21% | 3,230,000 | +2.22% | 547,090 | -0.75% |

## Interpretation

- This candidate did **not** improve overall nearest-search time in this workload.
- Core search metrics (`nearest`, `search_node`, `search_leaf`) regressed by ~2–3%.
- Small improvement in `cube_dist_sq` is not enough to offset the regression.

## Outcome

- **Rejected** for now.
- Repository code was reverted to the prior faster baseline (early-exit `search_leaf` with tuple-return search path).

## Validation

- `dune test`: PASS (17/17).
