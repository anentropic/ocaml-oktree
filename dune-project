(lang dune 3.5)
(name oktree)
(version 0.1.0)

(generate_opam_files true)

(source (github anentropic/ocaml-oktree))
(license MIT)
(authors "Anentropic")
(maintainers "ego@anentropic.com")

(package
 (name oktree)
 (synopsis "OKtree: A simple octree implementation in OCaml")
 (description "A simple octree implementation in OCaml, intended to efficiently find nearest match for an arbitrary point among a set of points in 3D coordinate space.")
 (depends
  ; opam install . --deps-only --with-test
  (ocaml (>= 5.1))
  (psq (>= 0.2))
    ; benchmark deps
    (core (>= 0.15.0))
    (core_bench (>= 0.15.0))
    (core_unix (>= 0.15.0))
  ; test deps
  (ppx_deriving_popper (and :with-test (>= 0.1.1)))
  (gg (and :with-test (>= 1.0)))

  ; benchmark deps (to be installed manually):
  ; opam pin -n git+https://github.com/mseri/owl.git#arm64 --with-version=1.1.0
  ; opam install core_bench core_unix owl
  ; opam pin https://github.com/sanette/oplot.git#0.7
  ; opam install oplot

  ; dev deps (to be installed manually):
  ; opam install ocaml-lsp-server ocp-indent ocp-index ocamlformat down ocamlfind
 ))
