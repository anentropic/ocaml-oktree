(lang dune 3.9)
(name oktree)
(version 0.2.2)

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

  ; test deps
  ; opam install . --deps-only --with-test
  (ppx_deriving_popper (and :with-test (>= 0.1.1)))
  (gg (and :with-test (>= 1.0)))

  ; dev deps
  ; opam install . --deps-only --with-dev-setup
  (ocamlformat :with-dev-setup)
  (ocp-indent :with-dev-setup)
  (opam-publish :with-dev-setup)
  (ocaml-lsp-server :with-dev-setup)
  ; - for benchmark suite
  (core_bench (and :with-dev-setup (>= 0.15.0)))
  (core_unix (and :with-dev-setup (>= 0.15.0)))
  (landmarks :with-dev-setup)
  (landmarks-ppx :with-dev-setup)
  ; - for REPL
  (utop :with-dev-setup)

  ; docs deps
  (odoc :with-doc)
 ))

 (pin
  (url git+https://github.com/LexiFi/landmarks.git#df896c4) ; until 1.6 is published
  (package
    (name landmarks-ppx)
    (version 1.6.alpha))
 )