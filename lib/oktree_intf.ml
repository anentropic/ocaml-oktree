(** Module type for 3D vectors used as points in the octree.

    This module type defines the interface for 3D point/vector types.
    It is deliberately designed to be compatible with
    {{:https://erratique.ch/software/gg/doc/Gg/V3/}Gg.V3}.

    The vector represents a point in 3D coordinate space with x, y, and z
    components, along with basic vector operations needed for octree operations.
*)
module type VEC3 = sig
  type t
  (** The type of 3D vectors. *)

  val x : t -> float
  (** [x v] is the x component of [v].

      {[
        open Gg
        let v = V3.v 1.0 2.0 3.0
        let x_coord = V3.x v
        (* x_coord = 1.0 *)
      ]}
  *)

  val y : t -> float
  (** [y v] is the y component of [v].

      {[
        open Gg
        let v = V3.v 1.0 2.0 3.0
        let y_coord = V3.y v
        (* y_coord = 2.0 *)
      ]}
  *)

  val z : t -> float
  (** [z v] is the z component of [v].

      {[
        open Gg
        let v = V3.v 1.0 2.0 3.0
        let z_coord = V3.z v
        (* z_coord = 3.0 *)
      ]}
  *)

  val of_tuple : float * float * float -> t
  (** [of_tuple (x, y, z)] creates a vector from a tuple.

      {[
        open Gg
        let v = V3.of_tuple (1.0, 2.0, 3.0)
        (* v = V3.v 1.0 2.0 3.0 *)
      ]}
  *)

  val to_tuple : t -> float * float * float
  (** [to_tuple v] converts a vector to a tuple [(x, y, z)].

      {[
        open Gg
        let v = V3.v 1.0 2.0 3.0
        let (x, y, z) = V3.to_tuple v
        (* (1.0, 2.0, 3.0) *)
      ]}
  *)

  val add : t -> t -> t
  (** [add u v] is the vector addition [u + v].

      {[
        open Gg
        let u = V3.v 1.0 2.0 3.0
        let v = V3.v 4.0 5.0 6.0
        let sum = V3.add u v
        (* sum = V3.v 5.0 7.0 9.0 *)
      ]}
  *)

  val sub : t -> t -> t
  (** [sub u v] is the vector subtraction [u - v].

      {[
        open Gg
        let u = V3.v 4.0 5.0 6.0
        let v = V3.v 1.0 2.0 3.0
        let diff = V3.sub u v
        (* diff = V3.v 3.0 3.0 3.0 *)
      ]}
  *)

  (* val mul : t -> t -> t *)
  (** [mul u v] is the component wise multiplication [u * v]. *)

  val div : t -> t -> t
  (** [div u v] is the component wise division [u / v].

      {[
        open Gg
        let u = V3.v 6.0 8.0 10.0
        let v = V3.v 2.0 4.0 5.0
        let quotient = V3.div u v
        (* quotient = V3.v 3.0 2.0 2.0 *)
      ]}
  *)

  val norm : t -> float
  (** [norm v] is the Euclidean norm (magnitude) of [v].

      Computes [sqrt(x*x + y*y + z*z)], the distance from the origin.

      {[
        open Gg
        let v = V3.v 3.0 4.0 0.0
        let magnitude = V3.norm v
        (* magnitude = 5.0 *)
      ]}

      {[
        (* Unit vector has norm 1.0 *)
        let unit_x = V3.v 1.0 0.0 0.0
        let n = V3.norm unit_x
        (* n = 1.0 *)
      ]}
  *)

  val map : (float -> float) -> t -> t
  (** [map f v] applies [f] to each component of [v].

      {[
        open Gg
        let v = V3.v 1.0 2.0 3.0
        let doubled = V3.map (fun x -> x *. 2.0) v
        (* doubled = V3.v 2.0 4.0 6.0 *)
      ]}

      {[
        (* Clamp all components to range [0, 1] *)
        let clamp01 x = max 0.0 (min 1.0 x)
        let v = V3.v 1.5 (-0.5) 0.7
        let clamped = V3.map clamp01 v
        (* clamped = V3.v 1.0 0.0 0.7 *)
      ]}
  *)

  val pp : Format.formatter -> t -> unit
  (** [pp ppf v] prints a textual representation of [v] on [ppf].

      {[
        open Gg
        let v = V3.v 1.0 2.0 3.0
        let () = Format.printf "Point: %a@." V3.pp v
        (* Output: Point: (1 2 3) *)
      ]}
  *)

  (* val compare : t -> t -> int *)
  (** [compare u v] is [Stdlib.compare u v]. *)
end

(** Module type for octree operations.

    This module type defines the interface for an octree that stores 3D points
    and supports efficient nearest neighbor queries.
*)
module type S = sig
  type vec3
  (** The type of 3D vectors used as points in the octree. *)

  type t
  (** The type of the octree. *)

  val pp : Format.formatter -> t -> unit
  (** [pp ppf tree] prints a textual representation of the octree structure.

      Useful for debugging and understanding tree layout.

      {[
        open Gg
        module Okt = Oktree.Make (V3)

        let tree = Okt.of_list [V3.zero; V3.v 1.0 0.0 0.0]
        let () = Format.printf "%a@." Okt.pp tree
        (* Prints the tree structure showing nodes and leaves *)
      ]}
  *)

  val insert : t -> vec3 -> t
  (** [insert tree point] returns a new tree with [point] added.

      The tree is persistent/immutable, so this returns a new tree rather than
      modifying the existing one.

      Note: For bulk insertions, it is more efficient to rebuild the tree with
      {!of_list} than to insert points one by one.

      {[
        open Gg
        module Okt = Oktree.Make (V3)

        (* Start with a tree *)
        let tree = Okt.of_list [V3.zero; V3.v 1.0 0.0 0.0]

        (* Add a new point *)
        let tree2 = Okt.insert tree (V3.v 0.0 1.0 0.0)

        (* Original tree unchanged, tree2 has the new point *)
        let points = Okt.to_list tree2
        (* points includes (0, 1, 0) *)
      ]}

      {[
        (* Add multiple points *)
        let initial = Okt.of_list [V3.zero]
        let tree = List.fold_left Okt.insert initial [
            V3.v 1.0 0.0 0.0;
            V3.v 0.0 1.0 0.0;
            V3.v 0.0 0.0 1.0;
          ]
      ]}
  *)

  val of_list : ?leaf_size:int -> vec3 list -> t
  (** [of_list ?leaf_size points] builds an octree from a list of points.

      This is the primary way to construct an octree. The tree is built by
      recursively subdividing space until each leaf contains at most [leaf_size]
      points.

      @param leaf_size Maximum points per leaf before subdivision (default: 16).
                       Smaller values create deeper trees, larger values create
                       shallower trees. Tune based on your data distribution.

      {[
        open Gg
        module Okt = Oktree.Make (V3)

        (* Build with default leaf size *)
        let tree = Okt.of_list [
            V3.v 0.0 0.0 0.0;
            V3.v 1.0 0.0 0.0;
            V3.v 0.0 1.0 0.0;
            V3.v 0.0 0.0 1.0;
          ]
      ]}

      {[
        (* Build with custom leaf size *)
        let tree = Okt.of_list ~leaf_size:4 many_points
        (* Smaller leaf size: more subdivision, faster queries *)
      ]}

      {[
        (* Build from generated points *)
        let points = List.init 100 (fun i ->
            let t = float_of_int i /. 100.0 in
            V3.v t (sin t) (cos t)
          ) in
        let tree = Okt.of_list ~leaf_size:8 points
      ]}
  *)

  val to_list : t -> vec3 list
  (** [to_list tree] returns all points stored in the tree as a list.

      Useful for inspecting tree contents or extracting points after filtering.

      {[
        open Gg
        module Okt = Oktree.Make (V3)

        let points = [V3.zero; V3.v 1.0 0.0 0.0; V3.v 0.0 1.0 0.0]
        let tree = Okt.of_list points

        (* Get all points back *)
        let all_points = Okt.to_list tree
        (* all_points contains the same three points *)

        (* Count points in tree *)
        let count = List.length (Okt.to_list tree)
        (* count = 3 *)
      ]}

      {[
        (* Check if a specific point is in the tree *)
        let tree = Okt.of_list [V3.zero; V3.v 1.0 0.0 0.0]
        let has_origin =
          List.exists (fun p -> V3.x p = 0. && V3.y p = 0. && V3.z p = 0.)
            (Okt.to_list tree)
        (* has_origin = true *)
      ]}
  *)

  val nearest : t -> vec3 -> vec3
  (** [nearest tree query] finds the point in [tree] closest to [query].

      Uses Euclidean distance to determine the nearest point. This is the
      primary operation the octree is optimized for.

      Time complexity: O(log n) average case for well-distributed points,
      O(n) worst case for highly clustered points.

      {[
        open Gg
        module Okt = Oktree.Make (V3)

        let tree = Okt.of_list [
            V3.v 0.0 0.0 0.0;
            V3.v 1.0 0.0 0.0;
            V3.v 0.0 1.0 0.0;
          ]

        (* Find nearest to origin *)
        let near_origin = Okt.nearest tree (V3.v 0.1 0.1 0.1)
        (* near_origin = V3.v 0.0 0.0 0.0 *)

        (* Find nearest to (0.9, 0, 0) *)
        let near_x = Okt.nearest tree (V3.v 0.9 0.0 0.0)
        (* near_x = V3.v 1.0 0.0 0.0 *)
      ]}

      {[
        (* Color quantization example *)
        let palette = [
          V3.v 1.0 0.0 0.0;  (* red *)
          V3.v 0.0 1.0 0.0;  (* green *)
          V3.v 0.0 0.0 1.0;  (* blue *)
        ]
        let palette_tree = Okt.of_list palette

        (* Quantize orange to nearest palette color *)
        let orange = V3.v 1.0 0.5 0.0
        let quantized = Okt.nearest palette_tree orange
        (* quantized = V3.v 1.0 0.0 0.0 (red, closest to orange) *)
      ]}

      {[
        (* Batch nearest neighbor queries *)
        let tree = Okt.of_list large_dataset

        let find_all_nearest queries =
          List.map (Okt.nearest tree) queries

        let nearest_points = find_all_nearest query_points
      ]}
  *)
end

(** Functor type for creating octree modules.

    Takes a [VEC3] module and produces an octree module [S] specialized for
    that vector type.
*)
module type MAKER = functor (V3 : VEC3) -> S with type vec3 = V3.t

(** Main interface for the Oktree library.

    This interface exposes:
    - Module types {!VEC3}, {!S}, and {!MAKER}
    - The {!Make} functor for creating octree instances

    See {{!page-oktree}the user guide} for detailed usage examples.
*)
module type Intf = sig
  module type VEC3 = VEC3
  (** Module type for 3D vectors. See {!VEC3}. *)

  module type S = S
  (** Module type for octree operations. See {!S}. *)

  module type MAKER = MAKER
  (** Functor type for creating octree modules. See {!MAKER}. *)

  module Make : MAKER
  (** [Make (V3)] creates an octree module for 3D points represented by [V3].

      The [V3] module must satisfy the {!VEC3} interface. The most common
      choice is {{:https://erratique.ch/software/gg/doc/Gg/V3/}Gg.V3}.

      {[
        open Gg

        (* Create an octree module using Gg.V3 *)
        module Okt = Oktree.Make (V3)

        (* Now use Okt.of_list, Okt.nearest, etc. *)
        let tree = Okt.of_list [V3.zero; V3.v 1.0 0.0 0.0]
        let nearest = Okt.nearest tree (V3.v 0.5 0.0 0.0)
      ]}

      {[
        (* Custom vector implementation *)
        module Float3 : Oktree.VEC3 with type t = float * float * float = struct
          type t = float * float * float
          let x (x, _, _) = x
          let y (_, y, _) = y
          let z (_, _, z) = z
          let of_tuple t = t
          let to_tuple t = t
          let add (x1, y1, z1) (x2, y2, z2) = (x1 +. x2, y1 +. y2, z1 +. z2)
          let sub (x1, y1, z1) (x2, y2, z2) = (x1 -. x2, y1 -. y2, z1 -. z2)
          let div (x1, y1, z1) (x2, y2, z2) = (x1 /. x2, y1 /. y2, z1 /. z2)
          let norm (x, y, z) = sqrt (x *. x +. y *. y +. z *. z)
          let map f (x, y, z) = (f x, f y, f z)
          let pp fmt (x, y, z) = Format.fprintf fmt "(%g, %g, %g)" x y z
        end

        module Okt = Oktree.Make (Float3)
        let tree = Okt.of_list [(0., 0., 0.); (1., 1., 1.)]
      ]}
  *)
end
