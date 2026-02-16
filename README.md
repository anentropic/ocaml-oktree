# OKtree

[ [Docs](https://anentropic.github.io/ocaml-oktree/) ]

OKtree is a simple octree implementation in OCaml, intended to efficiently find the nearest match for an arbitrary point among a set of target points in 3D coordinate space.

> An octree is a tree data structure in which each internal node has exactly eight children. Octrees are most often used to partition a three-dimensional space by recursively subdividing it into eight octants. Octrees are the three-dimensional analog of quadtrees.
>
> &mdash; <cite>[Wikipedia](https://en.wikipedia.org/wiki/Octree)</cite>

The original use case for this lib was finding nearest match in a palette of RGB colours.

- Aims to be faster than not using an octree, does not claim to be world's fastest octree.
- Fast insertions are not a goal. Use-case is: create a tree once, match points many times.

## Basic usage

A tree is generated from a list of 3D points.

OKtree defines a `VEC3` module type for the points. This is deliberately compatible with the `Gg` library's [`Gg.V3`](https://erratique.ch/software/gg/doc/Gg/index.html#module-V3) module type.

So first we instantiate the Oktree functor, then add points:

```ocaml
open Gg

module Okt = Oktree.Make (V3)

let points = [ V3.zero; V3.v 0. 0.251 0.; V3.v 0. 0.23 0.; V3.v 0.2 0.1 0.2 ]
let okt = Okt.of_list ~leaf_size:8 points

Format.printf "%a" Okt.pp okt;;
(*
{ Oktree.Make.leaf_size = 8;
  tree =
  (Oktree.Make.Leaf
     [(0.000000, 0.000000, 0.000000); (0.000000, 0.251000, 0.000000);
       (0.000000, 0.230000, 0.000000); (0.200000, 0.100000, 0.200000)])
  }- : unit = ()
*)

(* find closest match from [points] *)
let nearest = Okt.nearest okt (V3.v 0.2 0.1 0.3)

Format.printf "%a" V3.pp nearest;;
(* (0.2 0.1 0.2)- : unit = () *)
```

Interface:

- `Okt.of_list` builds a tree from list of points; `~leaf_size` controls max points per leaf before splitting (optional, default: `16`).
- `Okt.nearest` finds the closest point in the tree to a given query point.
- `Okt.insert` returns a new tree with the point added.
- `Okt.to_list` returns list of points in tree.
- `Okt.pp` is a printer of trees, for use with `Format.printf` and friends.
