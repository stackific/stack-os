# Product vision

What Stack OS is for, why it exists, and what would make it a 10x idea rather than a 10% better distro. Written for the operator; researched October 2026.

## In one line

Stack OS is an OS and an AI-native framework for building your own extremely modern and efficient OS without becoming an expert overnight: you tell your AI to build it with Stack OS.

## The promise

The OS you make is yours: every decision visible, portable, reversible, and rebuildable by anyone with an AI and the prompts.

Apple-level finish, Omarchy-level fun, Fedora-stable, zero opinions you can't remove.

## First principles

Strip a personal OS down to what it actually is:

1. **An OS is a stack of decisions.** Which compositor, which keybind, which font, which update policy. Every distro is someone's set of decisions, frozen.
2. **Today decisions are stored as their output, not their intent.** Dotfiles, scripts and package lists record *what* was chosen. The *why* lives in someone's head, a forum thread or nowhere. That is why removing a part of Omarchy feels like "peeling layers off someone else's vision": you are reverse-engineering intent from output.
3. **Writing the output was the expensive part. AI made it cheap.** Turning "I want my bar on the left and my theme to follow my wallpaper" into working config used to take weeks of DIY. An agent does it in minutes. What stays expensive is *trust*: knowing what changed, why, and how to undo it.
4. **So the durable artifact is the intent, not the config.** If every change is stored as prompt + reason + diff, the config becomes a build product that anyone can regenerate, vary or replay on a newer base.
5. **Reversibility is what makes experimenting rational.** With an image-based OS (bootc), every state of the system is a bootable image; a bad change is one rollback away, so "feel free to do whatever" is a safe instruction, not a reckless one.

Stack OS is what falls out of these five: **prompts are the source code of your OS; the image is the compiled output; the decision journal is the history.**

## The landscape (October 2026)

| | What it gives you | What it lacks |
|---|---|---|
| **Omarchy** (Arch + Hyprland, now Quickshell in v4) | Gorgeous, fun, opinionated defaults; ~28k GitHub stars, an $8M+ foundation. Since v4, built-in agent launchers and a skills system that edits Hyprland, the bar and themes on request. | *Omakase*: the chef decides. The agent edits live files in `~/.config` on one machine, keeping only `.bak` copies: no journal, no reason, nothing in a repository. Updates "may occasionally restore certain configs to their original state"; `omarchy reinstall configs` or a fresh install wipes every change unless you back up dotfiles yourself. A custom ISO (`omarchy-iso-make --local-source`) builds from a fork of Omarchy's source, not from your agent's edits, so turning your machine into a distro means porting changes by hand. Removing opinions is peeling layers. Security criticism from the Arch community. |
| **NixOS** | Fully declarative, rollback, reproducible; widely called the ideal substrate for coding agents. | Steep language. Git history records *what*, not *why*. No finish or design opinion out of the box; you start from a plain base. |
| **BlueBuild / Universal Blue (Bluefin, Bazzite)** | Build your own bootc/Fedora Atomic image from a YAML recipe or a Containerfile template; CI builds, signs and hosts it; rollback for free. Bluefin even runs an agent "Factory" to maintain itself. | A recipe format for people who already know what they want. No intent record, no AI-native authoring for users, finish depends on the base you pick. |
| **AI-OS distros** (MakuluLinux AI-OS, CX Linux, deepin) | An assistant embedded in the desktop for natural-language control. | AI *operates* the OS; it does not *author* it. Nothing is recorded or reproducible; it's still someone else's distro. |

Nobody combines all four: **AI authoring + recorded intent + an image you can rebuild and roll back + a finished design to start from.** Each competitor holds one or two.

The closest threat is Omarchy: it already has the fun, the polish, the money and now agents. But its agent customizes one machine, once, in place; Stack OS's agent edits the source of a distro you own, so every change survives reinstalls, reaches every machine and ships as an image others can fork. Its structural limit is the omakase model itself: one chef, mutable dotfiles, no journal. Stack OS should not try to out-curate Omarchy; it should make curation forkable.

## The 10x idea

Not a 10% better distro: a framework to build your own OS, natively with AI. Fork Stack OS, pick from our existing prompts or write your own, and customize the OS to your liking.

10x is measured, not claimed. The bets, against today's best alternative:

| Job | Today | Stack OS target |
|---|---|---|
| Go from "I want X" to a working, finished desktop | Weeks of DIY on a plain base, or accept someone else's choices | Minutes: describe it, the agent changes the blueprint, the image rebuilds |
| Remove an opinion you don't like | Peel layers; hope the next update doesn't restore it | Revert one journal entry; the image rebuilds without it, and stays that way |
| Reproduce someone's setup | Screenshots and a dotfiles repo with no context | Paste their prompts into your AI; get the same result, or a variation, even on another base |
| Upgrade the base | Merge conflicts between your edits and upstream's | Replay your intents on the new base; the agent resolves them because it knows *why* each one exists |
| Recover from a bad change | Reinstall, or debug at 2 a.m. | Boot the previous image |
| Understand why your system is the way it is | Nobody knows | Every line traces back to a prompt, a reason and a PR |

If a feature does not move one of these rows by an order of magnitude, it is a 10% feature and waits.

## Open prompts

Every AI prompt used to make Stack OS is public, mapped to the pull request it produced. The project's "How it was made" docs are the journal for Stack OS itself; every user gets the same journal for their own machine.

## The decision journal

Every change to the blueprint, whether you typed it or an agent did, is recorded with the prompt, the diff and the reason. Nothing is magic: anyone can paste the prompts into their own AI and reproduce or vary the result. Nobody does this today. The closest is NixOS git history, which records what, not why.

## Fearless changes

Built on bootc, the whole OS is an image. You can always roll back to any earlier state; experiment freely, a mistake is one revert away.

## Look and feel

- Apple-level finish: one coherent design language from login screen to lock screen.
- Wallpaper-driven theme, applied to GTK and Qt apps alike, so the whole desktop follows one palette.
- Omarchy-level fun: delight is a feature, not a garnish.

## Moonshot horizon

Where this leads if the core bet works:

- **A prompt marketplace, not a dotfiles marketplace.** People share intents ("make it feel like a 2005 Mac", "gaming laptop, battery first") that anyone can apply, adapt and revert.
- **Base-agnostic intents.** The same journal rebuilt on Fedora today, on another bootc base tomorrow.
- **The OS explains itself.** Ask "why does Alt+Return open foot?" and get the prompt, the reason and the PR.
- **Your machine's journal is a portable identity.** New laptop: point it at your journal, get your OS.

## Hard problems to solve honestly

- **LLMs are not deterministic.** The same prompt can produce a different diff. The journal therefore stores the diff as the truth and the prompt as the intent; "rebuildable" means the diff applies, "reproducible" means the prompt gets you close.
- **Trust in AI-made changes.** Every change goes through review before it reaches the image, and the agent works on the blueprint, never on the running system.
- **Rollback covers the OS, not your data.** bootc rolls back the image; `/home` and parts of `/etc` carry over. Changes that touch user data need their own story.
- **"First paradigm shift" is a label others award.** Critics already say this about Omarchy: curation is not invention, and the shift is proven by lasting adoption, not announcements. Stack OS earns the claim only if forks, shared prompts and journals appear outside this repository.
- **Finish is hard to fork.** Apple-level polish comes from many small, consistent decisions. Stack OS must ship a finished default good enough that people fork *from* it rather than start bare.

## Sources

- Omarchy: [why it is hyped and hated](https://cloudzy.com/blog/why-omarchy-is-hyped-and-hated/), [agentic AI in Omarchy 4](https://tbreak.com/omarchy-linux-distro-agentic-ai/), [history, not yet a paradigm shift](https://world.hey.com/merovex/omarchy-is-history-it-is-not-yet-a-paradigm-shift-0a434ae8), [The Register on security criticism](https://www.theregister.com/a/5293026), [Omacom Foundation](https://itsfoss.com/news/omarchy-launches-omacom-foundation.md), [Omarchy agent skill](https://github.com/omacom/omarchy/blob/dev/default/omarchy-skill/SKILL.md), [Omarchy manual: dotfiles](https://omarchy.org/manual/dotfiles/), [omarchy-iso](https://github.com/omacom/omarchy-iso)
- NixOS: [ideal substrate for LLM coding agents](https://agent-wars.com/news/2026-03-24-nixos-as-the-ideal-substrate-for-llm-coding-agents), [local agent for NixOS config](https://discourse.nixos.org/t/local-ai-agent-for-nixos-configuration-looking-for-experience-reports/77238)
- bootc and Universal Blue: [BlueBuild](https://blue-build.org/), [BlueBuild recipe reference](https://blue-build.org/reference/recipe), [Fedora custom bootc base images](https://doc.fedoraproject.org/be/bootc/building-custom-base), [Bluefin Factory](https://docs.projectbluefin.io/factory/)
- AI-OS distros: [MakuluLinux AI-OS](https://www.linuxinsider.com/story/why-makululinux-ai-os-became-my-new-daily-driver-177752.html), [who is building the agent-native OS](https://medium.com/@marc.bara.iniesta/who-is-building-the-agent-native-operating-system-c6bae5a5a3f5)
- Theming: [matugen](https://github.com/InioX/matugen)
