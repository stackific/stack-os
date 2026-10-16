# Decision records

One file per settled decision, named `NNNN-slug.md`. Short: context, prior art, decision, consequences. A decision is changed by adding a new record that supersedes the old one, never by editing history.

Template:

```markdown
# NNNN: Title

**Context.** The problem and constraints.

**Prior art.** How established projects in `references/` solve it (from the `prior-art` agent): the pattern, file paths, where Stack OS follows it and where it deviates and why. Pin each cited reference to its commit (`references/snapper@a1b2c3d/...`). "None found" is a valid answer; say what was searched.

**Decision.** What Stack OS does.

**Consequences.** What follows, good and bad.
```

| # | Decision | Status |
|---|---|---|
