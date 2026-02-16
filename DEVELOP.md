# OKtree

Initial set up:

```sh
opam switch create .
eval $(opam env)
opam pin add landmarks-ppx git+https://github.com/LexiFi/landmarks.git#df896c4 --no-action
opam install . --deps-only --with-dev-setup --with-test --with-doc
```

(`landmarks` pin needed until version 1.6 released, see <https://github.com/LexiFi/landmarks/pull/45>)

### Optional: Visualise library

To build the `oktree.visualise` library, install `oplot`:

```sh
opam install oplot
dune clean && dune build && dune build @runtest
```

## VS Code

1. Press `Cmd+Shift+P` (Command Palette)
2. Type "OCaml: Select a Sandbox for this Workspace"
3. Select the local switch: `ocaml-oktree`

## REPL

```sh
dune utop
```

## Tests

Run tests with:

```sh
dune test
```

NOTE: this will produce no output if tests have already been run with no code changes to be compiled.

...or also if it's misconfigured and finds no tests to run. Add `--force` arg to be sure tests are run.

Tests use [Alcotest](https://github.com/mirage/alcotest) for unit tests and [QCheck](https://github.com/c-cube/qcheck) for property-based tests. Property-based tests default to 100 iterations locally. In CI, QCheck's built-in `QCHECK_LONG` mechanism scales this up:

```sh
# run with 10,000 iterations per PBT (same as CI)
QCHECK_LONG=true QCHECK_LONG_FACTOR=100 dune test --force
```

## Run CI locally (act)

For developing the GitHub Actions locally.

```sh
brew install act
```

The workflow uses `ocaml/setup-ocaml@v3`, which requires Node 24. The default `act` images don’t include Node 24 in the toolcache, so use the full runner image and set the toolcache path.

Build a local act runner image with bubblewrap:

```sh
cat <<'EOF' >/tmp/act-node24.Dockerfile
FROM ghcr.io/catthehacker/ubuntu:full-24.04
USER root
RUN apt-get update && apt-get install -y bubblewrap && rm -rf /var/lib/apt/lists/*
EOF

docker buildx build --platform linux/amd64 -t oktree-act-node24 --load -f /tmp/act-node24.Dockerfile /tmp
```

Run CI locally:

```sh
act -W .github/workflows/ci.yml \
	-P ubuntu-latest=oktree-act-node24 \
	--container-architecture linux/amd64 \
	--env ACTIONS_RUNNER_TOOL_CACHE=/opt/hostedtoolcache \
	--pull=false
```
