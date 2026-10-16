---
title: How it was made
description: Every change to Stack OS, with the prompt and expectations that produced it.
sidebar:
  order: 0
  label: Overview
---

Stack OS is built with an AI coding agent, and nothing is magic: every change is recorded here so anyone can rebuild Stack OS, or their own variant, from the same prompts.

The work is split into milestones, each proving one thing. A milestone is split into steps, and each step has its own page:

- **Goal**: what the step was meant to produce.
- **Expectations**: what the result must and must not do, written before the prompt ran. They are the test of a rebuild.
- **Prompt**: the request that produced the change, consolidated into one.
- **Outcome**: what was built, how it was checked, and what was left for later.

Each page starts with its step line (for example `001-03: power menu in the bar`), which is also the title of that step's single commit and links to it. A milestone's steps share one pull request.
