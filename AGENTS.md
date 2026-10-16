# AGENTS.md

## Attribution

Strict order: AI agents must not add any AI attribution to commit messages, PR titles or descriptions, or documentation. This includes trailers such as `Co-Authored-By: Claude`, "Generated with" footers, and similar markers.

## Design decisions

Before making or changing a design decision, research prior art with the `prior-art` agent.

- `meta/` holds design docs: `REFERENCES.md` (reference repositories, by topic) and `STACK-CLI.md` (the `stack` command spec).
- `references/` holds the repositories listed in `meta/REFERENCES.md`, cloned locally, gitignored, and indexed with cocoindex-code. Grep it by explicit path.
