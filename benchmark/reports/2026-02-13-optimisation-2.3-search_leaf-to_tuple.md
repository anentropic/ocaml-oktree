# Nearest-search optimisation experiment: `V3.to_tuple` in `search_leaf` (2026-02-13)

This report evaluates the next optimisation idea for `lib/oktree.ml`:

- In `search_leaf`, extract point coordinates once via `V3.to_tuple pt` instead of calling `V3.x`, `V3.y`, `V3.z` separately.

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
- coordinate access via `V3.x` / `V3.y` / `V3.z`

### Candidate

- Replace per-axis access calls with single tuple extraction per point:
  - `let x, y, z = V3.to_tuple pt`

## Raw results

### Baseline (runs)

- run1: `nearest=7,070,000` `search_node=7,030,000` `search_leaf=3,110,000` `cube_dist_sq=542,410`
- run2: `nearest=7,090,000` `search_node=7,050,000` `search_leaf=3,110,000` `cube_dist_sq=542,770`
- run3: `nearest=7,050,000` `search_node=7,010,000` `search_leaf=3,090,000` `cube_dist_sq=541,530`

### Candidate (runs)

- run1: `nearest=7,850,000` `search_node=7,800,000` `search_leaf=3,580,000` `cube_dist_sq=581,990`
- run2: `nearest=7,440,000` `search_node=7,390,000` `search_leaf=3,400,000` `cube_dist_sq=554,000`
- run3: `nearest=7,390,000` `search_node=7,340,000` `search_leaf=3,370,000` `cube_dist_sq=546,510`

## Median comparison

| Variant | `oktree.nearest` | Δ vs baseline | `search_node` | Δ vs baseline | `search_leaf` | Δ vs baseline | `cube_dist_sq` | Δ vs baseline |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| Baseline | 7,070,000 | — | 7,030,000 | — | 3,110,000 | — | 542,410 | — |
| `to_tuple` candidate | 7,440,000 | +5.23% | 7,390,000 | +5.12% | 3,400,000 | +9.32% | 554,000 | +2.14% |

## Interpretation

- This candidate regresses overall nearest-search performance.
- `search_leaf` in particular gets noticeably slower.
- Likely cause: tuple construction/destructuring overhead outweighs any savings from fewer accessor calls.

## Outcome

- **Rejected**.
- Code reverted to prior baseline implementation.

## Validation

- Candidate variant built and tests passed during experiment.
- Final repository state restored to baseline after measurement.
