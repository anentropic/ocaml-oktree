(*
  Sparse octree where leaves are Vec3 points in 3D space
  (octants without leaves are omitted)

  the octree will be an 'axis-aligned' cube
  and all three axes will have the same scale
*)
module Make =
  functor
    (V3 : Oktree_intf.VEC3)
    ->
    struct
      type vec3 = V3.t

      (* let pp_vec3 = V3.pp *)
      let pp_vec3 fmt p =
        let x, y, z = V3.to_tuple p in
        Format.fprintf fmt "(%f, %f, %f)" x y z

      type t = { leaf_size : int; tree : tree }
      and tree = Node of node | Leaf of vec3 list

      and node = {
        centre : vec3;
        half_size : float;
        mutable nwu : tree;
        mutable nwd : tree;
        mutable neu : tree;
        mutable ned : tree;
        mutable swu : tree;
        mutable swd : tree;
        mutable seu : tree;
        mutable sed : tree; (* i.e. N/S E/W Up/Down *)
      }
      [@@deriving show, map, fold, iter]

    (*
  Nodes array structure:
    octant  index  bits
    x0_y0_z0: 0 | 0 0 0
    x0_y0_z1: 1 | 0 0 1
    x0_y1_z0: 2 | 0 1 0
    x0_y1_z1: 3 | 0 1 1
    x1_y0_z0: 4 | 1 0 0
    x1_y0_z1: 5 | 1 0 1
    x1_y1_z0: 6 | 1 1 0
    x1_y1_z1: 7 | 1 1 1
  *)

      let max_depth = 20 (* see: [id_to_string] *)
      let default_leaf_size = 16
      let repeat_3 a = (a, a, a)

      let tmap8 f (swd, sed, nwd, ned, swu, seu, nwu, neu) =
        (f swd, f sed, f nwd, f ned, f swu, f seu, f nwu, f neu)

      type octant = SWD | SED | NWD | NED | SWU | SEU | NWU | NEU
      [@@deriving eq, ord, enum, show, iter]

      let all_octants =
        List.init (max_octant + 1) (fun i -> octant_of_enum i |> Option.get)

    (*
    joinStep :: (Enum a1, Enum a3, Enum a2, Enum a) => (a1, a2, a3) -> a
    joinStep (cx, cy, cz) = toEnum (fromEnum cx + 2 * fromEnum cy + 4 * fromEnum cz)
  *)
      let octant_of_flags (cx, cy, cz) =
        let o = Bool.to_int cx + (2 * Bool.to_int cy) + (4 * Bool.to_int cz) in
        octant_of_enum @@ o |> Option.get

      let octant_to_flags oct =
        let a = octant_to_enum oct in
        (a land 1 == 1, a land 2 == 2, a land 4 == 4)

    (*
    gives octant of a first vector relative to the second vector as a center

    can we say x:N-S, y:E-W, z:U-D?

    cmp :: V3 Double -> V3 Double -> ODir
    cmp ca cb = joinStep (cx, cy, cz)
      where cx = v3x ca >= v3x cb
            cy = v3y ca >= v3y cb
            cz = v3z ca >= v3z cb
  *)
      let relative_octant ca cb =
        let cx = V3.x ca >= V3.x cb
        and cy = V3.y ca >= V3.y cb
        and cz = V3.z ca >= V3.z cb in
        octant_of_flags (cx, cy, cz)

      let rec split_by centre = function
        | [] -> ([], [], [], [], [], [], [], [])
        | pt :: pts -> (
            let octant = relative_octant pt centre in
            (* recursion here is just visiting all pts in current level via head::tail, not going deeper *)
            let swd, sed, nwd, ned, swu, seu, nwu, neu = split_by centre pts in
            match octant with
            | SWD -> (pt :: swd, sed, nwd, ned, swu, seu, nwu, neu)
            | SED -> (swd, pt :: sed, nwd, ned, swu, seu, nwu, neu)
            | NWD -> (swd, sed, pt :: nwd, ned, swu, seu, nwu, neu)
            | NED -> (swd, sed, nwd, pt :: ned, swu, seu, nwu, neu)
            | SWU -> (swd, sed, nwd, ned, pt :: swu, seu, nwu, neu)
            | SEU -> (swd, sed, nwd, ned, swu, pt :: seu, nwu, neu)
            | NWU -> (swd, sed, nwd, ned, swu, seu, pt :: nwu, neu)
            | NEU -> (swd, sed, nwd, ned, swu, seu, nwu, pt :: neu))

      let split_by' f centre half_size (swd, sed, nwd, ned, swu, seu, nwu, neu) =
        let swd, sed, nwd, ned, swu, seu, nwu, neu =
          tmap8 f (swd, sed, nwd, ned, swu, seu, nwu, neu)
        in
        Node { centre; half_size; nwu; nwd; neu; ned; swu; swd; seu; sed }

      let child_of_octant node = function
        | NWU -> node.nwu
        | NWD -> node.nwd
        | NEU -> node.neu
        | NED -> node.ned
        | SWU -> node.swu
        | SWD -> node.swd
        | SEU -> node.seu
        | SED -> node.sed

      let children_of_node node =
        List.map (fun o -> (o, child_of_octant node o)) all_octants

      let rec path_to pt tree =
        match tree with
        | Leaf _ -> []
        | Node node ->
          let step = relative_octant pt node.centre in
          step :: path_to pt (child_of_octant node step)

      let rec apply_by_path f octants tree =
        match tree with
        | Leaf _ -> f tree (* TODO not clear what hask version does here *)
        | Node node -> (
            match octants with
            | [] -> f tree
            | step :: path -> (
                match step with
                | NWU -> Node { node with nwu = apply_by_path f path node.nwu }
                | NWD -> Node { node with nwd = apply_by_path f path node.nwd }
                | NEU -> Node { node with neu = apply_by_path f path node.neu }
                | NED -> Node { node with ned = apply_by_path f path node.ned }
                | SWU -> Node { node with swu = apply_by_path f path node.swu }
                | SWD -> Node { node with swd = apply_by_path f path node.swd }
                | SEU -> Node { node with seu = apply_by_path f path node.seu }
                | SED -> Node { node with sed = apply_by_path f path node.sed }))

      let find_centre pts =
        match pts with
        | [] -> raise @@ Invalid_argument "Empty points list"
        | [ p ] -> p
        | hd :: tl ->
          let count = List.length pts |> Float.of_int in
          V3.div (List.fold_left V3.add hd tl) (V3.of_tuple @@ repeat_3 count)

    (*
    [leaf_size] is max points per leaf before splitting
    so we recursively split on the centre point of the *points* in each octant
    NOTE: as per the 'hask' implementation, cannot insert to existing node, only leaf

    TODO: we inherit this bug when no. of duplicate points > leaf_size
    https://github.com/BioHaskell/octree/issues/14

    Also... duplicate points will skew the calculation of [find_centre] since
    it is finding the mean point
  *)
      let rec from_list' leaf_size pts =
        let len = List.length pts in
        if len <= leaf_size then Leaf pts
        else
          let centre = find_centre pts in
          let cx = V3.x centre and cy = V3.y centre and cz = V3.z centre in
          let half_size =
            List.fold_left
              (fun acc pt ->
                 let dx = abs_float (V3.x pt -. cx) in
                 let dy = abs_float (V3.y pt -. cy) in
                 let dz = abs_float (V3.z pt -. cz) in
                 let d = max dx (max dy dz) in
                 if d > acc then d else acc)
              0. pts
          in
          let swd, sed, nwd, ned, swu, seu, nwu, neu = split_by centre pts in
          let degenerate =
            List.length swd = len
            || List.length sed = len
            || List.length nwd = len
            || List.length ned = len
            || List.length swu = len
            || List.length seu = len
            || List.length nwu = len
            || List.length neu = len
          in
          if degenerate then Leaf pts
          else
            split_by' (from_list' leaf_size) centre half_size
              (swd, sed, nwd, ned, swu, seu, nwu, neu)

      let insert root pt =
        let path = path_to pt root.tree in
        let insert' = function
          | Leaf l -> from_list' root.leaf_size (pt :: l)
          | Node _ ->
            raise @@ Invalid_argument "Cannot insert into a Node - inserts can only be performed on Leaf nodes"
        in
        apply_by_path insert' path root.tree

      let of_list ?(leaf_size = default_leaf_size) pts =
        { leaf_size; tree = from_list' leaf_size pts }

      let tree_of t = t.tree

      (* Euclidean distance. Always positive (i.e. has no direction) *)
      let distance a b = V3.sub a b |> V3.norm

      let distance_sq_coords px py pz pt =
        let dx = V3.x pt -. px in
        let dy = V3.y pt -. py in
        let dz = V3.z pt -. pz in
        (dx *. dx) +. (dy *. dy) +. (dz *. dz)
      let rec to_list' pts children =
        List.concat_map
          (function
            | _, Leaf pts' -> pts @ pts'
            | _, Node node' -> to_list' pts (children_of_node node'))
          children

      let to_list = function
        | Leaf points -> points
        | Node node -> to_list' [] (children_of_node node)

    (*
    NOTE: the returned 'octant' no longer represents an octant
    per se but one of 8 derived possibilities
    ...this is a confusing overloading!
    ...but it saves creating another 8 member variant and
      identical join/split functions 

    we can see in [octant_distance'] below what they mean
    i.e. NEU means pt is "in the tested octant"

    The boolean checks expand out like:
      true != (not false) -> false
      false != (not false) -> true
      true != (not true) -> true
      false != (not true) -> false

    so to get NEU we need:
      x >= 0 and u = true  -> confirmed in the +x octant
      x < 0  and u = false -> confirmed in the -x octant
      etc

    and then when fewer bits are set we get the other options
  *)
      let point_pos dp octant =
        let u, v, w = octant_to_flags octant in
        octant_of_flags
          (V3.x dp >= 0. <> not u, V3.y dp >= 0. <> not v, V3.z dp >= 0. <> not w)

      let octant_distance' dp = function
        (* pt is in this octant *)
        | NEU -> 0.0
        (* adjacent by plane *)
        | NWU -> V3.x dp
        | SEU -> V3.y dp
        | NED -> V3.z dp
        (* adjacent by edge *)
        | SWU -> sqrt ((V3.x dp ** 2.) +. (V3.y dp ** 2.))
        | SED -> sqrt ((V3.y dp ** 2.) +. (V3.z dp ** 2.))
        | NWD -> sqrt ((V3.x dp ** 2.) +. (V3.z dp ** 2.))
        (* adjacent by vertex *)
        | SWD -> V3.norm dp

    (*
    where [dp] is difference between pt and octant centre
    ...which is like translating octant centre (with pt) to 0,0,0 origin
    and [octant] is the child octant id
  *)
      let octant_distance dp octant =
        octant_distance' (V3.map abs_float dp) (point_pos dp octant)

      (* Depth-first nearest neighbor search with aggressive pruning.
                   Key optimizations:
                   1. Visit the octant containing the query point first (most likely to have nearest)
                   2. Prune octants whose closest point is farther than current best
                   3. No heap allocation - pure recursive traversal *)

      let[@inline] cube_dist_sq px py pz cx cy cz hs =
        let dx = abs_float (px -. cx) -. hs in
        let dy = abs_float (py -. cy) -. hs in
        let dz = abs_float (pz -. cz) -. hs in
        let dx = if dx > 0. then dx else 0. in
        let dy = if dy > 0. then dy else 0. in
        let dz = if dz > 0. then dz else 0. in
        (dx *. dx) +. (dy *. dy) +. (dz *. dz)

      let[@inline] search_leaf best_d2 best_pt px py pz points =
        let rec loop best_d2 best_pt = function
          | [] -> (best_d2, best_pt)
          | pt :: rest ->
            let d2 = distance_sq_coords px py pz pt in
            if d2 < best_d2 then loop d2 (Some pt) rest
            else loop best_d2 best_pt rest
        in
        loop best_d2 best_pt points

      (* Search a single child, returning updated best *)
      let rec search_child best_d2 best_pt px py pz child =
        match child with
        | Leaf points -> search_leaf best_d2 best_pt px py pz points
        | Node n ->
          let cx = V3.x n.centre
          and cy = V3.y n.centre
          and cz = V3.z n.centre in
          let d2 = cube_dist_sq px py pz cx cy cz n.half_size in
          if d2 >= best_d2 then (best_d2, best_pt)
          else search_node best_d2 best_pt px py pz n

      (* Search all 8 children of a node, starting with the one containing the query point *)
      and search_node best_d2 best_pt px py pz node =
        let cx = V3.x node.centre
        and cy = V3.y node.centre
        and cz = V3.z node.centre in
        (* Determine which octant the query point is in *)
        let ge_x = px >= cx and ge_y = py >= cy and ge_z = pz >= cz in
        (* Get children in order from primary octant outward *)
        let c0, c1, c2, c3, c4, c5, c6, c7 =
          match (ge_x, ge_y, ge_z) with
          | false, false, false ->
            ( node.swd,
              node.sed,
              node.nwd,
              node.swu,
              node.ned,
              node.seu,
              node.nwu,
              node.neu )
          | true, false, false ->
            ( node.sed,
              node.swd,
              node.ned,
              node.seu,
              node.nwd,
              node.swu,
              node.neu,
              node.nwu )
          | false, true, false ->
            ( node.nwd,
              node.ned,
              node.swd,
              node.nwu,
              node.sed,
              node.swu,
              node.neu,
              node.seu )
          | true, true, false ->
            ( node.ned,
              node.nwd,
              node.sed,
              node.neu,
              node.swd,
              node.seu,
              node.nwu,
              node.swu )
          | false, false, true ->
            ( node.swu,
              node.seu,
              node.nwu,
              node.swd,
              node.neu,
              node.sed,
              node.nwd,
              node.ned )
          | true, false, true ->
            ( node.seu,
              node.swu,
              node.neu,
              node.sed,
              node.nwu,
              node.swd,
              node.ned,
              node.nwd )
          | false, true, true ->
            ( node.nwu,
              node.neu,
              node.swu,
              node.nwd,
              node.seu,
              node.swd,
              node.ned,
              node.sed )
          | true, true, true ->
            ( node.neu,
              node.nwu,
              node.seu,
              node.ned,
              node.swu,
              node.nwd,
              node.sed,
              node.swd )
        in
        (* Search all children in order, with pruning *)
        let best_d2, best_pt = search_child best_d2 best_pt px py pz c0 in
        let best_d2, best_pt = search_child best_d2 best_pt px py pz c1 in
        let best_d2, best_pt = search_child best_d2 best_pt px py pz c2 in
        let best_d2, best_pt = search_child best_d2 best_pt px py pz c3 in
        let best_d2, best_pt = search_child best_d2 best_pt px py pz c4 in
        let best_d2, best_pt = search_child best_d2 best_pt px py pz c5 in
        let best_d2, best_pt = search_child best_d2 best_pt px py pz c6 in
        search_child best_d2 best_pt px py pz c7

      let nearest root p =
        let px = V3.x p and py = V3.y p and pz = V3.z p in
        match root with
        | Leaf points -> (
            match search_leaf infinity None px py pz points with
            | _, None -> raise Not_found
            | _, Some pt -> pt)
        | Node node -> (
            match search_node infinity None px py pz node with
            | _, None -> raise Not_found
            | _, Some pt -> pt)

      (* brute-force, for debugging *)
      let distances root p =
        List.map (fun p' -> (p', distance p p')) (to_list root)

      let rec print_centres ?(label = "Root") tree =
        ignore
        @@
        match tree with
        | Node n ->
          Format.printf "<%s> centre: %a\n" label pp_vec3 n.centre;
          List.iter
            (fun o ->
               let child = child_of_octant n o in
               print_centres ~label:(show_octant o) child)
            all_octants
        | Leaf _ -> ()

      let rec print_centre_distances ?(label = "Root") tree p =
        ignore
        @@
        match tree with
        | Node n ->
          Format.printf "<%s> p-to-centre: %f\n" label (distance n.centre p);
          List.iter
            (fun o ->
               let child = child_of_octant n o in
               let label = label ^ ": " ^ show_octant o in
               Format.printf "<%s> p-to-surface: %f\n" label
                 (octant_distance (V3.sub p n.centre) o);
               print_centre_distances ~label child p)
            all_octants
        | Leaf _ -> ()
    end
