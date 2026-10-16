# Stack OS

## Requirements

- [Git](https://git-scm.com/)
- [Bun](https://bun.sh/)
- [uv](https://docs.astral.sh/uv/)

## Setup

```sh
git clone https://github.com/stackific/stack-os.git
cd stack-os
bun install          # installs Task and the git hooks
bunx task setup      # installs every project's dependencies
```

## Run

```sh
bunx task                # list all tasks
bunx task docs:dev       # docs site at http://localhost:4321
bunx task docs:build     # build the docs site
bunx task lint           # run every check on all files
```

## Semantic index (optional)

Clone the reference projects into `references/` (see `meta/roadmaps/refs.md`), then:

```sh
bunx task index:setup    # once per machine
bunx task index:build    # after adding or updating references/
```
