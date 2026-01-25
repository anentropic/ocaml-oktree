(*
  Sparse octree where leaves are Vec3 points in 3D space
  (octants without leaves are omitted)

  the octree will be an 'axis-aligned' cube
  and all three axes will have the same scale
*)
module Make = functor (V3 : Oktree_intf.VEC3) ->
struct
  type vec3 = V3.t

  (* let pp_vec3 = V3.pp *)
  let pp_vec3 fmt p =
    let x, y, z = V3.to_tuple p in
    Format.fprintf fmt "(%f, %f, %f)" x y z


  type t = {
    leaf_size : int;
    tree: tree;
  }
  and tree =
    | Node of node
    | Leaf of vec3 list
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
    mutable sed : tree;
    (* i.e. N/S E/W Up/Down *)
  } [@@deriving show, map, fold, iter]

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

  let max_depth = 20  (* see: [id_to_string] *)
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
    let o = (Bool.to_int cx) + (2 * (Bool.to_int cy)) + (4 * (Bool.to_int cz)) in
    octant_of_enum @@ o |> Option.get

  let octant_to_flags oct =
    let a = octant_to_enum oct in
    ((a land 1) == 1, (a land 2) == 2, (a land 4) == 4)

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
    and cz = V3.z ca >= V3.z cb
    in
    octant_of_flags (cx, cy, cz)

  let rec split_by centre = function
    | [] -> ([], [], [], [], [], [], [], [])
    | pt::pts -> begin
        let octant = relative_octant pt centre in
        (* recursion here is just visiting all pts in current level via head::tail, not going deeper *)
        let (swd, sed, nwd, ned, swu, seu, nwu, neu) = split_by centre pts in
        match octant with
        | SWD -> (pt::swd,     sed,     nwd,     ned,     swu,     seu,     nwu,     neu)
        | SED -> (    swd, pt::sed,     nwd,     ned,     swu,     seu,     nwu,     neu)
        | NWD -> (    swd,     sed, pt::nwd,     ned,     swu,     seu,     nwu,     neu)
        | NED -> (    swd,     sed,     nwd, pt::ned,     swu,     seu,     nwu,     neu)
        | SWU -> (    swd,     sed,     nwd,     ned, pt::swu,     seu,     nwu,     neu)
        | SEU -> (    swd,     sed,     nwd,     ned,     swu, pt::seu,     nwu,     neu)
        | NWU -> (    swd,     sed,     nwd,     ned,     swu,     seu, pt::nwu,     neu)
        | NEU -> (    swd,     sed,     nwd,     ned,     swu,     seu,     nwu, pt::neu)
      end

  let split_by' f centre half_size (swd, sed, nwd, ned, swu, seu, nwu, neu) =
    let (swd, sed, nwd, ned, swu, seu, nwu, neu) =
      tmap8 f (swd, sed, nwd, ned, swu, seu, nwu, neu)
    in
    Node {
      centre;
      half_size;
      nwu;
      nwd;
      neu;
      ned;
      swu;
      swd;
      seu;
      sed;
    }

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
    List.map (fun o -> o, child_of_octant node o) all_octants

  let rec path_to pt tree =
    match tree with
    | Leaf _ -> []
    | Node node ->
      let step = relative_octant pt node.centre in
      step :: path_to pt (child_of_octant node step)

  let rec apply_by_path f octants tree =
    match tree with
    | Leaf _ -> f tree  (* TODO not clear what hask version does here *)
    | Node node ->
      match octants with
      | [] -> f tree
      | step::path -> match step with
        | NWU -> Node { node with nwu = apply_by_path f path node.nwu }
        | NWD -> Node { node with nwd = apply_by_path f path node.nwd }
        | NEU -> Node { node with neu = apply_by_path f path node.neu }
        | NED -> Node { node with ned = apply_by_path f path node.ned }
        | SWU -> Node { node with swu = apply_by_path f path node.swu }
        | SWD -> Node { node with swd = apply_by_path f path node.swd }
        | SEU -> Node { node with seu = apply_by_path f path node.seu }
        | SED -> Node { node with sed = apply_by_path f path node.sed }

  let find_centre pts =
    match pts with
    | [] -> raise @@ Invalid_argument "Empty points list"
    | [p] -> p
    | hd::tl -> begin
        let count = List.length pts |> Float.of_int in
        V3.div (List.fold_left V3.add hd tl) (V3.of_tuple @@ repeat_3 count)
      end

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
    if len <= leaf_size
    then Leaf pts
    else
      let centre = find_centre pts in
      let cx = V3.x centre
      and cy = V3.y centre
      and cz = V3.z centre in
      let half_size =
        List.fold_left (fun acc pt ->
            let dx = abs_float (V3.x pt -. cx) in
            let dy = abs_float (V3.y pt -. cy) in
            let dz = abs_float (V3.z pt -. cz) in
            let d = max dx (max dy dz) in
            if d > acc then d else acc
          ) 0. pts
      in
      let (swd, sed, nwd, ned, swu, seu, nwu, neu) = split_by centre pts in
      let degenerate =
        List.length swd = len || List.length sed = len ||
        List.length nwd = len || List.length ned = len ||
        List.length swu = len || List.length seu = len ||
        List.length nwu = len || List.length neu = len
      in
      if degenerate
      then Leaf pts
      else
        split_by' (from_list' leaf_size) centre half_size (swd, sed, nwd, ned, swu, seu, nwu, neu)

  let insert root pt =
    let path = path_to pt root.tree in
    let insert' = function
      | Leaf l -> from_list' root.leaf_size (pt::l)
      | Node _ -> raise @@ Invalid_argument ""
    in
    apply_by_path insert' path root.tree

  let of_list ?(leaf_size=default_leaf_size) pts =
    {
      leaf_size;
      tree = from_list' leaf_size pts
    }

  (* Euclidean distance. Always positive (i.e. has no direction) *)
  let distance a b = V3.sub a b |> V3.norm
  let norm_sq v =
    let x = V3.x v
    and y = V3.y v
    and z = V3.z v in
    (x *. x) +. (y *. y) +. (z *. z)
  let distance_sq a b = V3.sub a b |> norm_sq
  (* Possible optimisation: https://stackoverflow.com/a/1678481/202168
     if we only need to 'sort' and don't care about magnitude of
     distances then the sqrt step is superfluous (I think that
     would be just V3.norm2) *)

  type candidate = Octant of node | Point of vec3 [@@deriving show]

  type point_list = vec3 list [@@deriving show]

  (* make Priority Queue types for our nearest search *)
  module PQ_Item = struct
    type t = candidate
    let compare a b =
      (* PQ appears to treat items which compare equal as dups *)
      match a, b with
      | Octant a', Octant b' -> compare a' b'
      | Octant _, Point _ -> 1
      | Point _, Octant _ -> -1
      | Point a', Point b' -> V3.compare a' b'
    let pp fmt item =
      match item with
      | Octant node -> Format.fprintf fmt "Octant(centre: %a)" pp_vec3 node.centre
      | Point point -> Format.fprintf fmt "Point%a" pp_vec3 point
  end
  module PQ_Priority = struct
    type t = float
    let compare = compare
    let pp fmt = Format.fprintf fmt (format_of_string "%f")
  end
  module PQ = Psq.Make(PQ_Item)(PQ_Priority)

  let pp_pq_pair fmt pair =
    let item, d = pair in
    Format.fprintf fmt "(%a, distance: %a)" PQ_Item.pp item PQ_Priority.pp d

  let rec to_list' pts children =
    List.concat_map (function
        | _, Leaf pts' -> pts @ pts'
        | _, Node node' -> to_list' pts (children_of_node node')
      ) children

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
    let (u, v, w) = octant_to_flags octant in
    octant_of_flags (
      (V3.x dp >= 0.) <> (not u),
      (V3.y dp >= 0.) <> (not v),
      (V3.z dp >= 0.) <> (not w)
    ) 

  let octant_distance' dp = function
    (* pt is in this octant *)
    | NEU -> 0.0
    (* adjacent by plane *)
    | NWU -> V3.x dp
    | SEU -> V3.y dp
    | NED -> V3.z dp
    (* adjacent by edge *)
    | SWU -> sqrt ( V3.x dp ** 2. +. V3.y dp ** 2.)
    | SED -> sqrt ( V3.y dp ** 2. +. V3.z dp ** 2.)
    | NWD -> sqrt ( V3.x dp ** 2. +. V3.z dp ** 2.)
    (* adjacent by vertex *)
    | SWD -> V3.norm dp

  (*
    where [dp] is difference between pt and octant centre
    ...which is like translating octant centre (with pt) to 0,0,0 origin
    and [octant] is the child octant id
  *)
  let octant_distance dp octant =
    octant_distance' (V3.map abs_float dp) (point_pos dp octant)

  let octant_distances dp =
    List.map (fun o -> (o, octant_distance dp o)) all_octants

  type candidate_list = candidate list
  [@@deriving show]

(*
-- | Finds nearest neighbour for a given point.
nearest :: Octree a -> V3 Double -> Maybe (V3 Double, a)
nearest (Leaf l) pt = pickClosest pt l
nearest node pt = selectFrom candidates
  where
    -- list of (Maybe candidate, min. bound for octant distance) tuples, sorted by min. bound
    -- `split node` is the centre point of `node`
    -- so we are comparing pt translated so that octant centre is the origin
    candidates = map findCandidate . List.sortBy compareDistance . octantDistances $ pt - split node

    compareDistance a b = compare (snd a) (snd b)

    -- finds candidates for a given octant, d arg is passed through
    -- d is the distance from the point to the centre of the octant
    findCandidate (octant, d) = (nearest' . octreeStep node $ octant, d)

    nearest' n = nearest n pt

    -- selects the best candidate from a list of candidates (via recursive h::t pattern matching)
    selectFrom ((Nothing, _d) : cs) = selectFrom cs  -- given octant is empty, try next
    selectFrom ((Just best, _d) : cs) = selectFrom' best cs  -- try to improve on current best with remaining candidates
    selectFrom [] = Nothing

    -- selects a better candidate from a list of candidates (via recursive h::t pattern matching)
    -- or returns current `best` if none better is found
    -- d is the distance from the point to the centre of the octant
    -- PG: I understood this as analogous to Priority Queue, given we already sorted the list
    selectFrom' best ((Nothing, d) : cs) = selectFrom' best cs  -- continue
    -- if candidate octant is further away than current best, just return current best
    -- TODO: FAILS: shortcut guard to avoid recursion over whole structure (since d is bound for distance within octant):
    selectFrom' best ((_, d) : cs) | d > dist pt (fst best) = Just best
    -- if candidate octant is closer (or equal) than current best, try to improve on it with remaining candidates
    selectFrom' best ((Just next, d) : cs) = selectFrom' nextBest cs
      where
        -- check the actual point distances
        nextBest =
          if dist pt (fst best) <= dist pt (fst next)
            then best
            else next
    selectFrom' best [] = Just best
*)

  let best_distance = function
    | None -> infinity
    | Some (_, d2) -> d2

  let cube_distance_sq centre half_size p =
    let dx = abs_float (V3.x p -. V3.x centre) -. half_size in
    let dy = abs_float (V3.y p -. V3.y centre) -. half_size in
    let dz = abs_float (V3.z p -. V3.z centre) -. half_size in
    let dx = if dx > 0. then dx else 0. in
    let dy = if dy > 0. then dy else 0. in
    let dz = if dz > 0. then dz else 0. in
    (dx *. dx) +. (dy *. dy) +. (dz *. dz)

  let update_best_from_points best p points =
    match points with
    | [] -> best
    | hd::tl ->
      let (best_pt, best_d2), rest_points =
        match best with
        | None -> ((hd, distance_sq p hd), tl)
        | Some (pt, d2) -> ((pt, d2), points)
      in
      let best_pt, best_d2 =
        List.fold_left (fun (best_pt, best_d2) pt ->
            let d2 = distance_sq p pt in
            if d2 < best_d2 then (pt, d2) else (best_pt, best_d2)
          ) (best_pt, best_d2) rest_points
      in
      Some (best_pt, best_d2)

  let enqueue_node_with_best best pq node p =
    let enqueue_child best pq child =
      match child with
      | Leaf points -> (update_best_from_points best p points, pq)
      | Node child_node ->
        let d2 = cube_distance_sq child_node.centre child_node.half_size p in
        if d2 < best_distance best
        then (best, PQ.add (Octant child_node) d2 pq)
        else (best, pq)
    in
    let best, pq = enqueue_child best pq node.nwu in
    let best, pq = enqueue_child best pq node.nwd in
    let best, pq = enqueue_child best pq node.neu in
    let best, pq = enqueue_child best pq node.ned in
    let best, pq = enqueue_child best pq node.swu in
    let best, pq = enqueue_child best pq node.swd in
    let best, pq = enqueue_child best pq node.seu in
    enqueue_child best pq node.sed

  (* TODO return option type instead of raise Not_found ? *)
  let rec nearest' best pq p =
    match PQ.pop pq with
    | None -> begin
        match best with
        | None -> raise Not_found  (* would mean our tree was empty *)
        | Some (pt, _) -> pt
      end
    | Some ((candidate, d2), pq') -> begin
        match candidate with
        | Point pt -> begin
            let best' =
              if d2 < best_distance best
              then Some (pt, d2)
              else best
            in
            nearest' best' pq' p
          end
        | Octant node ->
          let best', pq'' = enqueue_node_with_best best pq' node p in
          nearest' best' pq'' p
      end

  let node_nearest node p =
    let best, pq = enqueue_node_with_best None PQ.empty node p in
    nearest' best pq p

  let nearest root p =
    match root with
    | Node node -> node_nearest node p
    | Leaf points ->
      let best = update_best_from_points None p points in
      nearest' best PQ.empty p

  (* brute-force, for debugging *)
  let distances root p =
    List.map (fun p' -> (p', distance p p')) (to_list root)

  let rec print_centres ?(label="Root") tree =
    ignore @@ match tree with
    | Node n -> begin
        Format.printf "<%s> centre: %a\n" label pp_vec3 n.centre;
        List.iter (fun o ->
            let child = child_of_octant n o in
            print_centres ~label:(show_octant o) child
          ) all_octants
      end
    | Leaf _ -> ()

  let rec print_centre_distances ?(label="Root") tree p =
    ignore @@ match tree with
    | Node n -> begin
        Format.printf "<%s> p-to-centre: %f\n" label (distance n.centre p);
        List.iter (fun o ->
            let child = child_of_octant n o in
            let label = label ^ ": " ^ (show_octant o) in
            Format.printf "<%s> p-to-surface: %f\n" label (octant_distance p o);
            print_centre_distances ~label child p
          ) all_octants
      end
    | Leaf _ -> ()
end
