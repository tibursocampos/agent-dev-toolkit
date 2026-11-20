# User guides

Onboarding hub for **agent-dev-toolkit**. Start here after [install / sync](../INSTALL.md) — you should not need to read every `SKILL.md` under the agent home for daily work.

**Audience:** developers using any supported agent with this toolkit’s skills.

**Language:** guides are in **English**. User chat and persisted artifacts follow the operator’s chat language; spawn / Task child prompts and agent receipts stay **en-US** (`core/skills/_shared/agents/LANGUAGE.md`). Application source code stays English.

---

## What this toolkit is

A **multi-agent** skills and policy pack with three independent feature-delivery paths: Classic SDD for a clear feature, Orchestrated Delivery for coordinated multi-story work, and ADT Delivery Flow for refinement through implementation in one evolving PLAN. Backlog refinement and requirement review are optional helpers. A one-file change can use `adt-developer` or a stack skill. Start with the [flow chooser](flow-selection.md), then follow the relevant session guide. Git flow is `adt-commit` / `adt-push` / optional `adt-open-github-pr`. Chat language, the parent orchestrator, and optional response compression are in [session-behavior.md](session-behavior.md). Prefer **Option 0** Release bootstrap ([INSTALL.md § 0](../INSTALL.md#0-release-bootstrap-https--checksum--toolkit)), or after clone run `pwsh -NoProfile -File .\scripts\toolkit.ps1`. Scripting/CI: `-Action Sync` or `sync-agent.ps1 -Agent <id>`.

---

## Getting started

1. Clone and sync. Follow [Install](../INSTALL.md) (option 1 = interactive `toolkit.ps1`) and [01 - Getting started](01-getting-started.md).
2. Open the **project you are building** in your agent (not only this toolkit repo).
3. Use the [decision tree](#which-skill-should-i-use) below, then [02 - Using skills](02-using-skills.md).

Re-run option 1 (`toolkit.ps1` → Sync agent) after `git pull` so published skills stay current. Scripting: `sync-agent.ps1`.

---

## Which skill should I use?

The decision tree and entry points live in [flow-selection.md](flow-selection.md). Mechanics: [Classic SDD](../sessions/02-classic-sdd.md), [Orchestrated Delivery](../sessions/01-orchestrated-delivery.md), and [ADT Delivery](../sessions/10-adt-delivery.md). Every skill: [sessions/09-every-skill.md](../sessions/09-every-skill.md).

Architecture input is gathered when a concrete question warrants it. Greenfield or brownfield classification alone does not require an ARCH artifact or a separate approval. Layers A/B/C: [sessions/04-implement-and-guidelines.md](../sessions/04-implement-and-guidelines.md).

---

## How the paths relate

The three delivery paths are peers with different plan shapes. Classic SDD creates a PRD and PLAN for a story; Orchestrated Delivery analyzes and coordinates one or more story plans; ADT Delivery evolves a single feature-root PLAN through refinement, planning, and implementation. None is a prerequisite for another. `/adt-refine-story` and `/adt-requirement-review` can shape or challenge inputs before choosing a delivery path.

The entry table and decision points live in [flow-selection.md](flow-selection.md); its linked session pages explain each path. Canonical SDD paths and storage rules are in `core/skills/_shared/sdd-artifacts/STORAGE.md`. Optional sidecars and repository-wide validation tools do not automatically become workflow gates. Skill discovery after sync: `adt-help-skills` (agent source of truth: `CATALOG.md` + `OPERATOR.md`) · human list: [SKILLS.md](../SKILLS.md).

---

## Guide index

| Guide | Content |
|-------|---------|
| [01-getting-started.md](01-getting-started.md) | Clone → sync → validate → first skill |
| [02-using-skills.md](02-using-skills.md) | How to invoke skills (incl. Codex dual-root + `adt-help-skills`) |
| [session-behavior.md](session-behavior.md) | Chat language, parent orchestrator, optional compression |
| [08-orchestrator-mode.md](08-orchestrator-mode.md) | Orchestrator default adaptive, charter, commands |
| [09-authorship-git-notes.md](09-authorship-git-notes.md) | Opt-in authorship git-notes (default off); TRACE remains SoT |
| [flow-selection.md](flow-selection.md) | Choosing the flow: decision tree, entry points, readiness rule, write limits |
| [backlog-refine.md](backlog-refine.md) | Backlog refine flow: adt-refine-story, adt-requirement-review, adt-split-story-checklist, write locations |
| [new-endpoint-example.md](new-endpoint-example.md) | Illustrative .NET endpoint across controller, facade, service, entity, HTTP client and tests |

Related:

| Doc | Content |
|-----|---------|
| [../INSTALL.md](../INSTALL.md) | Sync flags, live home, uninstall |
| [../VALIDATION.md](../VALIDATION.md) | validate-core + keyed uninstall asserts + AllowUserHome forward + 10 agent smokes (Copilot is a suite) |
| [../sessions/README.md](../sessions/README.md) | How skills relate, session by session |
| [../SKILLS.md](../SKILLS.md) | Skill list (points at the session pages) |
| [../ADAPTERS.md](../ADAPTERS.md) | Per-agent publish layouts |

---

## After code — recommended chain

1. `/adt-code-review` (choose angles if prompted)
2. Optional `/adt-test-coverage` (.NET)
3. `/adt-commit` then `/adt-push` (with confirmation); optional `/adt-open-github-pr` when opening a PR (feature **squash** → `develop`; release **rebase** → `main`/`master`)

---

## Session behavior

Chat language, parent orchestrator, and optional response compression (`caveman` default on) are one page: [session-behavior.md](session-behavior.md). Compression does not change skill steps.

## Orchestrator mode

Parent stays lean; specialists do heavy work. **Default `adaptive`.** Commands: `orchestrator always` / `adaptive` / `status`. Full guide: [08-orchestrator-mode.md](08-orchestrator-mode.md).
