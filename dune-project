(lang dune 3.9)
(name oktree)
(version 0.2.1)

(generate_opam_files true)

(source (github anentropic/ocaml-oktree))
(license MIT)
(authors "Anentropic")
(maintainers "ego@anentropic.com")

(package
 (name oktree)
 (synopsis "OKtree: A simple octree implementation in OCaml")
 (description "A simple octree implementation in OCaml, intended to efficiently find nearest match for an arbitrary point among a set of points in 3D coordinate space.")
 (depopts
  ; optional: visualise library deps
  ; opam install oplot
  oplot)
 (depends
  ; core deps
  (ocaml (>= 4.14))
  ppx_deriving

  ; test and benchmark deps
  ; opam install . --deps-only --with-test
  (ppx_deriving_popper (and :with-test (>= 0.1.1)))
  (gg (and :with-test (>= 1.0)))
  (core_bench (and :with-test (>= 0.15.0)))
  (core_unix (and :with-test (>= 0.15.0)))

  ; dev deps (for pre-commit hooks: formatting and build)
  ; opam install . --deps-only --with-dev-setup
  (ocamlformat :with-dev-setup)
  (ocp-indent :with-dev-setup)
  (opam-publish :with-dev-setup)

  ; dev deps for REPL 
  (utop :with-dev-setup)

  ; docs
  (odoc :with-doc)
 ))
