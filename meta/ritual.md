# The ritual: how every change to Stack OS is made

Stack OS's promise is that nothing is magic: anyone can rebuild it, or their own variant, from the recorded prompts. That only holds if the record is complete. So writing code is a ritual with fixed steps, and the record is the "How it was made" section of the docs.

## The rule

**No change lands without its prompt and expectations recorded.** Each entry has one prompt and one outcome. The prompt consolidates the original ask and every follow-up into a single coherent request, as if it had been asked right the first time; the outcome is the single coherent response to it. Nothing that changed the result may be left out, but conversational noise (typos, back-and-forth, dead ends) is. If a change was made by hand, the entry says "manual" and why.

Expectations are written *before* the prompt runs: what the result must do and must not do, as checks a reader can perform. AI models drift; the same prompt on a newer model may produce a different result. That is acceptable. The expectations, not the original diff, are the test: if a reader's result meets them, it is a valid rebuild; if not, they know exactly where it diverged.

## Working software first

A step is done when its "done when" items in its milestone file (`meta/milestones/NNN-slug/README.md`) pass, not when every edge case is handled. Edge cases found along the way go in the entry's Follow-ups, not into the current change. A prompt that asks for the simplest working version beats one that asks for completeness; the record is cleaner and the expectations are easier to check.

## One unit of work = one entry

An entry covers one task (a milestone step or a bug fix), not one prompt. A task usually takes several prompts; they are all listed in order.

Entries live in `docs/src/content/docs/how-it-was-made/`, nested like the work: one folder per milestone, one page per step. A step's entry is `NNN-slug/<n>-slug.md`, where `NNN-slug` matches the milestone's folder in `meta/milestones/` and `<n>` is the step's number within its milestone (e.g. `001-minimal-desktop/3-power-menu.md`). Each milestone folder starts with an `index.md` overview (goal, scope and "done when" in reader terms, sidebar label `Overview`) and is a sidebar group in `docs/astro.config.mjs` labelled `<N>-Title` (milestone number without zero padding, e.g. `1-Minimal desktop`), added when the milestone is planned. Neither the file name nor the title carries the step ID; the entry's first line, right before `## Goal`, does: `NNN-NN: <few-word summary>` (milestone and step, zero-padded, e.g. `001-03: power menu in the bar`), plain text in the step's own commit; the next step's commit turns the whole line into a link to it (a commit cannot link itself). No agent, model or other AI attribution in the entry. The step ID is the thread a reader follows: docs entry, branch, commits and PR all carry it. See `meta/operator-guide.md`.

A milestone's decisions are listed, with link and status, only in its `meta/milestones/NNN-slug/README.md`; `meta/milestones/README.md` keeps the Status block and the milestone index.

Readers see the docs site, the closed PRs and the commits; they never see `meta/`. So an entry must stand on its own: say in plain words what a spec required instead of only linking it.

## Steps

1. **Open the entry first.** Create `<n>-slug.md` with the goal, expectations and the planned first prompt. Doing this before the prompt stops the record from being written from memory afterwards.
2. **Run the prompt** in an agent (never named in the entry).
3. **Review the result.** Read the diff. If it's wrong, send a correction; it is folded into the entry's consolidated prompt when the entry is closed. Never silently fix by hand what the agent got wrong; if you must, record the manual change.
4. **Verify.** Run the task's "done when" check from its milestone file in `meta/milestones/NNN-slug/`. Record the command and result, and tick each verified "done when" item in that file.
5. **Close the entry.** Consolidate the prompt, write the Outcome, fill in Deviations and Follow-ups. Before moving to the next step, every step adds a screenshot of its result to the Outcome, next to the text: saved as `docs/src/assets/how-it-was-made/NNN-slug/<n>-slug.png` and embedded with a relative link (shell steps capture it with `task dev:screenshot`).
6. **Review.** Stage the change and run two passes: the `reviewer` agent (`.claude/agents/reviewer.md`) for the project's rules, the step's expectations and the accepted decisions, and the built-in `/code-review` for bugs. Fix each finding or move it to Follow-ups with a reason, then add one line to the entry's Result: `Review: N fixed, N deferred.` No commit while a `high` finding is open.
7. **Commit** one commit per step, with the entry's first line as the subject (`001-03: power menu in the bar`) and the entry's URL as the last body line before the trailers (`https://stack-os.org/how-it-was-made/NNN-slug/<n>-slug/`, e.g. `https://stack-os.org/how-it-was-made/001-minimal-desktop/1-dev-environment/`), signed and signed off, on the milestone's branch (`m1-minimal-desktop`). Each milestone has one PR, titled `NNN: Title` (`001: Minimal desktop`), whose description lists the steps by their `NNN-NN` lines,, opened with its first step's commit and merged when its last step is in; it may also hold extra commits (review fixes, chores), but a step's own work is exactly one commit. That commit also does the previous step's bookkeeping: links its entry's first line to its commit, ticks it in the milestone file with the short hash, and updates the Status block. The last step of a milestone gets this in the next milestone's first commit.

## Entry template

````markdown
---
title: 3-Power menu       # <n>-Title
description: One line.
sidebar:
  order: 3              # the step number <n>
---

[001-03: power menu in the bar](https://github.com/stackific/stack-os/commit/<sha>)

## Goal
What this step was meant to produce, and which milestone item it serves.

## Context
What existed before, and the decisions this step implements, in plain words (readers don't have `meta/`). Earlier steps by ID.

## Expectations
Written before the prompt runs. This is how drift is detected later: a newer model may
produce a different result from the same prompt, and the reader checks it against these,
not against the original diff.

Must:
- observable outcome 1 (a file exists, a command prints X, a test passes)
- outcome 2

Must not:
- touch anything outside `docs/`
- add a dependency

## Prompt
One request: the original ask plus every follow-up that changed the result, edited into a
single coherent ask. A reader should be able to send it as-is. It is a wrapped code block titled "Prompt", so the docs show a copy button on it.

```text title="Prompt" wrap
prompt text
```

## Outcome
One coherent response to that prompt: what was built and how it meets the expectations.

![What the step produced](../../../../assets/how-it-was-made/001-minimal-desktop/3-power-menu.png)

## Manual changes
Anything done by hand, and why the agent didn't do it.

## Result
What now exists. Commands run to verify, with their output summarised.

## Deviations
Where the result differs from the plan or the meta docs, and whether the docs were updated.

## Follow-ups
Open items, with the step ID that picks them up once known.
````

## What is not recorded

- Secrets, tokens, personal paths that aren't part of the project.
- Conversation that produced no change (questions answered, options discussed). Summarise in Context if it mattered.

## Why the agents are set up the way they are

The repo's Claude Code configuration (`.claude/`, `.mcp.json`) is part of the record: caveman keeps replies short so prompts stay the signal, the push guard and the no-commit rule keep the human in the loop, and the semantic index over `references/` gives the agent the same reading material a human contributor has. Changing that setup is itself an entry.
