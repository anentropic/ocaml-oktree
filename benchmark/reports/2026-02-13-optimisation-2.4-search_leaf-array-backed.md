# Nearest-search optimisation experiment: array-backed `search_leaf` traversal (2026-02-13)

This report evaluates the next optimisation idea for `lib/oktree.ml`:

- Use an array-backed traversal path in `search_leaf`.
- Candidate implementation converted each leaf list to an array (`Array.of_list`) and scanned it with an imperative `for` loop.

## Test setup

- Command (each run):

  ```sh
  OCAML_LANDMARKS=auto,off dune exec --instrument-with landmarks benchmark/profile.exe -- --n-points 4096 --n-queries 10000 --seed 20260213
  ```

- 3 runs per variant, fixed seed/workload.
- Metrics from `Aggregated table` (`Time` cycles):
  - `oktree.nearest`
  - `Oktree.Make.search_node`
  - `Oktree.Make.search_leaf`
  - `Oktree.Make.cube_dist_sq`

## Variants

### Baseline

Current best implementation before this experiment:

- early-exit partial distance checks in `search_leaf`
- list traversal in recursive loop

### Candidate

- In `search_leaf`, convert points list to array and iterate by index.

## Raw results

### Baseline (runs)

- run1: `nearest=7,310,000` `search_node=7,260,000` `search_leaf=3,210,000` `cube_dist_sq=559,030`
- run2: `nearest=7,120,000` `search_node=7,080,000` `search_leaf=3,130,000` `cube_dist_sq=548,280`
- run3: `nearest=7,130,000` `search_node=7,090,000` `search_leaf=3,120,000` `cube_dist_sq=546,960`

### Candidate (runs)

- run1: `nearest=9,420,000` `search_node=9,370,000` `search_leaf=5,150,000` `cube_dist_sq=576,310`
- run2: `nearest=8,940,000` `search_node=8,890,000` `search_leaf=4,880,000` `cube_dist_sq=546,130`
- run3: `nearest=8,940,000` `search_node=8,890,000` `search_leaf=4,880,000` `cube_dist_sq=550,620`

## Median comparison

| Variant | `oktree.nearest` | Δ vs baseline | `search_node` | Δ vs baseline | `search_leaf` | Δ vs baseline | `cube_dist_sq` | Δ vs baseline |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| Baseline | 7,130,000 | — | 7,090,000 | — | 3,130,000 | — | 548,280 | — |
| Array-backed candidate | 8,940,000 | +25.39% | 8,890,000 | +25.39% | 4,880,000 | +55.91% | 550,620 | +0.43% |

## Interpretation

- This candidate significantly regresses nearest-search performance.
- Main regression is in `search_leaf` time, consistent with allocation/copy overhead from `Array.of_list` per visited leaf.
- `cube_dist_sq` is nearly unchanged, so slowdown is from leaf traversal strategy itself.

## Outcome

- **Rejected**.
- `lib/oktree.ml` reverted to prior baseline implementation.

## Validation

- Candidate built and tests passed (`17/17`) during experiment.
- Final repository state restored after measurement.
