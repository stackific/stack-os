# Operator guide

How the operator (the human maintainer) and the agent build Stack OS together. The agent does the drafting; the operator decides, edits and approves.

## What readers see

Future users see only three things. Everything is shaped for them:

| Where | What it shows |
|---|---|
| Docs (stack-os.org) → How it was made | one entry per step: goal, expectations, prompts, result |
| Closed PRs on GitHub | the diff and review for that step |
| Commits | the code, each prefixed with its step ID |

`meta/` is for maintainers and agents; readers never need it.

## The step ID is the thread

Every milestone is split into steps: **M1.3** = milestone 1, step 3. The same ID appears everywhere:

| Artifact | Form |
|---|---|
| Branch | `m1/3-stack-update` |
| Commits | `M1.3: add update subcommand` (signed and signed off) |
| PR title | `M1.3: stack update` |
| Docs entry | `how-it-was-made/3-stack-update.md` (next counter, no step ID), title `3-Stack update`; first line `Step: M1.3 · PR: #NN` |

A reader on any of the three can find the other two.

## The loop

**Per milestone**
1. Say: `plan M1`.
2. The agent proposes the steps (M1.1 … M1.n), each tied to the milestone's "done when" items, and flags which need a design decision first.
3. Trim or reorder. The agent writes the list in the milestone's file (`meta/milestones/mN-slug.md`) as `Steps:`, one line each: `- [ ] M1.4: snapshot layer (decision 0013)`, ticked with its PR number when merged.

**Per design decision** (only when a step needs one)
4. The agent runs prior-art research (the `prior-art` agent over `references/`) and drafts the decision record in `meta/decisions/`, condensing the research into its Prior art section.
5. Approve or change it. No code yet.

**Per step**
6. Say: `next step`.
7. The agent opens the docs entry and replies with:
   - the expectations (must / must not)
   - a ready-to-send prompt, about five lines
8. Edit either if you want, then send the prompt.
9. The agent implements, checks against the expectations, and shows evidence (test or command output).
10. Review and send corrections as needed. When the step is done, the agent folds the ask and all corrections into one coherent prompt and one outcome in the entry; check that it reads right.
11. Say: `commit` (or `commit and PR`). The agent commits, pushes the branch, opens the PR and links it in the entry.
12. Merge the PR on GitHub.

## Status

The `## Status` block in `meta/milestones/README.md` is the single answer to "where are we": milestone, step, open PRs, pending decisions, next action. The agent updates it in the same commit that closes a step, opens a PR or settles a decision, so `git pull` brings any machine up to date.

## New machine or new thread

1. Clone, then set `user.name`, `user.email` and SSH commit signing (`gpg.format=ssh`, `user.signingkey`, `commit.gpgsign=true`, `format.signoff=true`).
2. Install dependencies and the git hooks: `bun install`, then `bunx task setup`.
3. For the semantic index, clone `references/` (see `meta/roadmaps/refs.md`), then `bunx task index:setup` and `bunx task index:build`.
4. Open Claude Code and say `where are we`. `CLAUDE.md` loads `AGENTS.md` and this guide into every session.

## What you say, what you get

| You say | You get |
|---|---|
| `plan M1` | step list for M1 |
| `next step` | expectations + draft prompt for the next step |
| *(the prompt)* | implementation + evidence |
| `fix: <what's wrong>` | a correction, folded into the entry's prompt at the end |
| `commit and PR` | signed-off commit, pushed branch, PR linked in the entry |
| `where are we` | the Status block plus the current milestone's steps |

## Your part, the agent's part

| Operator | Agent |
|---|---|
| choose and order steps | split milestones into steps |
| approve design decisions | research prior art, draft decisions |
| edit expectations | draft expectations and prompts |
| send the prompt | implement, test, show evidence |
| review, correct | fill the docs entry |
| say "commit", merge PRs | commit (signed off), push branch, open PR |

## Rules the agent follows

- Never commits or pushes without your word; never pushes to `main`.
- No AI attribution in commits, PRs or files.
- Simplest version that passes the step; edge cases go to Follow-ups.
- Docs entries stand on their own: no "see meta/…" a reader can't follow.
