# Vibe-optimisation notes:

Our starting point was:

| Name                                   | Time/Run | mWd/Run | mjWd/Run | Prom/Run | Percentage |
|----------------------------------------|---------:|--------:|---------:|---------:|-----------:|
| Uniform/uniform pts:256 queries:256    |  4.82 ms | 2.10 Mw |  5.07 kw |  5.07 kw |     32.23% |
| Uniform/uniform pts:1024 queries:256   | 10.53 ms | 4.33 Mw | 21.44 kw | 21.44 kw |     70.42% |
| Uniform/uniform pts:4096 queries:256   | 12.94 ms | 5.33 Mw | 33.07 kw | 33.07 kw |     86.54% |
| Uniform/uniform pts:16384 queries:256  |  8.82 ms | 3.66 Mw | 11.76 kw | 11.76 kw |     58.99% |
| Normal/normal pts:256 queries:256      |  5.73 ms | 2.46 Mw |  6.73 kw |  6.73 kw |     38.35% |
| Normal/normal pts:1024 queries:256     | 12.41 ms | 4.73 Mw | 26.36 kw | 26.36 kw |     83.01% |
| Normal/normal pts:4096 queries:256     | 14.95 ms | 5.97 Mw | 38.33 kw | 38.33 kw |    100.00% |
| Normal/normal pts:16384 queries:256    | 13.99 ms | 4.90 Mw | 22.61 kw | 22.61 kw |     93.58% |

Generally the Normal distribution tests are a bit slower than the Uniform distribution.

There is a weird anomaly where the `normal pts:4096` case is slower than `normal pts:16384`

### Pass 1. (GPT-5.2-Codex)

Achieved a great improvement down to ~2.8ms for `normal pts:16384` (and that is now the slowest case as expected)

> Optimized nearest search by using squared distances and enqueueing only the best point per leaf, reducing PQ work and allocations in `oktree.ml`

and then in another pass:

> Refactoring nearest search to prune with octant-only priority queue

However I had forgotten to tell it to make sure the tests still pass.

Fixing the tests + implementation made it much slower at ~47ms.

> Fixed update_best_from_points to always consider all leaf points, which corrected the nearest results.

> If you want both speed and correctness, we need a real lower bound. That means storing subtree bounds (e.g., half-size of the cube or a bounding radius) in each node so we can prune safely.

Proceeding with this gave insignificant improvement to ~44ms

> Added half_size bounds to node and use a correct cube-distance lower bound for pruning in `oktree.ml` and `oktree_intf.ml`.

### Pass 2 (GPT-5.2-Codex)

Asking a new chat to optimise this got down to ~8ms

I have lost the description of what it did but it's in 9416eae

So it appears to have replaced the Priority Queue with a Heap.

### Pass 3 (Claude 4.5 Opus)

Next I threw more expensive Opus at it.

This improved a further ~40% by:

> **Key change**: Replaced the heap-based priority queue approach with a depth-first recursive search that:
> 
> 1. **Visits the child octant containing the query point first** - This is most likely to contain the nearest neighbor, establishing a good initial bound quickly
> 2. **Visits remaining children in order of proximity** - Face-adjacent, edge-adjacent, then corner-opposite octants
> 3. **Aggressive pruning** - Skips children whose bounding cube is already farther than the current best
> 4. **No heap allocation** - Pure recursive traversal with better cache locality

At ~4.7ms for `normal pts:16384 queries:256` this gives us ~18µs per query.

I did try another pass after this but its changes didn't result in any significant improvement and only made the code less readable.
