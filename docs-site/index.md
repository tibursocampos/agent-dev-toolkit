---
title: Home
---

# agent-dev-toolkit

**agent-dev-toolkit** is a developer toolkit for coding agents. One shared core (skills, policy, router, and delivery contracts) is published by adapters into the agent you already use. You sync with a PowerShell CLI, then invoke the same skill ids in that agent.

| I want to | Go to |
|-----------|-------|
| Install the toolkit | [Get started](get-started.md) |
| Sync or validate from the command line | [CLI](cli.md) |
| Run my first skill | [First use](first-use.md) |
| Choose a feature delivery workflow | [Choosing a delivery flow](delivery-flow.md) |

Also: [Using skills](using-skills.md), [Orchestrated Delivery](orchestrated-delivery.md), [Adapters](adapters.md), and [Architecture](architecture.md).

<figure class="home-diagram">
  <img src="assets/core-adapters-diagram.svg" alt="Core skills, adapters, and agent install roots" width="560" height="300">
</figure>

**Ten agents:** Cursor, Antigravity, Claude Code, Codex, GitHub Copilot, OpenCode, Grok Build, ZCode, Hermes, and OpenHands.

To try it from a clone, run the interactive menu: `pwsh -NoProfile -File ./scripts/toolkit.ps1`. Downloads and the other install options are on [Get started](get-started.md).

