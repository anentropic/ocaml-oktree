open Gg
open Core_bench

(*
  NOTE: only OCaml 5+ due to incompatibility with older Core_bench/Core_unix
  dune build @runtest
  dune exec benchmark/nearest.exe -- -quota 3 -stabilize-gc
*)

module O = Oktree.Make (V3)

let clamp01 x = if x < 0. then 0. else if x > 1. then 1. else x
let uniform01 rng = Random.State.float rng 1.

let gaussian01 rng =
  let u1 = Random.State.float rng 1. in
  let u2 = Random.State.float rng 1. in
  let z0 = sqrt (-2. *. log u1) *. cos (2. *. Float.pi *. u2) in
  clamp01 (0.5 +. (0.15 *. z0))

let point rng dist = V3.v (dist rng) (dist rng) (dist rng)
let points rng dist n = List.init n (fun _ -> point rng dist)

let make_tests ~name ~dist ~seed ~sizes ~n_queries =
  let rng = Random.State.make [| seed |] in
  List.map
    (fun n_points ->
       let pts = points rng dist n_points in
       let queries = points rng dist n_queries in
       let okt = O.of_list pts in
       Bench.Test.create
         ~name:(Printf.sprintf "%s pts:%d queries:%d" name n_points n_queries)
         (fun () -> List.iter (fun q -> ignore (O.nearest okt q)) queries))
    sizes

let main () =
  let sizes = [ 256; 1024; 4096; 16384 ] in
  let n_queries = 256 in
  let tests =
    [
      Bench.Test.create_group ~name:"Uniform"
      @@ make_tests ~name:"uniform" ~dist:uniform01 ~seed:1 ~sizes ~n_queries;
      Bench.Test.create_group ~name:"Normal"
      @@ make_tests ~name:"normal" ~dist:gaussian01 ~seed:2 ~sizes ~n_queries;
    ]
  in
  Command_unix.run (Bench.make_command tests)

let () = main ()
