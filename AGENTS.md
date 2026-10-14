# AGENTS.md

Exit code 130 is a bug in VSCode terminal, just retry if you get that.

When managing dependencies use an opam switch.

When completing a task, use `get_errors` tool to check for issues and then fix them. You may have to do a `dune clean && dune build` or even restart the OCaml LSP in some cases.

If you made any changes to the oktree lib then run tests with `dune test`. If you made functional changes to oktree lib then run the benchmark and report any regressions > 5%.

## Opening pull requests

When you open a pull request, ask the user whether it needs a review. If they say yes:

1. Mark the PR ready for review, since the review bot skips drafts.
2. Request a review from `anentropic-reviewbot`. Claude then posts inline comments and a summary on the PR.
3. Watch the PR and address the review comments and any CI failures as they come in, until CI is green and no blocking comments are left open.

To get another review after pushing fixes, request one from `anentropic-reviewbot` again.
