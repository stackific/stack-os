# Milestones

Milestones are rolling: one file per milestone, `mN-slug.md`, added as the roadmap grows. Each has a "done when" list. Nothing from a later milestone starts until the current one's list is green, except documentation. Every item becomes one or more "How it was made" entries (see `../ritual.md`).

## Status

Milestone: M1 (planned, draft)
Step: none
Open PRs: #1
Pending decisions: 0001 image layout, 0002 greeter, 0003 lock screen
Next: approve the M1 steps, then draft decision 0001

## Index

| Milestone | Title | State |
|---|---|---|
| [M1](m1-minimal-desktop.md) | Minimal desktop | planned |

Template for `mN-slug.md`:

```markdown
# MN: Title

One line on what the milestone proves.

Scope: what is in and out.

Done when:

- [ ] an observable check a reader can run

Steps:

- [ ] MN.1: step title (decision NNNN)
```
