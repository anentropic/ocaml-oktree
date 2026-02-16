module O = Oktree.Make (Gg.V3)

let pp_vec3 fmt p =
  let x, y, z = Gg.V3.to_tuple p in
  Format.fprintf fmt "(%f, %f, %f)" x y z

let pp_point_list fmt =
  let pp_sep fmt' () = Format.pp_print_string fmt' "; " in
  let ppl fmt' = Format.pp_print_list ~pp_sep pp_vec3 fmt' in
  Format.fprintf fmt "[%a]" ppl

let gen_ggv3 low high =
  let open QCheck2.Gen in
  let* x = float_range low high in
  let* y = float_range low high in
  let* z = float_range low high in
  return (Gg.V3.v x y z)

let ggv3_testable =
  Alcotest.testable Gg.V3.pp (fun a b -> Gg.V3.compare a b = 0)

let sort_ggv3_list = List.sort Gg.V3.compare
let distance a b = Gg.V3.sub a b |> Gg.V3.norm

(* brute force oracle *)
let nearest points p =
  if List.length points = 0 then
    raise @@ Invalid_argument "nearest oracle: points list was empty"
  else
    let sorted =
      List.map (fun p' -> (distance p' p, p')) points |> List.sort compare
    in
    let _, result = List.hd sorted in
    result

let from_tuples l = List.map (fun (x, y, z) -> Gg.V3.v x y z) l

(* UNIT TESTS *)

let test_of_list () =
  let expected = [ Gg.V3.ox; Gg.V3.oy; Gg.V3.oz ] |> sort_ggv3_list in
  let okt = O.of_list expected in
  let actual = O.to_list okt |> sort_ggv3_list in
  Alcotest.(check (list ggv3_testable)) "preserves points" expected actual

let nearest_handpicked_tests =
  let make (points, target) () =
    let okt = O.of_list points in
    let expected = nearest points target in
    let result = O.nearest okt target in
    Alcotest.check ggv3_testable "nearest point" expected result
  in
  let args =
    [
      ( [ Gg.V3.zero; Gg.V3.v 0. 0.251 0.; Gg.V3.v 0. 0.23 0.; Gg.V3.v 0.2 0.1 0.2 ],
        Gg.V3.v 0.24 0.24 0.24 );
      ( [ Gg.V3.v 0.22211 0.310896 0.380155; Gg.V3.v 0. 0. 0.; Gg.V3.v 0.154595 0.444363 0.909263 ],
        Gg.V3.v 0.3333 0.41 0.6667 );
      ( [ Gg.V3.v 0. 0.849467 0.16977; Gg.V3.v 0. 0. 0.175422 ],
        Gg.V3.v 0.3333 0.41 0.6667 );
      ( [ Gg.V3.v 0.0408104 0.120397 0.712801; Gg.V3.v 0.754196 0.425501 0.700406 ],
        Gg.V3.v 0.3333 0.41 0.6667 );
      (*
        Copilot added this set, duplicates and all. Presumably to capture PBT cases that failed during dev:
      *)
      ( from_tuples
          [
            (0.000000, 0.135509, 0.558065);
            (0.000000, 0.000000, 0.251862);
            (0.000000, 0.000000, 0.309942);
            (0.000000, 0.818889, 0.000000);
            (0.558965, 0.114604, 0.000000);
            (0.000000, 0.000000, 0.000000);
            (0.000000, 0.000000, 0.297470);
            (0.000000, 0.000000, 0.449710);
            (0.000000, 0.000000, 0.302328);
            (0.497573, 0.000000, 0.000000);
            (0.000000, 0.000000, 0.449739);
            (0.000000, 0.000000, 0.302581);
            (0.000000, 0.933309, 0.000000);
            (0.000000, 0.000000, 0.000000);
            (0.000000, 0.000000, 0.321395);
            (0.000000, 0.000000, 0.407899);
            (0.032235, 0.087385, 0.615754);
            (0.000000, 0.373305, 0.000000);
            (0.000000, 0.000000, 0.432156);
            (0.000000, 0.000000, 0.000000);
            (0.000000, 0.000000, 0.247959);
            (0.000000, 0.000000, 0.361187);
            (0.000000, 0.000000, 0.000000);
            (0.000000, 0.000000, 0.483175);
            (0.000000, 0.000000, 0.367874);
            (0.000000, 0.000000, 0.445183);
            (0.000000, 0.000000, 0.000000);
            (0.000000, 0.000000, 0.306433);
          ],
        Gg.V3.v 0.3333 0.41 0.6667 );
    ]
  in
  List.mapi
    (fun i arg ->
       Alcotest.test_case (Printf.sprintf "handpicked case %d vs brute-force oracle" i) `Quick (make arg))
    args

let test_nearest_sample_empty () =
  let okt = O.of_list [] in
  let p = Gg.V3.v 0.2 0.5 0.7 in
  match O.nearest okt p with
  | _ -> Alcotest.fail "expected Not_found"
  | exception Not_found -> ()

let test_empty_tree () =
  let okt = O.of_list [] in
  let points = O.to_list okt in
  Alcotest.(check (list ggv3_testable)) "empty" [] points

let test_single_point () =
  let pt = Gg.V3.v 0.5 0.5 0.5 in
  let okt = O.of_list [ pt ] in
  let points = O.to_list okt in
  Alcotest.(check (list ggv3_testable)) "single point" [ pt ] points

let test_duplicate_points () =
  let pt = Gg.V3.zero in
  let okt = O.of_list [ pt; pt; pt ] in
  let points = O.to_list okt |> sort_ggv3_list in
  Alcotest.(check (list ggv3_testable)) "duplicates preserved" [ pt; pt; pt ] points

let test_nearest_single_point () =
  let pt = Gg.V3.v 0.1 0.2 0.3 in
  let okt = O.of_list [ pt ] in
  let query = Gg.V3.v 0.5 0.5 0.5 in
  let result = O.nearest okt query in
  Alcotest.check ggv3_testable "only point" pt result

let test_insert_to_empty () =
  let okt = O.of_list [] in
  let pt = Gg.V3.v 0.5 0.5 0.5 in
  let new_okt = O.insert okt pt in
  let points = O.to_list new_okt in
  Alcotest.(check (list ggv3_testable)) "inserted point" [ pt ] points

let test_insert_multiple () =
  let pt1 = Gg.V3.v 0.1 0.1 0.1 in
  let okt1 = O.of_list [ pt1 ] in
  let pt2 = Gg.V3.v 0.9 0.9 0.9 in
  let okt2 = O.insert okt1 pt2 in
  let points = O.to_list okt2 |> sort_ggv3_list in
  Alcotest.(check (list ggv3_testable)) "both points" (sort_ggv3_list [ pt1; pt2 ]) points

let test_points_at_boundaries () =
  let points =
    [
      Gg.V3.v 0. 0. 0.;
      Gg.V3.v 1. 1. 1.;
      Gg.V3.v 0. 1. 0.;
      Gg.V3.v 1. 0. 1.;
    ]
  in
  let okt = O.of_list points in
  let result = O.to_list okt |> sort_ggv3_list in
  Alcotest.(check (list ggv3_testable)) "boundary points" (sort_ggv3_list points) result

let test_invalid_leaf_size leaf_size () =
  let points = [ Gg.V3.ox; Gg.V3.oy; Gg.V3.oz ] in
  match O.of_list ~leaf_size points with
  | _ -> Alcotest.fail (Printf.sprintf "leaf_size %d should raise" leaf_size)
  | exception Invalid_argument _ -> ()

(* PROPERTY-BASED TESTS *)

let qcheck_of_list_to_list_nonempty =
  QCheck2.Test.make ~name:"[PBT] of_list/to_list roundtrip preserves all points"
    ~print:(Format.asprintf "%a" pp_point_list)
    QCheck2.Gen.(list_size (int_range 1 100) (gen_ggv3 0. 1.))
    (fun points ->
       let okt = O.of_list points in
       let expected = points |> sort_ggv3_list in
       let actual = O.to_list okt |> sort_ggv3_list in
       List.length expected = List.length actual
       && List.for_all2 (fun a b -> Gg.V3.compare a b = 0) expected actual)

let qcheck_of_list_leaf_size =
  let open QCheck2.Gen in
  let gen =
    let* leaf_size = int_range 1 32 in
    let* points = list_size (int_range 1 100) (gen_ggv3 0. 1.) in
    return (leaf_size, points)
  in
  QCheck2.Test.make ~name:"[PBT] of_list with random leaf_size preserves all points"
    ~print:(fun (ls, pts) ->
        Printf.sprintf "leaf_size=%d, %s" ls
          (Format.asprintf "%a" pp_point_list pts))
    gen
    (fun (leaf_size, points) ->
       let okt = O.of_list ~leaf_size points in
       let expected = points |> sort_ggv3_list in
       let actual = O.to_list okt |> sort_ggv3_list in
       List.length expected = List.length actual
       && List.for_all2 (fun a b -> Gg.V3.compare a b = 0) expected actual)

let qcheck_nearest_random_target_nonempty_tree =
  let open QCheck2.Gen in
  let gen =
    let* points = list_size (int_range 1 100) (gen_ggv3 0. 1.) in
    let* target = gen_ggv3 0. 1. in
    return (points, target)
  in
  QCheck2.Test.make ~name:"[PBT] nearest matches brute-force oracle on random points"
    ~print:(fun (pts, tgt) ->
        Format.asprintf "target=%a, points=%a" Gg.V3.pp tgt pp_point_list pts)
    gen
    (fun (points, target) ->
       let okt = O.of_list points in
       let expected = nearest points target in
       let result = O.nearest okt target in
       Gg.V3.compare result expected = 0)

let qcheck_insert =
  let open QCheck2.Gen in
  let gen =
    let* points = list_size (int_range 1 50) (gen_ggv3 0. 1.) in
    let* new_pt = gen_ggv3 0. 1. in
    return (points, new_pt)
  in
  QCheck2.Test.make ~name:"[PBT] insert preserves all points in to_list"
    ~print:(fun (pts, pt) ->
        Format.asprintf "new=%a, points=%a" Gg.V3.pp pt pp_point_list pts)
    gen
    (fun (points, new_pt) ->
       let okt = O.of_list points in
       let okt' = O.insert okt new_pt in
       let expected = (new_pt :: points) |> sort_ggv3_list in
       let actual = O.to_list okt' |> sort_ggv3_list in
       List.length expected = List.length actual
       && List.for_all2 (fun a b -> Gg.V3.compare a b = 0) expected actual)

let qcheck_insert_nearest =
  let open QCheck2.Gen in
  let gen =
    let* points = list_size (int_range 1 50) (gen_ggv3 0. 1.) in
    let* new_pt = gen_ggv3 0. 1. in
    return (points, new_pt)
  in
  QCheck2.Test.make ~name:"[PBT] nearest returns inserted point when queried at same location"
    ~print:(fun (pts, pt) ->
        Format.asprintf "new=%a, points=%a" Gg.V3.pp pt pp_point_list pts)
    gen
    (fun (points, new_pt) ->
       let okt = O.of_list points in
       let okt' = O.insert okt new_pt in
       let result = O.nearest okt' new_pt in
       Gg.V3.compare result new_pt = 0)

let test_pp_smoke () =
  let okt = O.of_list [ Gg.V3.zero; Gg.V3.v 0.5 0.5 0.5 ] in
  let s = Format.asprintf "%a" O.pp okt in
  Alcotest.(check bool) "pp produces non-empty output" true (String.length s > 0)

(* RUNNER *)

let () =
  let report_path =
    try Some (Sys.getenv "JUNIT_REPORT_PATH") with Not_found -> None
  in
  let testsuite, exit_fn =
    Junit_alcotest.run_and_report ~and_exit:false "oktree"
      [
        ( "of_list",
          [
            Alcotest.test_case "roundtrip of_list/to_list with 3 static points" `Quick test_of_list;
          ]
          @ List.map QCheck_alcotest.to_alcotest
            [ qcheck_of_list_to_list_nonempty; qcheck_of_list_leaf_size ] );
        ( "nearest",
          nearest_handpicked_tests
          @ [
            Alcotest.test_case "raises Not_found on empty tree" `Quick test_nearest_sample_empty;
            Alcotest.test_case "returns sole point in singleton tree" `Quick test_nearest_single_point;
          ]
          @ List.map QCheck_alcotest.to_alcotest
            [ qcheck_nearest_random_target_nonempty_tree ] );
        ( "insert",
          [
            Alcotest.test_case "insert into empty tree" `Quick test_insert_to_empty;
            Alcotest.test_case "sequential inserts preserve all points" `Quick test_insert_multiple;
          ]
          @ List.map QCheck_alcotest.to_alcotest
            [ qcheck_insert; qcheck_insert_nearest ] );
        ( "edge_cases",
          [
            Alcotest.test_case "of_list [] produces empty tree" `Quick test_empty_tree;
            Alcotest.test_case "of_list with single point" `Quick test_single_point;
            Alcotest.test_case "of_list preserves duplicate points" `Quick test_duplicate_points;
            Alcotest.test_case "of_list with boundary coordinates 0 and 1" `Quick test_points_at_boundaries;
            Alcotest.test_case "pp produces non-empty output" `Quick test_pp_smoke;
            Alcotest.test_case "of_list ~leaf_size:0 raises Invalid_argument" `Quick (test_invalid_leaf_size 0);
            Alcotest.test_case "of_list ~leaf_size:(-1) raises Invalid_argument" `Quick (test_invalid_leaf_size (-1));
            Alcotest.test_case "of_list ~leaf_size:(-10) raises Invalid_argument" `Quick (test_invalid_leaf_size (-10));
          ] );
      ]
  in
  (match report_path with
   | Some path -> Junit.to_file (Junit.make [ testsuite ]) path
   | None -> ());
  exit_fn ()
