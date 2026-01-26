# AGENTS.md

Exit code 130 is a bug in VSCode terminal, just retry if you get that.

When managing dependencies use an opam switch.

When completing a task, use `get_errors` tool to check for issues and then fix them. You may have to do a `dune clean && dune build` or even restart the OCaml LSP in some cases.

If you made any changes to the oktree lib then run tests with `dune test`. If you made functional changes to oktree lib then run the benchmark and report any regressions > 5%.
