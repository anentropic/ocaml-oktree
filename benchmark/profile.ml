open Gg

[@@@landmark "auto-off"]

module O = Oktree.Make (V3)

let default_n_points = 4096
let default_n_queries = 10000

let random_seed () =
  let state = Random.State.make_self_init () in
  Random.State.bits state

let parse_args () =
  let n_points = ref default_n_points in
  let seed = ref None in
  let n_queries = ref default_n_queries in
  let specs =
    [
      ( "--n-points",
        Arg.Int (fun n -> n_points := n),
        Printf.sprintf "Number of points to pre-generate (default: %d)" default_n_points
      );
      ( "--n-queries",
        Arg.Int (fun n -> n_queries := n),
        Printf.sprintf "Number of nearest queries to run (default: %d)" default_n_queries
      );
      ( "--seed",
        Arg.Int (fun s -> seed := Some s),
        "Random seed (default: random per run)" );
    ]
  in
  let usage =
    Printf.sprintf
      "Usage: %s [--n-points INT] [--n-queries INT] [--seed INT]"
      Sys.argv.(0)
  in
  Arg.parse specs (fun arg -> raise (Arg.Bad ("Unknown argument: " ^ arg))) usage;
  if !n_points <= 0 then raise (Arg.Bad "--n-points must be > 0");
  if !n_queries <= 0 then raise (Arg.Bad "--n-queries must be > 0");
  let seed = match !seed with Some s -> s | None -> random_seed () in
  (!n_points, !n_queries, seed)

let gaussian rng =
  let epsilon = 1e-12 in
  let u1 = Random.State.float rng 1. in
  let u1 = if u1 <= 0. then epsilon else u1 in
  let u2 = Random.State.float rng 1. in
  sqrt (-2. *. log u1) *. cos (2. *. Float.pi *. u2)

let point rng = V3.v (gaussian rng) (gaussian rng) (gaussian rng)

let generate_points rng n = List.init n (fun _ -> point rng)

let nearest_landmark = Landmark.register "oktree.nearest"

let profile_options =
  let options = Landmark.default_options in
  {
    options with
    output = Landmark.Channel stdout;
    format = Landmark.Textual { threshold = 0.0 };
    sys_time = true;
    allocated_bytes = true;
  }

let start_nearest_profiling () =
  Landmark.set_profiling_options profile_options;
  if Landmark.profiling () then (
    Landmark.stop_profiling ();
    Landmark.reset ());
  Landmark.start_profiling ()

let () =
  let n_points, n_queries, seed = parse_args () in
  let rng = Random.State.make [| seed |] in
  let pts = generate_points rng n_points in
  let oktree = O.of_list pts in
  let queries = generate_points rng n_queries in
  start_nearest_profiling ();
  List.iter
    (fun target ->
       Landmark.enter nearest_landmark;
       ignore (O.nearest oktree target);
       Landmark.exit nearest_landmark)
    queries;
  Landmark.stop_profiling ();
  let graph =
    Landmark.export_and_reset
      ~label:
        (Printf.sprintf
           "oktree.nearest --n-points %d --n-queries %d --seed %d"
           n_points n_queries seed)
      ()
  in
  Landmark.Graph.output ~threshold:0.0 stdout graph;
  flush stdout
