# The ritual: how every change to Stack OS is made

Stack OS's promise is that nothing is magic: anyone can rebuild it, or their own variant, from the recorded prompts. That only holds if the record is complete. So writing code is a ritual with fixed steps, and the record is the "How it was made" section of the docs.

## The rule

**No change lands without its prompt and expectations recorded.** Each entry has one prompt and one outcome. The prompt consolidates the original ask and every follow-up into a single coherent request, as if it had been asked right the first time; the outcome is the single coherent response to it. Nothing that changed the result may be left out, but conversational noise (typos, back-and-forth, dead ends) is. If a change was made by hand, the entry says "manual" and why.

Expectations are written *before* the prompt runs: what the result must do and must not do, as checks a reader can perform. AI models drift; the same prompt on a newer model may produce a different result. That is acceptable. The expectations, not the original diff, are the test: if a reader's result meets them, it is a valid rebuild; if not, they know exactly where it diverged.

## Working software first

A step is done when its "done when" items in its milestone file (`meta/milestones/`) pass, not when every edge case is handled. Edge cases found along the way go in the entry's Follow-ups, not into the current change. A prompt that asks for the simplest working version beats one that asks for completeness; the record is cleaner and the expectations are easier to check.

## One unit of work = one entry

An entry covers one task (a milestone step or a bug fix), not one prompt. A task usually takes several prompts; they are all listed in order.

Entries live in `docs/src/content/docs/how-it-was-made/` as `<n>-slug.md`, where `<n>` is a sequential counter: the next unused integer (e.g. `3-stack-update.md`). Neither the file name nor the title carries the step ID; the entry's first line does (`Step: M1.3`). The step ID is the thread a reader follows: docs entry, branch, commits and PR all carry it. See `meta/operator-guide.md`.

Readers see the docs site, the closed PRs and the commits; they never see `meta/`. So an entry must stand on its own: say in plain words what a spec required instead of only linking it.

## Steps

1. **Open the entry first.** Create `<n>-slug.md` with the goal, expectations and the planned first prompt. Doing this before the prompt stops the record from being written from memory afterwards.
2. **Run the prompt** in Claude Code (or another agent; name it in the entry).
3. **Review the result.** Read the diff. If it's wrong, send a correction; it is folded into the entry's consolidated prompt when the entry is closed. Never silently fix by hand what the agent got wrong; if you must, record the manual change.
4. **Verify.** Run the task's "done when" check from its milestone file in `meta/milestones/`. Record the command and result.
5. **Close the entry.** Consolidate the prompt, write the Outcome, fill in Deviations and Follow-ups.
6. **Commit** with the step ID as the subject prefix (`M1.3: ...`), signed and signed off. One entry can span several commits. Link the PR in the entry before merging.

## Entry template

```markdown
---
title: 3-Stack update     # <n>-Title
description: One line.
sidebar:
  order: 3              # the entry's counter <n>
---

Step: M1.3 · PR: #NN · Agent: Claude Code (model)

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
single coherent ask. A reader should be able to send it as-is.

> prompt text

## Outcome
One coherent response to that prompt: what was built and how it meets the expectations.

## Manual changes
Anything done by hand, and why the agent didn't do it.

## Result
What now exists. Commands run to verify, with their output summarised.

## Deviations
Where the result differs from the plan or the meta docs, and whether the docs were updated.

## Follow-ups
Open items, with the step ID that picks them up once known.
```

## What is not recorded

- Secrets, tokens, personal paths that aren't part of the project.
- Conversation that produced no change (questions answered, options discussed). Summarise in Context if it mattered.

## Why the agents are set up the way they are

The repo's Claude Code configuration (`.claude/`, `.mcp.json`) is part of the record: caveman keeps replies short so prompts stay the signal, the push guard and the no-commit rule keep the human in the loop, and the semantic index over `references/` gives the agent the same reading material a human contributor has. Changing that setup is itself an entry.
