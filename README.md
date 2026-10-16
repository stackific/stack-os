# Stack OS

## Requirements

- [Git](https://git-scm.com/)
- [Task](https://taskfile.dev/docs/installation)

## Setup

```sh
git clone https://github.com/stackific/stack-os.git
cd stack-os
task setup   # installs every dependency (Bun, uv, podman, toolbox if missing), the git hooks and the dev toolbox
```

## Run

```sh
task                   # list all tasks
task dev:setup         # build the shell dev toolbox (Mango, foot, pinned Quickshell)
task dev:run           # nested Mango running the shell from src/shell/, live reload
task docs:dev          # docs site at http://localhost:4321
task docs:build        # build the docs site
task lint              # run every check on all files
```

## Semantic index (optional)

Clone the reference projects into `references/` (see `meta/roadmaps/refs.md`), then:

```sh
task index:setup   # once per machine
task index:build   # after adding or updating references/
```
