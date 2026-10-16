# AGENTS.md

## Attribution

Strict order: AI agents must not add any AI attribution to commit messages, PR titles or descriptions, or documentation. This includes trailers such as `Co-Authored-By: Claude`, "Generated with" footers, agent or model lines in docs entries, and similar markers.

## Working rules

- Never commit or push without the operator's explicit command; never push to `main`.
- Every commit is signed and carries the operator's DCO `Signed-off-by` line.
- Every change follows `meta/ritual.md`: prompt and expectations recorded in a "How it was made" entry.
- Working software over edge cases: ship the simplest thing that passes the step's "done when" list; edge cases go to Follow-ups.
- Indent with 2 spaces in every language, except: C++ (including Qt), Rust and QML use 4 spaces; Go uses gofmt (tabs).
- Write idiomatic, modular code for each language: follow its standard conventions, formatter and linter; small modules with one responsibility.
- Always document code inline: a header comment per file or module on what it does and why, and comments on anything non-obvious, in the language's doc-comment style.
- Every dev command goes through Task (`task <name>`, from taskfile.dev): never call `bun`, `bunx` or other tools directly, add a task instead.
- Pre-commit hooks (lefthook, installed by `task setup`) must pass; never bypass them with `--no-verify`. `task lint` runs them on all files.
- Taskfiles are modular: each project folder has its own `Taskfile.yml` with an `install` task, included from the root `Taskfile.yml` and called by `task setup`. Shared tasks go in `taskfiles/`.
- Edit AGENTS.md and CLAUDE.md concisely.

## Layout

- `docs/`: Starlight docs site; its tasks run `bun`, never npm/node.
- `src/`: all Stack OS code, one folder per project (`shell/`, `dev/`, `quickshell/`); folders with tooling have their own `Taskfile.yml`.
- `meta/`: maintainer and agent docs; readers never see it. `ritual.md`, `operator-guide.md`, `milestones/` (`README.md` with the Status block and milestone index; one folder per milestone, `NNN-slug/`, with its `README.md`, which lists its steps and decisions, and its decisions `NN-slug.md`; step IDs `M1-3`), `templates/` (milestone and decision templates), and `roadmaps/` (`refs.md`: reference repositories by topic; `cli.md`: the `stack` command spec).
- `references/`: read-only upstream projects, cloned locally, gitignored, and indexed with cocoindex-code. Never edit or copy wholesale. Grep it by explicit path. Every third-party project lives there, so cite its files as `project/path:lines` (`mango/src/main.c:389-423`), never with a `references/` prefix.

## Design decisions

Before making or changing a design decision, research prior art with the `prior-art` agent.

- `terra-fedora` is our proof of concept: a bootable, installable Fedora bootc custom distro that works end to end. Look there first for how it solved image builds, installation and its `terra` CLI.
- The other references are listed in `meta/roadmaps/refs.md`.
