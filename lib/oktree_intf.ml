(*
  A type for the points in our octree.

  (Will essentially be a vector of three floats)

  Deliberately designed to be compatible with:
  https://erratique.ch/software/gg/doc/Gg/V3/
*)
module type VEC3 = sig
  type t

  val x : t -> float
  (** [x v] is the x component of [v]. *)

  val y : t -> float
  (** [y v] is the y component of [v]. *)

  val z : t -> float
  (** [z v] is the z component of [v]. *)

  val of_tuple : float * float * float -> t
  (** [of_tuple (x, y, z)] is [v x y z]. *)

  val to_tuple : t -> float * float * float
  (** [to_tuple v] is [(x v, y v, z v)]. *)

  val add : t -> t -> t
  (** [add u v] is the vector addition [u + v]. *)

  val sub : t -> t -> t
  (** [sub u v] is the vector subtraction [u - v]. *)

  val mul : t -> t -> t
  (** [mul u v] is the component wise multiplication [u * v]. *)

  val div : t -> t -> t
  (** [div u v] is the component wise division [u / v]. *)

  val norm : t -> float
  (** [norm v] is the norm [|v| = sqrt v.v]. *)

  val map : (float -> float) -> t -> t
  (** [map f v] is the component wise application of [f] to [v]. *)

  val pp : Format.formatter -> t -> unit
  (** [pp ppf v] prints a textual representation of [v] on [ppf]. *)

  val compare : t -> t -> int
  (** [compare u v] is [Stdlib.compare u v]. *)
end

module type S = sig
  type vec3
  type t

  val pp : Format.formatter -> t -> unit

  val insert : t -> vec3 -> t
  val of_list : ?leaf_size:int -> vec3 list -> t
  val to_list : t -> vec3 list

  val nearest : t -> vec3 -> vec3
end

module type MAKER = functor (V3 : VEC3) -> S with type vec3 = V3.t

module type Intf = sig
  module type VEC3 = VEC3
  module type S = S
  module type MAKER = MAKER

  module Make : MAKER
end
