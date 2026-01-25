# OKtree

## Run CI locally (act)

For developing the GitHub Actions locally.

```sh
brew install act
```

The workflow uses `ocaml/setup-ocaml@v3`, which requires Node 24. The default act images don’t include Node 24 in the toolcache, so use the full runner image and set the toolcache path.

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
